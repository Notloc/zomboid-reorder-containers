require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISMouseDrag"
require "ISUI/ISInventoryPage"

ReorderContainers_Mod = {}

ReorderContainers_Mod.onMouseDown = function(self, x, y)
    self.pre_reorder_onMouseDown(self, x, y)
    self.reorderMouseY = getMouseY()
end

ReorderContainers_Mod.onMouseMove = function(self, dx, dy, skipOgMouseMove)
    if not skipOgMouseMove then -- skipOgMouseMove is true when we're calling this from onMouseMoveOutside
        self.pre_reorder_onMouseMove(self, dx, dy)
    end
    if self.pressed then
        if math.abs(self.reorderMouseY - getMouseY()) > 10 then
            self.draggingToReorder = true
        end

        if self.draggingToReorder then
            local parent = self:getParent()
            
            local x = getMouseX()
            local y = getMouseY()
            local parentY = parent:getAbsoluteY()
            local newY = y - parentY - self:getHeight() / 2
            
            newY = math.max(parent:titleBarHeight() - 16, newY)

            self:setY(newY)
            self:bringToTop()
    
            self.draggingToReorder = true
        end
    end
end

ReorderContainers_Mod.onMouseMoveOutside = function(self, dx, dy)
    self.pre_reorder_onMouseMoveOutside(self, dx, dy)
    ReorderContainers_Mod.onMouseMove(self, dx, dy, true)

    -- if the mouse is no longer down, we missed the mouse up event
    if self.draggingToReorder and not isMouseButtonDown(0) then
        ReorderContainers_Mod.onMouseUp(self, 0, 0)
    end
end

ReorderContainers_Mod.onMouseUp = function(self, x, y)
    local page = self:getParent()
    if self.draggingToReorder then
        self.pressed = false;
        self.draggingToReorder = false
        page:reorderContainerButtons(self)
        page:refreshBackpacks()
    else
        -- Restore the original backpack order before we process the mouse up
        if page.pre_reorder_backpacks then
            table.wipe(page.backpacks)
            for index, button in ipairs(page.pre_reorder_backpacks) do
                table.insert(page.backpacks, button)
            end
        end

        self.pre_reorder_onMouseUp(self, x, y)
    end
end

ReorderContainers_Mod.original_addContainerButton = ISInventoryPage.addContainerButton
function ISInventoryPage:addContainerButton(container, texture, name, tooltip)
    local button = ReorderContainers_Mod.original_addContainerButton(self, container, texture, name, tooltip)
    -- Buttons can be reused, so we need to make sure we don't overwrite the original functions

    if not button.pre_reorder_onMouseDown then
        button.pre_reorder_onMouseDown = button.onMouseDown
    end
    button.onMouseDown = ReorderContainers_Mod.onMouseDown
    
    if not button.pre_reorder_onMouseMove then
        button.pre_reorder_onMouseMove = button.onMouseMove
    end
    button.onMouseMove = ReorderContainers_Mod.onMouseMove

    if not button.pre_reorder_onMouseMoveOutside then
        button.pre_reorder_onMouseMoveOutside = button.onMouseMoveOutside
    end
    button.onMouseMoveOutside = ReorderContainers_Mod.onMouseMoveOutside

    if not button.pre_reorder_onMouseUp then
        button.pre_reorder_onMouseUp = button.onMouseUp
    end
    button.onMouseUp = ReorderContainers_Mod.onMouseUp

    return button
end

local SORT_KEY = "ReorderContainers_Sort"
local SORT_KEY_FLOOR = "ReorderContainers_Sort_Floor"



ISInventoryPage.pre_reorder_createChildren = ISInventoryPage.createChildren
ISInventoryPage. createChildren = function(self)
    self.pre_reorder_createChildren(self)

    local reorderButton = ISButton:new(self:getWidth() - 32, self:getHeight() - 24, 32, 16, "", self)
    reorderButton:setImage(getTexture("media/ui/ReorderContainers/reorder-icon.png"))

    reorderButton.anchorLeft = false
    reorderButton.anchorRight = true
    reorderButton.anchorTop = false
    reorderButton.anchorBottom = true

    reorderButton.onMouseDown = function(self, x, y)
        local popup = ReorderContainers_ManualPopup:new(self:getAbsoluteX(), self:getAbsoluteY(), self:getParent())
        popup:initialise()
        popup:addToUIManager()
    end

    reorderButton:initialise()
    reorderButton:instantiate()
    self:addChild(reorderButton)
end










ISInventoryPage.reorderContainerButtons = function(self, draggedButton)
    local playerObj = getSpecificPlayer(self.player)
    local playerInv = playerObj:getInventory()
    local playerModData = playerObj:getModData()


    local inventoriesAndY = {}
    for index, button in ipairs(self.backpacks) do
        table.insert(inventoriesAndY, {inventory = button.inventory, y = button:getY()})
    end

    table.sort(inventoriesAndY, function(a, b) return a.y < b.y end)

    local seenObjs = {}

    for index, data in ipairs(inventoriesAndY) do
        if data.inventory == playerInv then
            playerModData[SORT_KEY] = index * 100
        elseif data.inventory:getType() == "floor" then
            playerModData[SORT_KEY_FLOOR] = index * 100
        else
            local item = data.inventory:getContainingItem()
            local isoObject = data.inventory:getParent()
            if item then
                item:getModData()[SORT_KEY] = index * 100
            elseif isoObject and (not seenObjs[isoObject] or data.inventory == draggedButton.inventory) then
                seenObjs[isoObject] = true -- some containers have multiple inventories, so only set the sort once. They have to sort together unfortunately.
                isoObject:getModData()[SORT_KEY] = index * 100
            end
        end
    end

end

ISInventoryPage.applyBackpackOrder = function(self)
    local playerObj = getSpecificPlayer(self.player)
    local playerInv = playerObj:getInventory()
    local playerModData = playerObj:getModData()

    local buttonsAndSort = {}
    for index, button in ipairs(self.backpacks) do
        local sort = -1
        if button.inventory == playerInv then
            sort = playerModData[SORT_KEY] or -1
        elseif button.inventory:getType() == "floor" then
            sort = playerModData[SORT_KEY_FLOOR] or -1
        else
            local item = button.inventory:getContainingItem()
            local isoObject = button.inventory:getParent()
            if item then
                sort = item:getModData()[SORT_KEY] or -1
            elseif isoObject then
                sort = isoObject:getModData()[SORT_KEY] or -1
            end
        end

        if sort == -1 then
            sort = 50000 + index
        end
        table.insert(buttonsAndSort, {button = button, sort = sort})
    end

    table.sort(buttonsAndSort, function(a, b) return a.sort < b.sort end)

    if not self.pre_reorder_backpacks then
        self.pre_reorder_backpacks = {}
    end
    
    -- Store the original list order so we can restore it for certain code paths
    table.wipe(self.pre_reorder_backpacks)
    for index, button in ipairs(self.backpacks) do
        self.pre_reorder_backpacks[index] = button
    end

    table.wipe(self.backpacks)
    for index, data in ipairs(buttonsAndSort) do
        data.button:setY((index - 1) * self.buttonSize + self:titleBarHeight() - 1)
        self.backpacks[index] = data.button
    end
end

ISInventoryPage.pre_reorder_refreshBackpacks = ISInventoryPage.refreshBackpacks
ISInventoryPage.refreshBackpacks = function(self)
    self:pre_reorder_refreshBackpacks()
    self:applyBackpackOrder()
end






