--------------------------------------------------------------------------------
-- Things API wrapper
--------------------------------------------------------------------------------

local Things = {
	__class = "Things",
	__index = require("__kry_stdlib__/stdlib/core")
}
setmetatable(Things, Things)

--------------------------------------------------------------------------------
-- Remote call helper
--------------------------------------------------------------------------------

---@param function_name string
---@return any result
---@return things.Error? error
local function call(function_name, ...)
	-- if the things api does not exist, warn the user
	if not remote.interfaces["things"] then
		error("\nMissing required remote interface." ..
			"\nPlease ensure the Things API mod is required before using this module.")
	end

	local err, result = remote.call("things", function_name, ...)

	if err then
		game.print("Things API call failed: " .. function_name .. "\n" .. serpent.line(err))
	end

	return result, err
end

--------------------------------------------------------------------------------
-- Basic API wrappers
--------------------------------------------------------------------------------

--- Returns the full summary of a Thing
---@param thing things.ThingIdentification
---@return things.ThingSummary?
function Things.get(thing)
	local result = call("get", thing)
	return result
end

--- Returns the Thing ID associated with a valid entity
---@param entity LuaEntity
---@return things.Id?
function Things.get_thing_id(entity)
	if not (entity and entity.valid) then return nil end
	local result = call("get_thing_id", entity)
	return result
end

--- Creates a Thing from the supplied API parameters
---@param params things.CreateThingParams
---@return things.ThingSummary?
function Things.create_thing(params)
	local result = call("create_thing", params)
	return result
end

--- Destroys a Thing and optionally leaves its entity in the world
---@param thing things.ThingIdentification
---@param keep_entity? boolean
---@return boolean success True when the Things API reports no error
function Things.force_destroy(thing, keep_entity)
	local _, err = call("force_destroy", thing, keep_entity)
	return err == nil
end

--- Removes a Thing from its current parent without destroying it
---@param child things.ThingIdentification
---@return boolean success True when the Things API reports no error
function Things.remove_parent(child)
	local _, err = call("remove_parent", child)
	return err == nil
end

--- Adds an existing child Thing to a parent under the string form of the
--- supplied child index
---@param parent things.ThingIdentification
---@param child_index string|integer
---@param child things.ThingIdentification
---@return boolean success True when the Things API reports no error
function Things.add_child(parent, child_index, child)
	local _, err = call(
		"add_child",
		parent,
		tostring(child_index),
		child
	)

	return err == nil
end

--------------------------------------------------------------------------------
-- Child lookup helpers
--------------------------------------------------------------------------------

--- Returns all children registered under a parent Thing
---@param parent things.ThingIdentification
---@return things.ThingChildrenSummary?
function Things.get_children(parent)
	local result = call("get_children", parent)
	return result
end

--- Returns the child summary stored under the string form of a child index
---@param parent things.ThingIdentification
---@param child_index string|integer
---@return things.ThingSummary?
function Things.get_child_info(parent, child_index)
	local children = Things.get_children(parent)
	if not children then return nil end

	return children[tostring(child_index)]
end

--- Returns the valid child entity stored under a specific child index
---@param parent things.ThingIdentification
---@param child_index string|integer
---@return LuaEntity?
function Things.get_child_entity(parent, child_index)
	local child = Things.get_child_info(parent, child_index)
	local entity = child and child.entity

	if entity and entity.valid then
		return entity
	end

	return nil
end

--- Finds the first valid child matching an optional predicate
---@param parent things.ThingIdentification
---@param predicate? fun(entity: LuaEntity, child: things.ThingSummary): boolean
---@return things.ThingSummary?
local function find_child_info(parent, predicate)
	local children = Things.get_children(parent)
	if not children then return nil end

	for _, child in pairs(children) do
		local entity = child.entity

		if entity
			and entity.valid
			and (not predicate or predicate(entity, child))
		then
			return child
		end
	end

	return nil
end

