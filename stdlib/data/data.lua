require('__kry_stdlib__/stdlib/core') -- Calling core up here to setup any required global stuffs

if _G.remote and _G.script then
    error('Data Modules can only be required in the data stage', 2)
end

local table = require('__kry_stdlib__/stdlib/utils/table')
local groups = require('__kry_stdlib__/stdlib/data/modules/groups')

--- Base wrapper for Factorio data-stage prototypes.
---@class StdLib.Data : StdLib.Core
---@field name? string
---@field type? string
---@field _raw? table
---@field _products? table
---@field _parent? StdLib.Data
---@field _requested_object? string|table
---@field _requested_type? string
---@field valid string|false
---@field extended boolean
---@field overwrite boolean
---@field class table
---@field options table<string, boolean>
local Data = {
    __class = 'Data',
    __index = require('__kry_stdlib__/stdlib/core'),
    Sprites = require('__kry_stdlib__/stdlib/data/modules/sprites'),
    Pipes = require('__kry_stdlib__/stdlib/data/modules/pipes'),
    Util = require('__kry_stdlib__/stdlib/data/modules/util'),
    _default_options = {
        ['silent'] = false, -- Don't log if not present
        ['fail'] = false, -- Error instead of logging
        ['verbose'] = false, -- Extra logging info
        ['extend'] = true, -- Extend the data
        ['skip_string_validity'] = false, -- Skip checking for valid data
        ['items_and_fluids'] = true -- consider fluids valid for Item checks
    }
}
setmetatable(Data, Data)

local inspect = _ENV.inspect
local rawtostring = _ENV.rawtostring
--))

--(( Local Functions ))--

-- This is the tracing function.
local function log_trace(self, object, object_type)
    local msg = (self.__class and self.__class or '') .. (self.name and '/' .. self.name or '') .. ' '
    msg = msg .. (object_type and (object_type .. '/') or '') .. tostring(object) .. ' does not exist.'

    local trace = _ENV.data_traceback()
    log(msg .. trace)
