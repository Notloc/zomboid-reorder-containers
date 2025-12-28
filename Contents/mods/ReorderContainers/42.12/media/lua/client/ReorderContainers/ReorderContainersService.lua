local Client = require("ReorderContainers/Client")
local ModDataService = require("ReorderContainers/ModDataService")

---@class ReorderContainersService
local ReorderContainersService = {}

---@param player IsoPlayer
---@param inventory ItemContainer
---@return RCSortingData, IsoObject|InventoryItem|IsoPlayer, string
ReorderContainersService.getSortDataAndParentObjectAndKeySuffix = function(player, inventory)
    local parentObject = nil
    local rootModData = nil

    -- The key suffix helps use prevent collisions with other players when sorting the loot window
    -- It also lets us store multiple sort data entries in the player's mod data for special containers
    local keySuffix = player:getUsername()
    
    local invType = inventory:getType()
    local isPlayerInv = inventory == player:getInventory()

    if isPlayerInv then
        keySuffix = invType
        rootModData = player:getModData()
        parentObject = player
    else
        local item = inventory:getContainingItem()
        local isoObject = inventory:getParent()
        if item then
            rootModData = item:getModData()
            parentObject = item
        elseif isoObject then
            rootModData = isoObject:getModData()
            parentObject = isoObject
        end
    end

    if not parentObject or not rootModData then
        keySuffix = invType
        rootModData = player:getModData()
        parentObject = player
    end

    local sortData= ModDataService.getSortData(rootModData, keySuffix)
    return sortData, parentObject, keySuffix
end

---@param player IsoPlayer
---@param inventory ItemContainer
---@param inventoryPage ISInventoryPage
---@return number
ReorderContainersService.getSortPriority = function(player, inventory, inventoryPage)
    local sortData = ReorderContainersService.getSortDataAndParentObjectAndKeySuffix(player, inventory)
    return (sortData and sortData.sortPriority) or ReorderContainersService.getDefaultSortPriority(inventory, inventoryPage)
end

---@param player IsoPlayer
---@param inventory ItemContainer
---@param priority number|nil
---@param isManual boolean
ReorderContainersService.setSortPriority = function(player, inventory, priority, isManual)
    local sortData, parent, keySuffix = ReorderContainersService.getSortDataAndParentObjectAndKeySuffix(player, inventory)
    if sortData then
        sortData.sortPriority = priority
        sortData.isManual = isManual
        Client.saveModData(parent, player, keySuffix)
    end
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
---@return boolean
ReorderContainersService.isManual = function(player, inventory)
    local sortData = ReorderContainersService.getSortDataAndParentObjectAndKeySuffix(player, inventory)
    return sortData and sortData.isManual or false
end

---@param playerObj IsoPlayer
---@return boolean
ReorderContainersService.getSortLootWindow = function(playerObj)
    local options = ModDataService.getPlayerOptions(playerObj)
    return options.allowLootSorting
end

---@param playerObj IsoPlayer
---@param value boolean
ReorderContainersService.setSortLootWindow = function(playerObj, value)
    local options = ModDataService.getPlayerOptions(playerObj)
    options.allowLootSorting = value
    playerObj:transmitModData()
end

--- Not to be confused with isLocked. This checks if sorting is enabled for the given inventory page.
--- Always true for the inventory, but can be disabled for loot windows.
---@param inventoryPage ISInventoryPage
---@return boolean
ReorderContainersService.isSortingEnabled = function(inventoryPage)
    local playerObj = getSpecificPlayer(inventoryPage.player)
    local options = ModDataService.getPlayerOptions(playerObj)
    local isLootPage = inventoryPage == getPlayerLoot(inventoryPage.player)
    return not isLootPage or options.allowLootSorting
end

---@param inventoryPage ISInventoryPage
---@return boolean
ReorderContainersService.isLocked = function(inventoryPage)
    local player = getSpecificPlayer(inventoryPage.player)
    local options = ModDataService.getPlayerOptions(player)
    if inventoryPage.onCharacter then
        return options.lockInventorySorting
    else
        return options.lockLootSorting
    end
end

---@param playerObj IsoPlayer
ReorderContainersService.toggleLootLock = function(playerObj)
    local options = ModDataService.getPlayerOptions(playerObj)
    options.lockLootSorting = not options.lockLootSorting
    playerObj:transmitModData()
    return options.lockLootSorting
end

---@param playerObj IsoPlayer
ReorderContainersService.toggleInventoryLock = function(playerObj)
    local options = ModDataService.getPlayerOptions(playerObj)
    options.lockInventorySorting = not options.lockInventorySorting
    playerObj:transmitModData()
    return options.lockInventorySorting
end

return ReorderContainersService