--- Returns the first valid child entity
---@param parent things.ThingIdentification
---@return LuaEntity?
function Things.get_first_child(parent)
	local child = find_child_info(parent)
	return child and child.entity
end

--- Returns the first valid child entity with the supplied entity type
---@param parent things.ThingIdentification
---@param entity_type string
---@return LuaEntity?
function Things.get_child_by_type(parent, entity_type)
	local child = find_child_info(parent, function(entity)
		return entity.type == entity_type
	end)

	return child and child.entity
end

--- Returns the first valid child entity with the supplied entity name
---@param parent things.ThingIdentification
---@param entity_name string
---@return LuaEntity?
function Things.get_child_by_name(parent, entity_name)
	local child = find_child_info(parent, function(entity)
		return entity.name == entity_name
	end)

	return child and child.entity
end

--------------------------------------------------------------------------------
-- Thing creation and child repair
--------------------------------------------------------------------------------

--- Returns the existing Thing summary or creates one for the supplied entity
---@param entity LuaEntity
---@param thing_name? string Name used only when a new Thing must be created
---@return things.ThingSummary?
function Things.ensure_thing(entity, thing_name)
	if not (entity and entity.valid) then return nil end

	local thing = Things.get(entity)
	if thing then return thing end

	return Things.create_thing{
		entity = entity,
		name = thing_name or entity.name
	}
end

--- Ensures that an entity is registered as a Thing child at the supplied index
--- Existing void children are filled, incorrect child Things are replaced, and
--- existing Thing entities are moved from their previous parent when required
---@param parent LuaEntity
---@param child_index string|integer
---@param child LuaEntity
---@param relative_pos? MapPosition Position relative to the parent stored by Things
---@return things.ThingSummary? child_info
function Things.ensure_thing_child(parent, child_index, child, relative_pos)
	if not (parent and parent.valid) then return nil end
	if not (child and child.valid) then return nil end

	local parent_thing = Things.ensure_thing(parent)
	if not parent_thing then return nil end

	local key = tostring(child_index)
	local current = Things.get_child_info(parent, key)

	-- Already correctly registered.
	if current and current.entity == child then
		return current
	end

	local child_thing = Things.get(child)

	-- Fill an existing void automatic child.
	if current and current.status == "void" then
		if child_thing then
			if not Things.force_destroy(child_thing.id, true) then
				return nil
			end
		end

		local created = Things.create_thing{
			entity = child,
			name = child.name,
			devoid = current.id
		}

		if not created then return nil end
		return Things.get_child_info(parent, key)
	end

	-- Remove an incorrect Thing occupying the required child index.
	if current then
		if not Things.force_destroy(current.id) then
			return nil
		end
	end

	child_thing = Things.get(child)

	if child_thing then
		local parent_info = child_thing.parent

		if parent_info then
			local already_attached =
				parent_info[1] == parent_thing.id
				and parent_info[2] == key

			if already_attached then
				return Things.get_child_info(parent, key)
			end

			if not Things.remove_parent(child_thing.id) then
				return nil
			end
		end

		if not Things.add_child(parent, key, child) then
			return nil
		end
	else
		local created = Things.create_thing{
			entity = child,
			name = child.name,
			parent = parent,
			child_index = key,
			relative_pos = relative_pos
		}

		if not created then return nil end
	end

	return Things.get_child_info(parent, key)
end

--------------------------------------------------------------------------------
-- Parent lookup helpers
--------------------------------------------------------------------------------

--- Returns the valid parent entity of a child Thing
---@param child LuaEntity
---@return LuaEntity?
function Things.get_parent(child)
	if not (child and child.valid) then return nil end

	local child_summary = Things.get(child)
	if not (child_summary and child_summary.parent) then return nil end

	local parent_summary = Things.get(child_summary.parent[1])
	local parent_entity = parent_summary and parent_summary.entity

	if parent_entity and parent_entity.valid then
		return parent_entity
	end

	return nil
end

return Things
