local Data = require('__kry_stdlib__/stdlib/data/data')
local Table = require('__kry_stdlib__/stdlib/utils/table') --[[@as StdLib.Utils.Table]]
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

--- Replaces the equipment categories accepted by this grid.
---@param categories string|string[] Equipment category name or names
---@return nil
function EquipmentGrid:set_categories(categories)
	if self:is_valid() then
		assert(type(categories) == "table" or type(categories) == "string",
			"Expected argument to be a table or a string.\nReceived:"..serpent.block(categories))
		if type(categories) == "string" then
			self.equipment_categories = {categories}
		elseif type(categories) == "table" then
			self.equipment_categories = Table.deepcopy(categories)
		end
	end
end
EquipmentGrid.set_category = EquipmentGrid.set_categories
EquipmentGrid.set_cats = EquipmentGrid.set_categories
EquipmentGrid.set_cat = EquipmentGrid.set_categories

--- Adds one or more equipment categories accepted by this grid.
---@param new_categories string|string[] Equipment category name or names
---@return self
function EquipmentGrid:add_categories(new_categories)
	assert(type(new_categories) == "table" or type(new_categories) == "string",
		"Expected argument to be a table or a string.")
	if self:is_valid() then
		if type(new_categories) == "string" then
			Category(new_categories, 'equipment-category'):add_to(self, 'equipment_categories')
		elseif type(new_categories) == "table" then
			for _, category_name in ipairs(new_categories) do
				Category(category_name, 'equipment-category'):add_to(self, 'equipment_categories')
			end
		end
	end
	return self
end
EquipmentGrid.add_category = EquipmentGrid.add_categories
EquipmentGrid.add_cats = EquipmentGrid.add_categories
EquipmentGrid.add_cat = EquipmentGrid.add_categories

--- Removes one or more equipment categories accepted by this grid.
---@param categories string|string[] Equipment category name or names
---@return self
function EquipmentGrid:remove_categories(categories)
	assert(type(categories) == "table" or type(categories) == "string",
		"Expected argument to be a table or a string.")
	if self:is_valid() then
		if type(categories) == "string" then
			Category(categories, 'equipment-category'):remove_from(self, 'equipment_categories')
		elseif type(categories) == "table" then
			for _, category_name in ipairs(categories) do
				Category(category_name, 'equipment-category'):remove_from(self, 'equipment_categories')
			end
		end
	end
	return self
end
EquipmentGrid.rem_category = EquipmentGrid.remove_categories
EquipmentGrid.rem_cats = EquipmentGrid.remove_categories
EquipmentGrid.rem_cat = EquipmentGrid.remove_categories

return EquipmentGrid
