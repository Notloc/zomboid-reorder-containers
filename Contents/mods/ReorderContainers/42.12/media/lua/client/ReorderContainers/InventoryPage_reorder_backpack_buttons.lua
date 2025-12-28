require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISMouseDrag"
require "ISUI/ISInventoryPage"

local Client = require("ReorderContainers/Client")
local ReorderContainersService = require("ReorderContainers/ReorderContainersService")

---@class ISInventoryPage
---@field public player integer

local SET_MANUALLY = "ReorderContainers_SetManually"

local function isButtonValid(invPage, button)
    return button:getIsVisible() and invPage.containerButtonPanel.children[button.ID]
end

function ISInventoryPage:reorderContainerButtons(draggedButton)
    -- Don't reorder if the button hasn't moved far enough
    if draggedButton and math.abs(draggedButton:getY() - draggedButton.reorderStartY) <= self.buttonSize then
        draggedButton:setY(draggedButton.reorderStartY)
        return
    end

    local playerObj = getSpecificPlayer(self.player)

    local inventoriesAndY = {}
    for index, button in ipairs(self.backpacks) do
        ---@cast button SortableBackpackButton
        if isButtonValid(self, button) then
            table.insert(inventoriesAndY, {inventory = button.inventory, y = button:getY()})
        end
    end
    table.sort(inventoriesAndY, function(a, b) return a.y < b.y end)

    local seenObjs = {}
    local lastSort = 0
    for index, data in ipairs(inventoriesAndY) do
        local sortData, parent, keySuffix = ReorderContainersService.getSortDataAndParentObjectAndKeySuffix(playerObj, data.inventory)
        local isManual = sortData and sortData.isManual or false
        local isDraggedButton = data.inventory == draggedButton.inventory

        if not isDraggedButton and parent ~= playerObj and seenObjs[parent] then
            -- Skip this button, some IsoObjects have multiple inventories
        elseif sortData then
            if parent then
                seenObjs[parent] = true
            end

            ---@diagnostic disable-next-line: assign-type-mismatch
            ---@type integer|nil
            local savedSort = tonumber(sortData.sortPriority)

            if not isManual or isDraggedButton or savedSort == nil then
                lastSort = lastSort + 10
                sortData.sortPriority = lastSort
                sortData.isManual = false
                Client.saveModData(parent, playerObj, keySuffix)
            else
                lastSort = savedSort
                -- Look back one button
                if index > 1 then
                    local prevInventory = inventoriesAndY[index - 1].inventory
                    local prevSort = ReorderContainersService.getSortPriority(playerObj, prevInventory, self)
                    if prevSort >= lastSort then
                        ReorderContainersService.setSortPriority(playerObj, prevInventory, lastSort - 1, false)
                    end
                end
            end
        end
    end
end

ISInventoryPage.applyBackpackOrder = function(self)
    local playerObj = getSpecificPlayer(self.player)

    local buttonsAndSort = {}
    for index, button in ipairs(self.backpacks) do
        if isButtonValid(self, button) then
            local sort = 1000 + index
            local sortData = ReorderContainersService.getSortDataAndParentObjectAndKeySuffix(playerObj, button.inventory)
            if sortData then
                sort = sortData.sortPriority or (1000 + index)
            end
            table.insert(buttonsAndSort, {button = button, sort = sort})
        end
    end

    table.sort(buttonsAndSort, function(a, b) return a.sort < b.sort end)

    for index, data in ipairs(buttonsAndSort) do
        data.button:setY((index - 1) * self.buttonSize)
    end
end

ISInventoryPage.pre_reorder_refreshBackpacks = ISInventoryPage.refreshBackpacks
ISInventoryPage.refreshBackpacks = function(self)
    if self.killTheChoice then -- Makes controller work...?
        self.backpackChoice = nil
        self.killTheChoice = false
    end
    
    self:pre_reorder_refreshBackpacks()
    if ReorderContainersService.isSortingEnabled(self) then
        self:applyBackpackOrder()
    end
    self.pendingReorder = false
end


