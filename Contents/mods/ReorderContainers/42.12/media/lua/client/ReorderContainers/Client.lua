local Constants = require("ReorderContainers/NetworkConstants")
local ModDataService = require("ReorderContainers/ModDataService")
local MOD_PREFIX = Constants.MODULE

local Client = {}

---@param parentObj GameEntity|IsoObject|nil
---@param playerObj IsoPlayer|nil
---@param specialKey string|nil
function Client.saveModData(parentObj, playerObj, specialKey)
    if not isClient() or isServer() then return end

    if not parentObj then
        return
    end

    if instanceof(parentObj, "IsoObject") then
        ---@cast parentObj IsoObject
        parentObj:transmitModData()
        return
    end

    if instanceof(parentObj, "InventoryItem") and playerObj then
        ---@cast parentObj InventoryItem

        local rootModData = parentObj:getModData()
        local sortData = ModDataService.getSortData(rootModData, specialKey)

        ---@cast parentObj InventoryItem
        local worldItem = parentObj:getWorldItem()
        if worldItem then
            local square = worldItem:getSquare()
            ---@type SaveGroundItemDataRequest
            local saveGroundItemData = {
                itemId = parentObj:getID(),
                x = square:getX(),
                y = square:getY(),
                z = square:getZ(),
                modData = sortData,
            }
            sendClientCommand(playerObj, Constants.MODULE, Constants.COMMAND_SAVE_GROUND_ITEM_DATA, saveGroundItemData)
        else
            ---@type SaveItemDataRequest
            local saveItemData = {
                itemId = parentObj:getID(),
                modData = sortData,
            }
            sendClientCommand(playerObj, Constants.MODULE, Constants.COMMAND_SAVE_ITEM_DATA, saveItemData)
        end
        return
    end
end

return Client