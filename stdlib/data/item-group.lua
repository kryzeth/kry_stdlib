local Data = require('__kry_stdlib__/stdlib/data/data') --[[@as StdLib.Data]]

--- ItemGroup
---@class StdLib.Data.ItemGroup : StdLib.Data
local ItemGroup = {
    __class = 'ItemGroup',
    __index = Data,
}

function ItemGroup:__call(item_group)
    return self:get(item_group, 'item-group')
end
setmetatable(ItemGroup, ItemGroup)

--- Count the number of visible rows used by this item group.
--- item subgroup contributes zero rows if it contains no visible entries.
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