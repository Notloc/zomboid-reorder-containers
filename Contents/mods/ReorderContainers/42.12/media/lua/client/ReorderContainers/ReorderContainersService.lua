local SORT_KEY = "ReorderContainers_Sort"
local SET_MANUALLY = "ReorderContainers_SetManually"
local INV_LOCK = "ReorderContainers_InvLock"
local LOOT_LOCK = "ReorderContainers_LootLock"
local LOOT_SORT = "ReorderContainers_LootSort"

-- For special containers that aren't "real"
local SPECIAL_SORT_KEYS_BY_INV_TYPE = {
    ["floor"] = "ReorderContainers_Sort_Floor",

    -- SpiffUI
    ["SpiffBodies"] = "Reorder_SpiffBodies",
    ["SpiffContainer"] = "Reorder_SpiffContainer",
    ["SpiffPack"] = "Reorder_SpiffPack",
    ["SpiffEquip"] = "Reorder_SpiffEquip",
}

---@class ReorderContainersService
local ReorderContainersService = {}

---@param player IsoPlayer
---@param inventory ItemContainer
---@return table|nil, string, GameEntity|nil
ReorderContainersService.getTargetModDataAndSortKeyAndParentObject = function(player, inventory)
    local playerKey = player:getUsername()
    local sortKey = SORT_KEY
    local parentObject = nil
    local targetModData = nil

    if inventory == player:getInventory() then
        sortKey = SORT_KEY
        targetModData = player:getModData()
    elseif SPECIAL_SORT_KEYS_BY_INV_TYPE[inventory:getType()] then
        sortKey = SPECIAL_SORT_KEYS_BY_INV_TYPE[inventory:getType()]
        targetModData = player:getModData()
    else
        sortKey = playerKey..SORT_KEY

        local item = inventory:getContainingItem()
        local isoObject = inventory:getParent()
        if item then
            targetModData = item:getModData()
            parentObject = item
        elseif isoObject then
            targetModData = isoObject:getModData()
            parentObject = isoObject
        end
    end

    return targetModData, sortKey, parentObject
end

---@param player IsoPlayer
---@param inventory ItemContainer
---@param inventoryPage ISInventoryPage
---@return number
ReorderContainersService.getSortPriority = function(player, inventory, inventoryPage)
    local targetModData, sortKey = ReorderContainersService.getTargetModDataAndSortKeyAndParentObject(player, inventory)
    if targetModData then
        return targetModData[sortKey] or ReorderContainersService.getDefaultSortPriority(inventory, inventoryPage)
    end
    return ReorderContainersService.getDefaultSortPriority(inventory, inventoryPage)
end

---@param inventory ItemContainer
---@param inventoryPage ISInventoryPage
ReorderContainersService.getDefaultSortPriority = function(inventory, inventoryPage)
    local index = 0
    for i, backpack in ipairs(inventoryPage.backpacks) do
        ---@cast backpack SortableBackpackButton
        if backpack.inventory == inventory then
            index = i
            break
        end
    end
    return 1000 + index
end

---@param player IsoPlayer
---@param inventory ItemContainer
---@param priority number|nil
---@param isManual boolean
ReorderContainersService.setSortPriority = function(player, inventory, priority, isManual)
    local targetModData, sortKey = ReorderContainersService.getTargetModDataAndSortKeyAndParentObject(player, inventory)
    if targetModData then
        targetModData[sortKey] = priority
        targetModData[SET_MANUALLY] = isManual
    end
end

---@param player IsoPlayer
---@param inventory ItemContainer
---@return boolean
ReorderContainersService.isManual = function(player, inventory)
    local targetModData, sortKey = ReorderContainersService.getTargetModDataAndSortKeyAndParentObject(player, inventory)
    return targetModData and targetModData[SET_MANUALLY]
end

---@param playerObj IsoPlayer
---@return boolean
ReorderContainersService.getSortLootWindow = function(playerObj)
    return playerObj:getModData()[LOOT_SORT]
end

---@param playerObj IsoPlayer
---@param value boolean
ReorderContainersService.setSortLootWindow = function(playerObj, value)
    playerObj:getModData()[LOOT_SORT] = value
end

---@param inventoryPage ISInventoryPage
---@return boolean
ReorderContainersService.canReorderBackpacks = function(inventoryPage)
    return inventoryPage ~= getPlayerLoot(inventoryPage.player) or ReorderContainersService.getSortLootWindow(getSpecificPlayer(inventoryPage.player))
end

---@param inventoryPage ISInventoryPage
---@return boolean
ReorderContainersService.isLocked = function(inventoryPage)
    local player = getSpecificPlayer(inventoryPage.player)
    if inventoryPage.onCharacter then
        return player:getModData()[INV_LOCK]
    else
        return player:getModData()[LOOT_LOCK]
    end
end

---@param playerObj IsoPlayer
ReorderContainersService.toggleLootLock = function(playerObj)
    local modData = playerObj:getModData()
    modData[LOOT_LOCK] = not modData[LOOT_LOCK]
    return modData[LOOT_LOCK]
end

---@param playerObj IsoPlayer
ReorderContainersService.toggleInventoryLock = function(playerObj)
    local modData = playerObj:getModData()
    modData[INV_LOCK] = not modData[INV_LOCK]
    return modData[INV_LOCK]
end

return ReorderContainersService