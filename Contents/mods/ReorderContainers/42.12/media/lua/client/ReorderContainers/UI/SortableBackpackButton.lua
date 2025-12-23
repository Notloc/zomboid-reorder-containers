local ReorderContainersService = require("ReorderContainers/ReorderContainersService")

---@class SortableBackpackButton : ISButton
---@field public playerNum integer
---@field public inventory ItemContainer
---@field public pre_reorder_onMouseDown fun(self: SortableBackpackButton, x: number, y: number): void
---@field public pre_reorder_onMouseMove fun(self: SortableBackpackButton, dx: number, dy: number): void
---@field public pre_reorder_onMouseMoveOutside fun(self: SortableBackpackButton, dx: number, dy: number): void
---@field public pre_reorder_onMouseUp fun(self: SortableBackpackButton, x: number, y: number): void
local SortableBackpackButton = {}

---@param button ISButton
---@param playerNum integer
---@return SortableBackpackButton
function SortableBackpackButton:inject(button, playerNum)
    ---@cast button SortableBackpackButton

    button.playerNum = playerNum
    
    -- Buttons can be reused, so we need to make sure we don't overwrite the original functions
    if not button.pre_reorder_onMouseDown then
        button.pre_reorder_onMouseDown = button.onMouseDown
    end
    button.onMouseDown = SortableBackpackButton.onMouseDown
    
    if not button.pre_reorder_onMouseMove then
        button.pre_reorder_onMouseMove = button.onMouseMove
    end
    button.onMouseMove = SortableBackpackButton.onMouseMove

    if not button.pre_reorder_onMouseMoveOutside then
        button.pre_reorder_onMouseMoveOutside = button.onMouseMoveOutside
    end
    button.onMouseMoveOutside = SortableBackpackButton.onMouseMoveOutside

    if not button.pre_reorder_onMouseUp then
        button.pre_reorder_onMouseUp = button.onMouseUp
    end
    button.onMouseUp = SortableBackpackButton.onMouseUp

    return button
end

function SortableBackpackButton:onMouseDown(x, y)
    self.pre_reorder_onMouseDown(self, x, y)
    self.reorderStartMouseY = getMouseY()
    self.reorderStartY = self:getY()

    local invPage = getPlayerInventory(self.playerNum)
    if not invPage then return end

    self.canDragToReorder = not ReorderContainersService.isLocked(invPage) and ReorderContainersService.canReorderBackpacks(invPage)
end

function SortableBackpackButton:onMouseMove(dx, dy, skipOgMouseMove)
    if not skipOgMouseMove then -- skipOgMouseMove is true when we're calling this from onMouseMoveOutside
        self.pre_reorder_onMouseMove(self, dx, dy)
    end

    if self.pressed and self.canDragToReorder then
        local inventoryPage = getPlayerInventory(self.playerNum)
        if not inventoryPage then return end

        if math.abs(self.reorderStartMouseY - getMouseY()) > inventoryPage.buttonSize/2 then
            self.draggingToReorder = true
        end

        local parent = self.parent
        if self.draggingToReorder and parent then
            local x = getMouseX()
            local y = getMouseY()
            local parentY = parent:getAbsoluteY()
            local newY = y - parentY - self:getHeight() / 2
            
            newY = math.max(-4, newY)

            self:setY(newY)
            self:bringToTop()
    
            self.draggingToReorder = true
        end
    end
end

function SortableBackpackButton:onMouseMoveOutside(dx, dy)
    self.pre_reorder_onMouseMoveOutside(self, dx, dy)
    SortableBackpackButton.onMouseMove(self, dx, dy, true)

    -- if the mouse is no longer down, we missed the mouse up event
    if self.draggingToReorder and not isMouseButtonDown(0) then
        SortableBackpackButton.onMouseUp(self, 0, 0)
    end
end

function SortableBackpackButton:onMouseUp(x, y)
    local page = getPlayerInventory(self.playerNum)
    if page and self.draggingToReorder then
        self.pressed = false;
        self.draggingToReorder = false
        page:reorderContainerButtons(self)
        page:refreshBackpacks()
    else
        self.pre_reorder_onMouseUp(self, x, y)
    end
end

return SortableBackpackButton