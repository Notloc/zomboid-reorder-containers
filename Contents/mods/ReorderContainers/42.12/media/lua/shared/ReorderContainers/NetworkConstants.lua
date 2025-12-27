---@class SaveItemDataRequest
---@field itemId integer
---@field modData table<string, any>

---@class SaveGroundItemDataRequest
---@field itemId integer
---@field x integer
---@field y integer
---@field z integer
---@field modData table<string, any>

return {
    MODULE = "ReorderContainers",
    COMMAND_SAVE_ITEM_DATA = "SaveItemSortData",
    COMMAND_SAVE_GROUND_ITEM_DATA = "SaveGroundItemSortData",
}