end
--)) END Local Functions ((--

--(( METHODS ))--

--- Returns whether this wrapper contains a valid prototype.
---@param type string? Prototype type to require
---@return boolean valid
function Data:is_valid(type)
    if type then
        return rawget(self, 'valid') == type or false
    else
        return rawget(self, 'valid') and true or false
    end
end

--- Returns whether this wrapper is an instance of the requested class.
---@param class string? Class name to require
---@return boolean matches
function Data:is_class(class)
    if class then
        return self.__class == class or false
    else
        return self.__class and true or false
    end
end

--- Prints selected fields from this wrapper.
---@param ... string Field names
---@return self
function Data:print(...)
    local arr = {}
    for _, key in pairs { ... } do
        arr[#arr + 1] = inspect(self[key])
    end
    print(table.unpack(arr))
    return self
end

--- Logs this wrapper or a supplied value using the inspect formatter.
---@param tbl? any Value to log; defaults to this wrapper
---@return self
function Data:log(tbl)
    local reduce_spam = function(item, path)
        -- if item == self.class then
        --     return {item.__class, self.__class}
        -- end
        if item == self._object_mt then
            return { self.__class, tostring(self) }
        end
        if path[#path] == 'parent' then
            return { tostring(item), item.__class }
        end
        if path[#path] == 'class' then
            return { self.__class, item.__class }
        end
        if path[#path] == inspect.METAtable then
            return { self.__class or item.__class, item.__class }
        end
        return item
    end
    log(inspect(tbl and tbl or self, { process = reduce_spam }))
    return self
end

--- Logs this wrapper using Serpent.
---@return self
function Data:serpent()
    log(serpent.block(self, { name = self.name, metatostring = false, nocode = true, comment = false }))
    return self
end

--- Raises an error.
---@param msg? string Error message
function Data:error(msg)
    error(msg or 'Forced Error')
    return self
end

--- Raises an error containing a Serpent dump of the wrapped prototype.
function Data:serpent_error()
    local dump = serpent.block(self._raw, {
        name = self.name or "object",
        metatostring = false,
        nocode = true,
        comment = false
    })

    error(dump, 2)
end

--- Changes the validity of this wrapper.
---@param bool boolean Whether the wrapper should remain valid
---@return self
function Data:continue(bool)
    rawset(self, 'valid', (bool and rawget(self, '_raw') and self.type) or false)
    return self
end

--- Retains validity only when the supplied predicate returns a truthy value.
---@param func fun(self: self, ...: any): any Predicate that receives this wrapper and any additional arguments
---@param ... any Additional predicate arguments
---@return self
function Data:continue_if(func, ...)
    rawset(self, 'valid', (func(self, ...) and rawget(self, '_raw') and self.type) or false)
    return self
end

--- Adds the wrapped prototype to `data.raw`.
---@param force? boolean Extend even if the prototype is already extended
---@return self
function Data:extend(force)
    if self.valid and (self.options.extend or force) then
        if not self.extended or force then
            local t = data.raw[self.type]
            if t == nil then
                t = {}
                data.raw[self.type] = t
            end
            t[self.name] = self._raw
            self.extended = true
        end
    end
    if force then
        log('NOTICE: Force extend ' .. self.type .. '/' .. self.name)
    elseif not self.options.extend and not self.extended then
        log('NOTICE: Did not extend ' .. self.type .. '/' .. self.name)
    end
    if self.overwrite then
        log('NOTICE: Overwriting ' .. self.type .. '/' .. self.name)
    end
    return self
end

--- Copies a data object (recipe, item, entity, etc) under a new name.
---@param new_name string The new name for the data object.
---@param result? string Replacement name for result-related fields; defaults to `new_name`
---@param opts? table<string, boolean> Options for the copied wrapper
---@return self
function Data:copy(new_name, result, opts)
    assert(type(new_name) == 'string', 'new_name must be a string')
	if self:is_valid() then
        result = result or new_name
        local copy = table.deep_copy(rawget(self, '_raw'))
        copy.name = new_name

        -- For entities
        -- Need to also check mining results!!!!!!
        if copy.minable and copy.minable.result then
            copy.minable.result = result
        end

        -- For items
        if copy.place_result then
            copy.place_result = result
        end

        -- rail planners
        if copy.placeable_by and copy.placeable_by.item then
            copy.placeable_by.item = result
        end

		-- for recipes
		if copy.main_product then
			copy.main_product = new_name
		end

        -- For recipes, we ignore results with non-matching names
        if copy.type == 'recipe' and copy.results then  -- results field is optional
			if #copy.results == 1 then -- handles vast majority of cases
				copy.results[1].name = new_name
			else for _, result in pairs(copy.results) do   
					if result.name == self.name then
						result.name = new_name
					end
				end
			end
        end

        return self(copy, nil, opts or self.options)
    else	-- this should help improve the error checking
		local requested_object = rawget(self, '_requested_object')
		local requested_type = rawget(self, '_requested_type')

		error(	-- hopefully better error formatting
			'\nCannot Copy, Invalid Prototype!\n'..
			'\nAttemped to copy data.raw.["' .. tostring(requested_type) ..
			'"].["' .. tostring(requested_object)..'"]'.. ' -> ' .. tostring(new_name),
			4
		)
	end
end
Data.krycopy = Data.copy

--- Renames a data object (recipe, item, entity, etc) by copying and removing the original.
---@param new_name string The new name for the data object.
---@param result? string Name for fields such as `minable.result` or `place_result`
---@param opts? table<string, boolean> Options for the copied wrapper
---@return self
function Data:replace_name(new_name, result, opts)
    assert(type(new_name) == 'string', 'new_name must be a string')

    if self:is_valid() then
        result = result or new_name

        -- Perform the copy using the existing logic
        local new_data = self:copy(new_name, result, opts)

        -- Delete the original from data.raw
        local raw = rawget(self, '_raw')
        if raw and raw.type and raw.name then
            data.raw[raw.type][raw.name] = nil
        end

        return new_data
    else
        error('Cannot Move, Invalid Prototype: '..new_name, 4)
    end
end

--- Changes the type of a data object by copying it and removing the original.
---
--- The original prototype is removed from `data.raw` after the copy is created.
---@param new_type string The new prototype type
---@param opts? table<string, boolean> Options for the copied wrapper; defaults to `self.options`
---@return self new_data The newly wrapped prototype
function Data:change_type(new_type, opts)
    assert(type(new_type) == 'string', 'new_type must be a string')
	if self:is_valid() then
		-- Copy the raw prototype so we do not mutate the original in-place
        local copy = table.deep_copy(rawget(self, '_raw'))
		copy.type = new_type
		
		-- Wrap the copied prototype using the existing logic
        local new_data = self(copy, nil, opts or self.options)
		
		-- Delete the original from data.raw
        local raw = rawget(self, '_raw')
        if raw and raw.type and raw.name then
            data.raw[raw.type][raw.name] = nil
        end
		
		return new_data
    else
        error('Cannot Change Type, Invalid Prototype: '..new_type, 4)
	end
end

--(( Flags ))--
--- Returns this prototype's flags as a unique array.
---@param create? boolean Assign the unique-array wrapper back to `self.flags`
---@return StdLib.UniqueArray flags
function Data:Flags(create)
    if create then
        self.flags = Data.Unique_Array(self.flags)
    end
    return self.flags or Data.Unique_Array()
end

--- Adds a prototype flag.
---@param flag string Flag to add
---@return self
function Data:add_flag(flag)
    self:Flags(true):add(flag)
    return self
end

--- Removes a prototype flag.
---@param flag string Flag to remove
---@return self
function Data:remove_flag(flag)
    self:Flags(true):remove(flag)
    return self
end

--- Returns whether all requested flags are present.
---@param flag string|string[] Flag or flags to check
---@return boolean present
function Data:has_flag(flag)
    return self:Flags():all(flag)
end

--- Returns whether any requested flag is present.
---@param flag string|string[] Flag or flags to check
---@return boolean present
function Data:any_flag(flag)
    return self:Flags():any(flag)
end

--)) Flags ((--

--- Runs a function if this wrapper is valid.
--- This wrapper and any additional parameters are passed to the function.
---@param func fun(self: self, ...: any): any Function to run
---@param ... any Additional function arguments
---@return self
function Data:run_function(func, ...)
    if self:is_valid() then
        func(self, ...)
    end
    return self
end
Data.execute = Data.run_function

--- Runs a function on a valid wrapper and returns its results.
---@param func fun(self: self, ...: any): any Function to run
---@param ... any Additional function arguments
---@return boolean valid Whether the wrapper was valid
---@return any results Values returned by `func`
function Data:get_function_results(func, ...)
    if self:is_valid() then
        return true, func(self, ...)
	else
		return false, nil
    end
end

--- Applies the unique-array metatable to a table when this wrapper is valid.
---@param tab? table table to update
---@return self
function Data:set_unique_array(tab)
    if self:is_valid() and tab then
        self.Unique_Array(tab)
    end
    return self
end

--- Adds or changes a field.
---@param field string Field to change
---@param value any Value to assign
---@return self
function Data:set_field(field, value)
    self[field] = value
    return self
end
Data.set = Data.set_field

--- Sets fields from a dictionary, overwriting existing values.
---@param tab table<string, any> Fields to set
---@return self
function Data:set_fields(tab)
    if self:is_valid() then
        for field, value in pairs(tab) do
            self[field] = value
        end
    end
    return self
end

--- Gets a field from this wrapper.
---@param field string Field to retrieve
---@param default_value? any Value returned when the field is `nil`
---@return any value
function Data:get_field(field, default_value)
    if not self:is_valid() then return nil end
	local v = self[field]
	return v ~= nil and v or default_value
end

--- Gets multiple fields as separate return values or as a dictionary.
---@param arr string[] Field names
---@param as_dictionary? boolean Return a dictionary instead of separate values
---@return any values Field values, or a dictionary when `as_dictionary` is true
---@usage local icon, name = Data('stone-furnace', 'furnace'):get_fields({'icon', 'name'})
function Data:get_fields(arr, as_dictionary)
    if self:is_valid() then
        local values = {}
        for _, name in pairs(arr) do
            values[as_dictionary and name or #values + 1] = self[name]
        end
        return as_dictionary and values or table.unpack(values)
    end
end

--- Removes an individual field from this wrapper.
---@param field string Field to remove
---@return self
function Data:remove_field(field)
    if self:is_valid() then
        self[field] = nil
    end
    return self
end

--- Removes an array of fields from this wrapper.
---@param arr string[] Fields to remove
---@return self
function Data:remove_fields(arr)
    if self:is_valid() then
        for _, field in pairs(arr) do
            self[field] = nil
        end
    end
    return self
end

--- Copies fields from another prototype of the same type.
--- A dictionary can provide replacement values instead of copying those fields.
---@param copy_name string Name of the prototype to copy from
---@param fields string[]|table<string, any> Fields to copy or replacement values
---@return self
function Data:copy_fields(copy_name, fields)
	assert(type(copy_name) == "string", "Expected string for name of data object to copy from")
	assert(type(fields) == "table", "Expected table for fields")
	local data_object = Data(copy_name,self.type)
    if self:is_valid() and data_object:is_valid() then
		fields = table.array_to_dictionary(fields)
		for field_name, field_data in pairs(fields) do
			-- if table was not converted via array_to_dictionary, copy fields from data_object
			if field_name ~= field_data then
				self[field_name] = field_data
			else
				self[field_name] = table.deepcopy(data_object[field_name])
			end
		end
	end
    return self
end

--- Copies all existing fields from another prototype of the same type.
--- The `name` and `type` fields are always excluded.
--- An optional array can specify additional fields not to copy.
---@param copy_name string Name of the prototype to copy from
---@param exceptions? string[] Fields not to copy
---@return self
function Data:copy_all_fields(copy_name, exceptions)
	assert(type(copy_name) == "string", "Expected string for name of data object to copy from")
	assert(exceptions == nil or type(exceptions) == "table", "Expected nil or table for exceptions")

	local data_object = Data(copy_name, self.type)

	if self:is_valid() and data_object:is_valid() then
		-- standardize exceptions as a dictionary for direct field lookups
		exceptions = table.array_to_dictionary(table.deepcopy(exceptions or {}))
		exceptions.name = true
		exceptions.type = true

		for field_name, field_data in pairs(data.raw[self.type][copy_name]) do
			if not exceptions[field_name] then
				self[field_name] = table.deepcopy(field_data)
			end
		end
	end

	return self
end

--- Changes the item subgroup and/or order.
--- If `subgroup` is invalid, `order` is not changed.
---@param subgroup? string Subgroup to assign when valid
---@param order? string Order string to assign
---@return self
function Data:subgroup_order(subgroup, order)
    if self:is_valid() then
        if subgroup then
			local Subgroup = require('__kry_stdlib__/stdlib/data/item-subgroup')
            if Subgroup(subgroup):is_valid() then
                self.subgroup = subgroup
            else
                order = nil
            end
        end
        if order and #order > 0 then
            self.order = order
        end
    end
    return self
end

--- Changes the item subgroup without affecting order.
---@param subgroup string Valid item-subgroup name
---@return self
function Data:set_subgroup(subgroup)
	assert(type(subgroup) == "string", "subgroup must be a string")
    return self:subgroup_order(subgroup)
end

--- Changes the order string without affecting the subgroup.
---@param order string Order string to assign
---@return self
function Data:set_order(order)
	assert(type(order) == "string", "order must be a string")
    return self:subgroup_order(nil, order)
end

--- Appends a string to the current order string.
--- Does nothing if `self.order` does not exist.
---@param order_suffix string String to append to `self.order`
---@return self
function Data:append_order(order_suffix)
    assert(type(order_suffix) == "string", "order_suffix must be a string")

    if self:is_valid() and self.order then
        self.order = self.order .. order_suffix
    end

    return self
end

--- Replaces the prototype icon or layered icons.
--- Removes `icons` when a single icon path is supplied.
---@param icon string|IconData[] Icon path or layered icon definitions
---@param size? integer Icon size in pixels
---@return self
function Data:replace_icon(icon, size)
    if self:is_valid() then
        if type(icon) == 'table' then
            self.icons = icon
            self.icon = nil
        elseif type(icon) == 'string' then
            self.icon = icon
			self.icons = nil
        end
        self.icon_size = size or self.icon_size
    end
    if not self.icon_size then
        error('Icon present but icon size not detected')
    end
    return self
end

--- Gets the layered icon definitions.
---@param copy? boolean Return a deep copy
---@return IconData[]? icons
function Data:get_icons(copy)
    if self:is_valid() then
        return copy and table.deep_copy(self.icons) or self.icons
	else
		return nil
    end
end

--- Gets the single icon path.
---@return string? icon
function Data:get_icon()
    if self:is_valid() then
        return self.icon
    end
end

--- Converts a single icon to layered icons and appends additional layers.
---@param ... IconData Icon layers to append
---@return self
function Data:make_icons(...)
    if self:is_valid() then
        if not self.icons then
            if self.icon then
                self.icons = { { icon = self.icon, icon_size = self.icon_size } }
                self.icon = nil
            else
                self.icons = {}
            end
        end
        for _, icon in pairs { ... } do
            self.icons[#self.icons + 1] = table.deep_copy(icon)
        end
    end
    return self
end

--- Updates fields on a layered icon at the given index.
---@param index integer Layer index
---@param values table<string, any> Fields to update
---@return self
function Data:set_icon_at(index, values)
    if self:is_valid() then
        if self.icons then
            for k, v in pairs(values or {}) do
                self.icons[index][k] = v
            end
        end
    end
    return self
end

--- Gets a printable `type/name` identifier for this wrapper.
---@return string identifier
function Data:tostring()
    return self.valid and (self.name and self.type) and (self.type .. '/' .. self.name) or rawtostring(self)
end

--- Iterates wrapped prototypes from a `data.raw` type or prototype dictionary.
---@param source? string|table Prototype type or dictionary; defaults to this wrapper's type
---@param opts? table<string, boolean> Options for yielded wrappers
---@return fun(): any, self? iterator
---@return nil initial_key
---@return nil initial_value
function Data:pairs(source, opts)
    local index, val
    if not source and self.type then
        source = data.raw[self.type]
    else
        local source_type = type(source)
        if source_type == 'string' then
            source = assert(data.raw[source], 'Source missing')
        else
            assert(source_type == 'table', 'Source missing')
        end
    end

    local function _next()
        index, val = next(source, index)
        if index then
            return index, self(val, nil, opts)
        end
    end

    return _next, index, val
end

--- Wraps a prototype table or looks up and wraps a prototype by name.
---@param object string|table Prototype name or prototype table
---@param object_type? string `data.raw` type; required for names except item wrappers
---@param opts? table<string, boolean> Wrapper options
---@return self wrapped
function Data:get(object, object_type, opts)
    --assert(type(object) == 'string' or type(object) == 'table', 'object string or table is required')

    -- Create our middle man container object
    local new = {
        class = self.class or self,
        _raw = nil,
        _products = nil,
        _parent = nil,
		_requested_object = object,	-- these are used to help pin down data:krycopy errors
		_requested_type = object_type,
        valid = false,
        extended = false,
        overwrite = false,
        options = table.merge(table.deep_copy(Data._default_options), opts or self.options or {})
    }

    if type(object) == 'table' then
        assert(object.type and object.name, 'name and type are required')

        new._raw = object
        new.valid = object.type
        --Is a data-raw that we are overwriting
        local existing = data.raw[object.type] and data.raw[object.type][object.name]
        new.extended = existing == object
        new.overwrite = not new.extended and existing and true or false
    elseif type(object) == 'string' then
        --Get type from object_type, or fluid or item_and_fluid_types
        local types = (object_type and { object_type }) or (self.__class == 'Item' and groups.item_and_fluid)
        if types then
            for _, type in pairs(types) do
                new._raw = data.raw[type] and data.raw[type][object]
                if new._raw then
                    new.valid = new._raw.type
                    new.extended = true
                    break
                end
            end
        else
            error('object_type is missing for ' .. (self.__class or 'Unknown') .. '/' .. (object or ''), 3)
        end
    end

    setmetatable(new, self._object_mt)
    if new.valid then
        rawset(new, '_parent', new)
        self.Unique_Array.set(new.flags)
        self.Unique_Array.set(new.crafting_categories)
        self.Unique_Array.set(new.mining_categories)
        self.Unique_Array.set(new.inputs)
    elseif not new.options.silent then	-- no more logs
        --log_trace(new, object, object_type)
    end
    return new:extend()
end
Data.__call = Data.get
--)) END Methods ((--

-- This is the table set on new objects
Data._object_mt = {
    --__class = "Data",
    -- index from _raw if that is not available then retrieve from the class
    __index = function(t, k)
        return rawget(t, '_raw') and t._raw[k] or t.class[k]
    end,
    -- Only allow setting on valid _raw tables.
    __newindex = function(t, k, v)
        if rawget(t, 'valid') and rawget(t, '_raw') then
            t._raw[k] = v
        end
    end,
    -- Call the getter on itself
    __call = function(t, ...)
        return t:__call(...)
    end,
    -- use Core.tostring
    __tostring = Data.tostring
}

return Data
