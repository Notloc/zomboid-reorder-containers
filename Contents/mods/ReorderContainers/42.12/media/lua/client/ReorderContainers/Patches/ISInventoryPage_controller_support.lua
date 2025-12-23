local ReorderContainersService = require("ReorderContainers/ReorderContainersService")

local og_onJoypadDown = ISInventoryPage.onJoypadDown

local function handleJoypadDown(self, target, button)
    -- Store the original order of the backpacks
    local originalOrder = {}
    for index, button in ipairs(target.backpacks) do
        originalOrder[button] = index
    end

    -- Sort the backpacks by their Y position so that scrolling works as expected
    table.sort(target.backpacks, function(a, b) return a:getY() < b:getY() end)

    -- Clear the 'backpackChoice', not sure what its actually for, but we stop it from existing on bumper inputs
    target.killTheChoice = true

    local retVal = og_onJoypadDown(self, button)
    table.sort(target.backpacks, function(a, b) return originalOrder[a] < originalOrder[b] end)
    return retVal
end

function ISInventoryPage:onJoypadDown(button)
    if button == Joypad.LBumper then
        return handleJoypadDown(self, getPlayerInventory(self.player), button)
    end

    if button == Joypad.RBumper then
        local lootPage = getPlayerLoot(self.player)
        if lootPage and ReorderContainersService.canReorderBackpacks(lootPage) then
            return handleJoypadDown(self, lootPage, button)
        end
    end

    return og_onJoypadDown(self, button)
end