local Data = require('__kry_stdlib__/stdlib/data/data') --[[@as StdLib.Data]]
local Table = require('__kry_stdlib__/stdlib/utils/table') --[[@as StdLib.Utils.Table]]

--- Wrapper for Factorio item-like prototypes.
---@class StdLib.Data.Item : StdLib.Data
local Item = {
    __class = 'Item',
    __index = Data,
    __call = Data.__call
}
setmetatable(Item, Item)

--- Converts a lab name or array of lab names to an array.
--- Returns every lab prototype name when `params` is omitted.
---@param params? string|string[] Lab name or names
---@return string[] lab_names
local function make_table(params)
    if not params then
        return Table.keys(data.raw.lab)
    else
        return type(params) == 'table' and params or { params }
    end
end

--- Adds or removes an item from the inputs of selected labs.
---@param name string Item prototype name
---@param lab_names? string|string[] Lab name or names; all labs when omitted
---@param add boolean Add the item when true; remove it otherwise
local function change_inputs(name, lab_names, add)
    lab_names = make_table(lab_names)
    local Entity = require('__kry_stdlib__/stdlib/data/entity')
    for _, lab_name in pairs(lab_names) do
        Entity(lab_name, 'lab'):change_lab_inputs(name, add)
    end
end

--- Adds this item to the inputs of selected labs.
---@param lab_names? string|string[] Lab name or names; all labs when omitted
---@return self
function Item:add_to_labs(lab_names)
    if self:is_valid() then
        change_inputs(self.name, lab_names, true)
    end
    return self
end

--- Removes this item from the inputs of selected labs.
---@param lab_names? string|string[] Lab name or names; all labs when omitted
---@return self
function Item:remove_from_labs(lab_names)
    if self:is_valid() then
        change_inputs(self.name, lab_names, false)
    end
    return self
end

return Item
