local ModDataConstants = require("ReorderContainers/ModDataConstants")
local PREFIX = ModDataConstants.PREFIX

---@type RCSortingData
local DEFAULT_SORT_DATA = {
    sortPriority = nil,
    isManual = false
}

---@type RCPlayerOptions
local DEFAULT_PLAYER_OPTIONS = {
    lockInventorySorting = false,
    lockLootSorting = false,
    allowLootSorting = false,
}

local function fillBlanks(target, source)
    for k, v in pairs(source) do
        if target[k] == nil then
            target[k] = v
        end
    end
end

---@class ModDataService
local ModDataService = {}

-- Ensures the mod data table for this mod exists, and returns it
function ModDataService.getModuleData(rootModData)
    local rcModData = rootModData[PREFIX]
    if not rcModData then
        rcModData = {}
        rootModData[PREFIX] = rcModData
    end
    return rcModData
end

-- Find and returns a specific object in our mod data, ensuring it exists and filling in any missing fields from the default object
function ModDataService.getModuleObject(rootModData, objectKey, defaultObject)
    local rcModData = ModDataService.getModuleData(rootModData)
    local obj = rcModData[objectKey]
    if not obj then
        obj = {}
        rcModData[objectKey] = obj
    end
    fillBlanks(obj, defaultObject)
    return obj
end

---@param rootModData table
---@param keySuffix string
---@return RCSortingData
function ModDataService.getSortData(rootModData, keySuffix)
    local key = ModDataConstants.SORT_DATA_KEY .. keySuffix
    return ModDataService.getModuleObject(rootModData, key, DEFAULT_SORT_DATA)
end

---@param player IsoPlayer
---@return RCPlayerOptions
function ModDataService.getPlayerOptions(player)
    return ModDataService.getModuleObject(player:getModData(), ModDataConstants.PLAYER_OPTIONS_KEY, DEFAULT_PLAYER_OPTIONS)
end

return ModDataService