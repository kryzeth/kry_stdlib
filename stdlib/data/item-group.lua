local Data = require('__kry_stdlib__/stdlib/data/data') --[[@as StdLib.Data]]

--- Wrapper for Factorio item-group prototypes.
---@class StdLib.Data.ItemGroup : StdLib.Data
local ItemGroup = {
    __class = 'ItemGroup',
    __index = Data,
}

--- Looks up and wraps an item group by name.
---@param item_group string Item-group prototype name
---@return StdLib.Data.ItemGroup item_group
function ItemGroup:__call(item_group)
    local new = self:get(item_group, 'item-group')
    ---@cast new StdLib.Data.ItemGroup
    return new
end
setmetatable(ItemGroup, ItemGroup)

--- Counts the number of visible rows used by this item group.
--- An item subgroup contributes zero rows if it contains no visible entries.
--- Each subgroup contributes one row for 1-10 visible entries.
--- Each subgroup contributes two rows for 11-20 visible entries, etc.
---@return integer? rows
function ItemGroup:count_rows()
    if self:is_valid('item-group') then
        local ItemSubgroup = require('__kry_stdlib__/stdlib/data/item-subgroup')
        local rows = 0

        for _, subgroup in pairs(data.raw['item-subgroup'] or {}) do
            if subgroup.group == self.name then
                rows = rows + ItemSubgroup(subgroup.name):count_rows()
            end
        end

        return rows
    end
end
ItemGroup.get_row_count = ItemGroup.count_rows
ItemGroup.count_group_rows = ItemGroup.count_rows

return ItemGroup
