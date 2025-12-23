local ReorderContainersService = require("ReorderContainers/ReorderContainersService")
local ManualSortingPriorityWindow = require("ReorderContainers/UI/ManualSortingPriorityWindow")

local LOCK_TEX = getTexture("media/ui/ReorderContainers/reorder-locked.png")
local UNLOCK_TEX = getTexture("media/ui/ReorderContainers/reorder-unlocked.png")

---@param inventoryPage ISInventoryPage
---@param lockButton ISButton
local function updateLock(inventoryPage, lockButton)
    local newState = nil
    if inventoryPage.onCharacter then
        newState = ReorderContainersService.toggleInventoryLock(getSpecificPlayer(inventoryPage.player))
    else
        newState = ReorderContainersService.toggleLootLock(getSpecificPlayer(inventoryPage.player))
    end
    
    if newState or not ReorderContainersService.canReorderBackpacks(inventoryPage) then 
        lockButton:setImage(getTexture("media/ui/ReorderContainers/reorder-locked.png"))        
    else
        lockButton:setImage(getTexture("media/ui/ReorderContainers/reorder-unlocked.png"))
    end
end


local og_createChildren = ISInventoryPage.createChildren
function ISInventoryPage:createChildren()
    og_createChildren(self)
    
    local inventoryPage = self
    
    local buttonSize = self.buttonSize/2 -- Half the size of the inventory container icons
    local xPos = self:getWidth() - buttonSize
    local yPos = self:getHeight() - buttonSize*0.5 - self:titleBarHeight()
    
    local reorderButton = ISButton:new(xPos, yPos, buttonSize, buttonSize, "", self)
    reorderButton.anchorTop = false
    reorderButton.anchorLeft = false
    reorderButton.anchorBottom = true
    reorderButton.anchorRight = true
    reorderButton:setImage(getTexture("media/ui/ReorderContainers/reorder-icon.png"))
    reorderButton:initialise()
    reorderButton:instantiate()
    self:addChild(reorderButton)
    self.reorderOptionsButton = reorderButton

    reorderButton:setOnClick(function()
        ---@type SortableBackpackButton
        local selectedButton = inventoryPage.selectedButton
        if selectedButton then
            local x = getCore():getScreenWidth() / 2
            local y = getCore():getScreenHeight() / 2
            local popup = ManualSortingPriorityWindow:new(x - 100, y - 60, inventoryPage, selectedButton.inventory)
            popup:initialise()
            popup:setAlwaysOnTop(true)
            popup:setCapture(true)
            popup:addToUIManager()
        end
    end)

    xPos = xPos - buttonSize
    local lockButton = ISButton:new(xPos, yPos, buttonSize, buttonSize, "", self)
    lockButton.anchorTop = false
    lockButton.anchorLeft = false
    lockButton.anchorBottom = true
    lockButton.anchorRight = true
    lockButton:initialise()
    lockButton:instantiate()
    self:addChild(lockButton)
    self.reorderLockButton = lockButton

    local isLocked = ReorderContainersService.isLocked(inventoryPage) or not ReorderContainersService.canReorderBackpacks(inventoryPage)
    lockButton:setImage(isLocked and LOCK_TEX or UNLOCK_TEX)

    lockButton:setOnClick(function()
        if not ReorderContainersService.canReorderBackpacks(self) then
            self.reorderOptionsButton:onMouseDown(0,0)
            return
        end
        updateLock(self, lockButton)
    end)
end

ISInventoryPage.updateReorderContainersLock = function(self)
    if self.onCharacter then
        return
    end

    ReorderContainersService.toggleLootLock(getSpecificPlayer(self.player))
    updateLock(self, self.reorderLockButton)
end
