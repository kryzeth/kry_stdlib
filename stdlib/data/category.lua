local Data = require('__kry_stdlib__/stdlib/data/data')
local Table = require('__kry_stdlib__/stdlib/utils/table') --[[@as StdLib.Utils.Table]]

--- Wrapper for Factorio category prototypes.
---@class StdLib.Data.Category : StdLib.Data
---@field type? StdLib.Data.CategoryType

---@alias StdLib.Data.CategoryType
---| '"ammo-category"'
---| '"equipment-category"'
---| '"fuel-category"'
---| '"recipe-category"'
---| '"module-category"'
---| '"rail-category"'
---| '"resource-category"'

local Category = {
    __class = 'Category',
    __index = Data,
    __call = Data.__call
}
setmetatable(Category, Category)

--- Supported category prototype types.
---@type table<StdLib.Data.CategoryType, true>
Category.category_types = {
    ['ammo-category'] = true,
    ['equipment-category'] = true,
    ['fuel-category'] = true,
    ['recipe-category'] = true,
    ['module-category'] = true,
    ['rail-category'] = true,
    ['resource-category'] = true
}

--- Adds this category to a target's category-list field.
---@param target StdLib.Data Target prototype wrapper
---@param field string Category-list field
---@return StdLib.Data target
function Category:add_to(target, field)
    if self:is_valid() and target:is_valid() then
        target[field] = target[field] or {}
        table.insert(target[field], self.name)
    end

    return target
end

--- Removes this category from a target's category-list field.
---@param target StdLib.Data Target prototype wrapper
---@param field string Category-list field
---@return StdLib.Data target
function Category:remove_from(target, field)
    if self:is_valid() and target:is_valid() then
        Table.remove_string(target[field] or {}, self.name)
    end

    return target
end

--- Replaces this category with another category.
---@param target StdLib.Data Target prototype wrapper
---@param field string Category-list field
---@param replacement_name string Replacement category name
---@return StdLib.Data target
function Category:replace(target, field, replacement_name)
    local replacement = Category(replacement_name, self.type)

    if replacement:is_valid() then
        self:remove_from(target, field)
        replacement:add_to(target, field)
    end

    return target
end

return Category
