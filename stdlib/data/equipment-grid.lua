local Data = require('__kry_stdlib__/stdlib/data/data')
local Category = require('__kry_stdlib__/stdlib/data/category')

--- Wrapper for Factorio equipment-grid prototypes.
---@class StdLib.Data.EquipmentGrid : StdLib.Data
---@field width integer
---@field height integer
---@field equipment_categories string[]
---@field locked? boolean
local EquipmentGrid = {
    __class = 'EquipmentGrid',
    __index = Data,
}

--- Looks up and wraps an equipment grid by name.
---@param name string Equipment-grid prototype name
---@return StdLib.Data.EquipmentGrid grid
function EquipmentGrid:__call(name)
    local new = self:get(name, 'equipment-grid')
    ---@cast new StdLib.Data.EquipmentGrid
    return new
end

setmetatable(EquipmentGrid, EquipmentGrid)

--- Sets the equipment grid's width.
---@param width integer Grid width
---@return boolean updated Whether the equipment grid was valid and updated
function EquipmentGrid:update_width(width)
    assert(type(width) == "number", "Expected argument to be a number")
	if self:is_valid() then
		self.width = width
		return true
	end
	return false
end

--- Sets the equipment grid's height.
---@param height integer Grid height
---@return boolean updated Whether the equipment grid was valid and updated
function EquipmentGrid:update_height(height)
    assert(type(height) == "number", "Expected argument to be a number")
	if self:is_valid() then
		self.height = height
		return true
	end
	return false
end

--- Sets the equipment grid's width and height.
---@param width integer Grid width
---@param height integer Grid height
---@return boolean updated Whether the equipment grid was valid and updated
function EquipmentGrid:update_size(width, height)
    assert(type(width) == "number", "Expected second argument to be a number")
    assert(type(height) == "number", "Expected first argument to be a number")
	if self:is_valid() then
		self.width = width
		self.height = height
		return true
	end
	return false
end

--- Replaces the equipment categories accepted by this grid with one category.
---@param category_name string Equipment category name
---@return self
function EquipmentGrid:set_category(category_name)
    assert(type(category_name) == "string", "Expected category name to be a string.")

    if self:is_valid() then
        local category = Category(category_name, 'equipment-category')
        if category:is_valid() then
            self.equipment_categories = {category_name}
        end
    end

    return self
end
EquipmentGrid.set_cat  = EquipmentGrid.set_category

--- Replaces the equipment categories accepted by this grid.
---@param category_list string[] Equipment categories
---@return self
function EquipmentGrid:set_categories(category_list)
    assert(type(category_list) == "table", "Expected categories to be a table.")

    if self:is_valid() then
        self.equipment_categories = {}
        for _, category_name in ipairs(category_list) do
            self:add_category(category_name)
        end
    end

    return self
end
EquipmentGrid.set_cats = EquipmentGrid.set_categories

--- Adds one equipment category.
---@param category_name string Equipment category name
---@return self
function EquipmentGrid:add_category(category_name)
    assert(type(category_name) == "string", "Expected category name to be a string.")

    if self:is_valid() then
        Category(category_name, 'equipment-category'):add_to(self, 'equipment_categories')
    end

    return self
end
EquipmentGrid.add_cat  = EquipmentGrid.add_category

--- Adds multiple equipment categories.
---@param category_list string[] Equipment categories
---@return self
function EquipmentGrid:add_categories(category_list)
    assert(type(category_list) == "table", "Expected categories to be a table.")

    if self:is_valid() then
        for _, category_name in ipairs(category_list) do
            self:add_category(category_name)
        end
    end

    return self
end
EquipmentGrid.add_cats = EquipmentGrid.add_categories

--- Removes one equipment category.
---@param category_name string Equipment category name
---@return self
function EquipmentGrid:remove_category(category_name)
    assert(type(category_name) == "string", "Expected category name to be a string.")

    if self:is_valid() then
        Category(category_name, 'equipment-category'):remove_from(self, 'equipment_categories')
    end

    return self
end
EquipmentGrid.rem_cat  = EquipmentGrid.remove_category
EquipmentGrid.rem_category = EquipmentGrid.remove_category

--- Removes multiple equipment categories.
---@param category_list string[] Equipment categories
---@return self
function EquipmentGrid:remove_categories(category_list)
    assert(type(category_list) == "table", "Expected categories to be a table.")

    if self:is_valid() then
        for _, category_name in ipairs(category_list) do
            self:remove_category(category_name)
        end
    end

    return self
end
EquipmentGrid.rem_cats = EquipmentGrid.remove_categories
EquipmentGrid.rem_cats = EquipmentGrid.remove_categories

return EquipmentGrid
