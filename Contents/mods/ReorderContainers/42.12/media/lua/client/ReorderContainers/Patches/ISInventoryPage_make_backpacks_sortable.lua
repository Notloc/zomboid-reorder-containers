local SortableBackpackButton = require("ReorderContainers/UI/SortableBackpackButton")

local og_addContainerButton = ISInventoryPage.addContainerButton
function ISInventoryPage:addContainerButton(container, texture, name, tooltip)
    local button = og_addContainerButton(self, container, texture, name, tooltip)
    return SortableBackpackButton:inject(button, self.player)
end