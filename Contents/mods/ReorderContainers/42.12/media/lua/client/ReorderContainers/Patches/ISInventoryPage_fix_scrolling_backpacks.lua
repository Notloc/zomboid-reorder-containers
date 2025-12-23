local og_onMouseWheel = ISInventoryPage.onMouseWheel
function ISInventoryPage:onMouseWheel(del)
    -- Store the original order of the backpacks
    local originalOrder = {}
    for index, button in ipairs(self.backpacks) do
        originalOrder[button] = index
    end

    -- Sort the backpacks by their Y position so that scrolling works as expected
    table.sort(self.backpacks, function(a, b) return a:getY() < b:getY() end)
    
    -- The backpacks *might* get refreshed by the mousescroll, so we track that
    self.pendingReorder = true

    local retVal = og_onMouseWheel(self, del)

    -- The backpacks were not refreshed, so we need to restore the original order
    if self.pendingReorder then
        table.sort(self.backpacks, function(a, b) return originalOrder[a] < originalOrder[b] end)
        self.pendingReorder = false
    end

    return retVal
end