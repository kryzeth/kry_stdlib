--- Internal scheduler used by stdlib/scripts/spread-on-tick.lua
--- stdlib owns the shared on_tick budget and batches checks by registered group
--- source mods own entity detection, payload data, and callback behavior
--- modders should use the Spread wrapper instead of calling the remote interface directly

local Event = require("__kry_stdlib__/stdlib/event/event")

local Spread = {
	__class = "Spread",
	__index = require("__kry_stdlib__/stdlib/core")
}
setmetatable(Spread, Spread)

local INTERFACE_NAME = "kry-stdlib-spread-on-tick"
local DEFAULT_MAX_CHECKS_PER_TICK = 50

--------------------------------------------------------------------------------
-- Runtime setting cache
--------------------------------------------------------------------------------

local max_checks_per_tick =
	settings.global["kry-stdlib-max-entity-checks"]
	and settings.global["kry-stdlib-max-entity-checks"].value
	or DEFAULT_MAX_CHECKS_PER_TICK

local function update_max_checks(event)
	if event.setting ~= "kry-stdlib-max-entity-checks" then return end

	max_checks_per_tick =
		settings.global["kry-stdlib-max-entity-checks"]
		and settings.global["kry-stdlib-max-entity-checks"].value
		or DEFAULT_MAX_CHECKS_PER_TICK
end

--------------------------------------------------------------------------------
-- Storage
--------------------------------------------------------------------------------

local data

local function setup_storage()
	storage.kry_stdlib_spread = storage.kry_stdlib_spread or {}

	data = storage.kry_stdlib_spread

	data.groups = data.groups or {}
	data.group_order = data.group_order or {}
	data.group_cursor = data.group_cursor or 1
	data.entity_count = data.entity_count or 0
	data.delayed_count = data.delayed_count or 0
end

local function restore_storage()
	data = storage.kry_stdlib_spread
end

local function get_data()
	if data then return data end

	-- Reconnect the local reference without modifying storage.
	data = storage.kry_stdlib_spread
	if data then return data end

	-- Handles a brand-new save where another mod registers before
	-- stdlib's own on_init callback has initialized storage.
	setup_storage()
	return data
end

--------------------------------------------------------------------------------
-- Conditional tick registration
--------------------------------------------------------------------------------

local on_tick
local tick_registered = false
local tick_disable_pending = false

local function has_pending_work()
	return data
		and ((data.entity_count or 0) > 0
			or (data.delayed_count or 0) > 0)
end

local function enable_tick()
	if not has_pending_work() then return end

	tick_disable_pending = false

	if tick_registered then return end

	Event.on_event(defines.events.on_tick, on_tick, nil, nil, { skip_valid = true })

	tick_registered = true
end

local function disable_tick_if_idle()
	if has_pending_work() then
		tick_disable_pending = false
		return
	end

	if tick_registered then
		tick_disable_pending = true
	end
end

local function process_pending_tick_disable()
	if not tick_disable_pending then return end

	tick_disable_pending = false

	if not tick_registered or has_pending_work() then return end

	Event.remove(defines.events.on_tick, on_tick)
	tick_registered = false
end

local function get_group(group_name)
	return get_data().groups[group_name]
end

local function count_entries(tbl)
	local count = 0

	for _ in pairs(tbl or {}) do
		count = count + 1
	end

	return count
end

local function rebuild_entity_counts()
	local data = get_data()
	local entity_count = 0
	local delayed_count = 0

	for _, group in pairs(data.groups) do
		group.entities = group.entities or {}
		group.delayed_entities = group.delayed_entities or {}
		group.interval_ticks = math.max(1, math.floor(tonumber(group.interval_ticks) or 1))

		-- Begin a fresh cycle after configuration changes.
		group.cycle_active = false
		group.next_cycle_tick = nil

		-- Remove obsolete state from the old per-entry interval system.
		group.next_due_tick = nil
		group.next_due_dirty = nil

		for unit_number, entry in pairs(group.entities) do
			-- Legacy Spread storage stored LuaEntity directly.
			if type(entry) == "userdata" then
				group.entities[unit_number] = {
					entity = entry,
					payload = nil
				}
			else
				entry.next_check_tick = nil
			end
		end
		
		entity_count = entity_count + count_entries(group.entities)
		delayed_count = delayed_count + count_entries(group.delayed_entities)
	end

	data.entity_count = entity_count
	data.delayed_count = delayed_count
end

local function get_group_interval(group)
	return group.interval_ticks or 1
end

-- A timed group remains eligible while it is partway through a cycle
-- Once the cycle ends, it waits until next_cycle_tick
local function group_is_due(group, tick)
	if get_group_interval(group) <= 1 then
		return true
	end

	if group.cycle_active then
		return true
	end

	return group.next_cycle_tick == nil
		or group.next_cycle_tick <= tick
end

local function begin_group_cycle(group, tick)
	if get_group_interval(group) <= 1 or group.cycle_active then
		return
	end

	group.cycle_active = true
	group.next_cycle_tick = tick + get_group_interval(group)
end

local function finish_group_cycle(group)
	if get_group_interval(group) > 1 then
		group.cycle_active = false
	end
end

-- New/newly released entities should not remain trapped behind an existing cooldown
local function wake_group(group, tick)
	if get_group_interval(group) > 1 and not group.cycle_active then
		group.next_cycle_tick = tick
	end
end

local function get_next_work_tick(tick)
	local next_work_tick

	for _, group in pairs(data.groups) do
		if group.enabled then
			if next(group.entities) then
				local interval_ticks = get_group_interval(group)

				if interval_ticks <= 1 or group.cycle_active then
					return tick
				end

				local cycle_tick = group.next_cycle_tick

				if cycle_tick == nil or cycle_tick <= tick then
					return tick
				end

				if not next_work_tick or cycle_tick < next_work_tick then
					next_work_tick = cycle_tick
				end
			end

			-- Delayed entries can wake the scheduler before the next group cycle begins
			for _, delayed in pairs(group.delayed_entities) do
				if delayed.tick <= tick then
					return tick
				end

				if not next_work_tick or delayed.tick < next_work_tick then
					next_work_tick = delayed.tick
				end
			end
		end
	end

	return next_work_tick
end

--------------------------------------------------------------------------------
-- Group order
--------------------------------------------------------------------------------

local function group_exists_in_order(data, group_name)
	for _, name in ipairs(data.group_order) do
		if name == group_name then
			return true
		end
	end

	return false
end

local function add_group_to_order(data, group_name)
	if group_exists_in_order(data, group_name) then return end
	data.group_order[#data.group_order + 1] = group_name
end

local function remove_group_from_order(data, group_name)
	for index = #data.group_order, 1, -1 do
		if data.group_order[index] == group_name then
			table.remove(data.group_order, index)
		end
	end

	if data.group_cursor > #data.group_order then
		data.group_cursor = 1
	end
end

--------------------------------------------------------------------------------
-- Summary
--------------------------------------------------------------------------------

local function get_summary()
	local data = get_data()
	local summary = {
		groups = {},
		group_order = data.group_order,
		group_cursor = data.group_cursor,
		entity_count = data.entity_count,
		delayed_count = data.delayed_count
	}

	for group_name, group in pairs(data.groups) do
		summary.groups[group_name] = {
			interface = group.interface,
			callback = group.callback,
			remove_callback = group.remove_callback,
			enabled = group.enabled,
			interval_ticks = group.interval_ticks,
			max_checks_per_tick = group.max_checks_per_tick,
			next_due_tick = group.next_due_tick,
			next_due_dirty = group.next_due_dirty,
			count = count_entries(group.entities),
			delayed_count = count_entries(group.delayed_entities),
			previous_key = group.previous_key,
			pending_key = group.pending_key
		}
	end

	return summary
end

local function get_group_summary(group_name)
	local group = get_group(group_name)

	if not group then return { exists = false } end

	return {
		exists = true,
		interface = group.interface,
		callback = group.callback,
		remove_callback = group.remove_callback,
		enabled = group.enabled,
		interval_ticks = group.interval_ticks,
		max_checks_per_tick = group.max_checks_per_tick,
		next_due_tick = group.next_due_tick,
		next_due_dirty = group.next_due_dirty,
		count = count_entries(group.entities),
		delayed_count = count_entries(group.delayed_entities),
		previous_key = group.previous_key,
		pending_key = group.pending_key
	}
end

--------------------------------------------------------------------------------
-- Remote API
--------------------------------------------------------------------------------

local function register_group(definition)
	if type(definition) ~= "table" then
		error("register_group expects a table")
	end

	local group_name = definition.name
	local interface_name = definition.interface
	local callback = definition.callback
	local remove_callback = definition.remove_callback
	local interval_ticks = math.max(1, math.floor(tonumber(definition.interval_ticks) or 1))
	local group_max_checks_per_tick = definition.max_checks_per_tick

	if group_max_checks_per_tick ~= nil then
		group_max_checks_per_tick =
			tonumber(group_max_checks_per_tick)

		if not group_max_checks_per_tick
			or group_max_checks_per_tick < 1 then

			error(
				"register_group definition.max_checks_per_tick "
				.. "must be a positive number or nil"
			)
		end

		group_max_checks_per_tick =
			math.floor(group_max_checks_per_tick)
	end

	if type(group_name) ~= "string" then
		error("register_group requires definition.name as string")
	end

	if type(interface_name) ~= "string" then
		error("register_group requires definition.interface as string")
	end

	if type(callback) ~= "string" then
		error("register_group requires definition.callback as string")
	end

	local data = get_data()
	local group = data.groups[group_name] or {
		entities = {},
		delayed_entities = {},
		previous_key = nil,
		pending_key = nil,
		enabled = true,
		cycle_active = false,
		next_cycle_tick = nil
	}

	group.entities = group.entities or {}
	group.delayed_entities = group.delayed_entities or {}

	local previous_interval = group.interval_ticks or 1

	group.interval_ticks = interval_ticks
	group.max_checks_per_tick =	group_max_checks_per_tick
	group.interface = interface_name
	group.callback = callback
	group.remove_callback = remove_callback
	group.enabled = definition.enabled ~= false

	if previous_interval ~= interval_ticks then
		-- Apply the new timing policy immediately
		group.previous_key = nil
		group.pending_key = nil
		group.cycle_active = false
		group.next_cycle_tick = game.tick
	end

	-- Remove obsolete state from the timestamp implementation
	group.next_due_tick = nil
	group.next_due_dirty = nil

	for _, entry in pairs(group.entities) do
		entry.next_check_tick = nil
	end

	data.groups[group_name] = group
	add_group_to_order(data, group_name)
end

local function unregister_group(group_name)
	local data = get_data()
	local group = data.groups[group_name]

	if group then
		data.entity_count = math.max(0, data.entity_count - count_entries(group.entities))
		data.delayed_count = math.max(0, data.delayed_count - count_entries(group.delayed_entities))
	end

	data.groups[group_name] = nil
	remove_group_from_order(data, group_name)
	disable_tick_if_idle()
end

local function clear_group(group_name)
	local group = get_group(group_name)
	if not group then return end

	local data = get_data()
	data.entity_count = math.max(0, data.entity_count - count_entries(group.entities))
	data.delayed_count = math.max(0, data.delayed_count - count_entries(group.delayed_entities))

	group.entities = {}
	group.delayed_entities = {}
	group.previous_key = nil
	group.pending_key = nil
	
	disable_tick_if_idle()
end

local function reset_group(group_name)
	local group = get_group(group_name)
	if not group then return end

	group.previous_key = nil
	group.pending_key = nil
	group.cycle_active = false
	group.next_cycle_tick = nil
end

local function add_entity(group_name, entity, payload, delay_ticks)
	local group = get_group(group_name)

	if not group then
		error(
			"Cannot add entity to unregistered spread group: "
			.. tostring(group_name)
		)
	end

	if not (entity and entity.valid and entity.unit_number) then return end

	local data = get_data()
	local unit_number = entity.unit_number

	delay_ticks = delay_ticks or 0

	-- Remove an existing delayed entry before replacing it.
	if group.delayed_entities[unit_number] then
		group.delayed_entities[unit_number] = nil
		data.delayed_count = math.max(0, data.delayed_count - 1)
	end

	-- Re-adding an active entity updates its reference and payload without
	-- resetting the interval timer.
	if group.entities[unit_number] then
		group.entities[unit_number] = { entity = entity, payload = payload }
		wake_group(group, game.tick)
		return
	end

	if delay_ticks > 0 then
		group.delayed_entities[unit_number] = {
			entity = entity,
			payload = payload,
			tick = game.tick + delay_ticks
		}

		data.delayed_count = data.delayed_count + 1
		enable_tick()
		return
	end

	group.entities[unit_number] = { entity = entity, payload = payload }
	wake_group(group, game.tick)
	data.entity_count = data.entity_count + 1
	enable_tick()
end

local function remove_entity(group_name, unit_number_or_entity)
	local group = get_group(group_name)
	if not group then return end

	local unit_number = unit_number_or_entity

	if type(unit_number_or_entity) == "table" or type(unit_number_or_entity) == "userdata" then
		unit_number = unit_number_or_entity.unit_number
	end

	if not unit_number then return end

	local data = get_data()

	if group.entities[unit_number] then
		group.entities[unit_number] = nil
		data.entity_count = math.max(0, data.entity_count - 1)
	end

	if group.delayed_entities[unit_number] then
		group.delayed_entities[unit_number] = nil
		data.delayed_count = math.max(0, data.delayed_count - 1)
	end

	if group.previous_key == unit_number then
		group.previous_key = nil
	end

	if group.pending_key == unit_number then
		group.pending_key = nil
	end
	
	disable_tick_if_idle()
end

local function set_group_enabled(group_name, enabled)
	local group = get_group(group_name)
	if not group then return end

	group.enabled = enabled and true or false
end

--------------------------------------------------------------------------------
-- Callback helpers
--------------------------------------------------------------------------------

local function callback_exists(interface_name, callback)
	return remote.interfaces[interface_name] and remote.interfaces[interface_name][callback]
end

local function is_group_callable(group)
	return group and group.interface and group.callback
		and callback_exists(group.interface, group.callback)
end

local function remove_stale_groups()
	local data = get_data()

	for group_name, group in pairs(data.groups) do
		if not is_group_callable(group) then
			data.entity_count = math.max(0, data.entity_count - count_entries(group.entities))
			data.delayed_count = math.max(0, data.delayed_count - count_entries(group.delayed_entities))
			data.groups[group_name] = nil
			remove_group_from_order(data, group_name)
		end
	end
end

local function notify_removed(group_name, group, unit_number, reason)
	if not group.remove_callback then return end
	if not callback_exists(group.interface, group.remove_callback) then return end

	remote.call(group.interface, group.remove_callback, unit_number, group_name, reason)
end

local function call_group_callback(group_name, group, entries, tick)
	if not callback_exists(group.interface, group.callback) then
		group.enabled = false
		return nil
	end

	return remote.call(group.interface, group.callback, entries, tick, group_name)
end

-- A batch callback may return:
-- { [unit_number] = true }
-- Each returned entity is removed from spread tracking
local function apply_callback_removals(group_name, group, removals)
	if type(removals) ~= "table" then return end

	local removed = 0

	for unit_number, should_remove in pairs(removals) do
		if should_remove and group.entities[unit_number] then
			-- Capture where iteration should continue before removing the current cursor key
			if group.previous_key == unit_number then
				group.pending_key = next(group.entities, unit_number)
				group.previous_key = nil
			elseif group.pending_key == unit_number then
				group.pending_key = nil
			end

			group.entities[unit_number] = nil
			removed = removed + 1

			notify_removed(group_name, group, unit_number, "callback")
		end
	end

	if removed > 0 then
		data.entity_count = math.max(0, data.entity_count - removed)
		if not next(group.entities) then
			group.cycle_active = false
			group.next_cycle_tick = nil
		end
	end
end

--------------------------------------------------------------------------------
-- Delayed entities
--------------------------------------------------------------------------------

local function release_delayed_entities(group_name, group, tick)
	if not next(group.delayed_entities) then return end

	local data = get_data()

	for unit_number, delayed in pairs(group.delayed_entities) do
		if delayed.tick <= tick then
			group.delayed_entities[unit_number] = nil
			data.delayed_count = math.max(0, data.delayed_count - 1)
			
			local entity = delayed.entity

			if entity and entity.valid then
				-- Do not double-count if it was registered normally
				-- while still waiting in the delayed table.
				if not group.entities[unit_number] then
					group.entities[unit_number] = {
						entity = entity,
						payload = delayed.payload
					}

					data.entity_count = data.entity_count + 1
				else
					-- Update the existing entry with the latest values.
					group.entities[unit_number] = {
						entity = entity,
						payload = delayed.payload,
						next_check_tick = tick
					}
				end
			else notify_removed(group_name, group, unit_number, "invalid-delayed")
			end
			wake_group(group, tick)
		end
	end
end

--------------------------------------------------------------------------------
-- Iteration
--------------------------------------------------------------------------------

local function take_next_entry(group)
	-- If the previous key was removed externally, restart safely.
	if group.previous_key ~= nil and group.entities[group.previous_key] == nil then
		group.previous_key = nil
	end

	-- Continue from a key captured before an entry was removed.
	if group.pending_key ~= nil then
		local key = group.pending_key
		group.pending_key = nil

		local entry = group.entities[key]

		if entry ~= nil then
			return key, entry
		end
	end

	return next(group.entities, group.previous_key)
end

-- Select one stored entry for this tick's batch.
--
-- Returns:
-- processed:   whether one check was consumed
-- entry:       valid stored entry, or nil
-- reached_end: whether this group reached the end
local function collect_one_entry(group_name, group)
	local unit_number, entry = take_next_entry(group)

	if unit_number == nil then
		group.previous_key = nil
		group.pending_key = nil
		return false, nil, true
	end

	-- Capture the next key before potentially removing this entry.
	local next_key = next(group.entities, unit_number)
	local entity = entry and entry.entity
	if not (entity and entity.valid) then
		group.entities[unit_number] = nil
		data.entity_count = math.max(0, data.entity_count - 1)
		notify_removed(group_name, group, unit_number, "invalid")
		group.previous_key = nil

		if next_key ~= nil then
			group.pending_key = next_key
			return true, nil, false
		end

		group.pending_key = nil
		return true, nil, true
	end

	if next_key == nil then
		group.previous_key = nil
		group.pending_key = nil
		return true, entry, true
	end

	group.previous_key = unit_number
	return true, entry, false
end

--------------------------------------------------------------------------------
-- Tick scheduler
--------------------------------------------------------------------------------

on_tick = function(event)
	-- Nothing active or delayed anywhere.
	if data.entity_count == 0 and data.delayed_count == 0 then
		disable_tick_if_idle()
		return
	end

	local order = data.group_order
	local order_count = #order

	if order_count == 0 then
		disable_tick_if_idle()
		return
	end
	
	-- If every active entry and delayed registration is scheduled for a
	-- future tick, skip batch construction and remote callbacks entirely.
	local next_work_tick = get_next_work_tick(event.tick)

	if not next_work_tick or next_work_tick > event.tick then return end

	-- Delayed entities must be released even when there are no active
	-- entities. This runs once per group, not once per entity check.
	if data.delayed_count > 0 then
		for index = 1, order_count do
			local group_name = order[index]
			local group = data.groups[group_name]

			if group and group.enabled then
				release_delayed_entities(group_name, group, event.tick)
			end
		end
	end

	-- Delayed entities may still be waiting for a later tick.
	if data.entity_count == 0 then
		disable_tick_if_idle()
		return
	end

	local checked = 0
	local exhausted = {}
	local batches = {}
	local due_groups = {}
	local group_checked = {}

	----------------------------------------------------------------------
	-- Build batches using the existing global round-robin budget
	----------------------------------------------------------------------

	while checked < max_checks_per_tick do
		local did_check = false
		local searched_groups = 0

		while searched_groups < order_count do
			if data.group_cursor > order_count then
				data.group_cursor = 1
			end

			local group_name = order[data.group_cursor]

			data.group_cursor = data.group_cursor + 1
			searched_groups = searched_groups + 1

			local group = data.groups[group_name]

			if group and group.enabled and not exhausted[group_name] then
				local group_count =
					group_checked[group_name] or 0

				local group_limit =
					group.max_checks_per_tick

				-- This group has consumed its private budget for this tick.
				-- Do not end its active cycle; resume it next tick.
				if group_limit and group_count >= group_limit then
					exhausted[group_name] = true
				else
					local due = due_groups[group_name]
					if due == nil then
						due = group_is_due(group, event.tick)
						due_groups[group_name] = due
					end
					if not due then
						exhausted[group_name] = true
					elseif not next(group.entities) then
						group.previous_key = nil
						group.pending_key = nil
						finish_group_cycle(group)
						exhausted[group_name] = true
					else
						begin_group_cycle(group, event.tick)
						local processed, entry, reached_end = collect_one_entry(group_name, group)

						if reached_end then
							finish_group_cycle(group)
							exhausted[group_name] = true
						end

						if processed then
							checked = checked + 1
							group_count = group_count + 1
							group_checked[group_name] = group_count
							did_check = true
							-- Stop selecting this group during the current
							-- tick once its private limit is reached.
							-- Its cursor and cycle remain intact.
							if group_limit and group_count >= group_limit then
								exhausted[group_name] = true
							end

							if entry then
								local batch = batches[group_name]
								if not batch then
									batch = {}
									batches[group_name] = batch
								end
								batch[#batch + 1] = entry
							end

							break
						end
					end
				end
			end
		end
		if not did_check then break end
	end

	----------------------------------------------------------------------
	-- Call each participating mod once
	----------------------------------------------------------------------

	for index = 1, order_count do
		local group_name = order[index]
		local entries = batches[group_name]

		if entries and #entries > 0 then
			local group = data.groups[group_name]

			if group and group.enabled then
				local removals = call_group_callback(group_name, group, entries, event.tick)

				apply_callback_removals(group_name, group, removals)
			end
		end
	end

	disable_tick_if_idle()
end

--------------------------------------------------------------------------------
-- Event and remote registration
--------------------------------------------------------------------------------

Event.on_init(function()
	setup_storage()
	rebuild_entity_counts()
	enable_tick()
end)

Event.on_load(function()
	restore_storage()
	enable_tick()
end)

Event.on_configuration_changed(function()
	setup_storage()
	remove_stale_groups()
	rebuild_entity_counts()
	enable_tick()
	disable_tick_if_idle()
end)

Event.on_event(
	defines.events.on_runtime_mod_setting_changed,
	update_max_checks
)

Event.on_nth_tick(60, process_pending_tick_disable)

remote.add_interface(INTERFACE_NAME, {
	register_group = register_group,
	unregister_group = unregister_group,
	clear_group = clear_group,
	reset_group = reset_group,
	add_entity = add_entity,
	remove_entity = remove_entity,
	set_group_enabled = set_group_enabled,
	get_summary = get_summary,
	get_group_summary = get_group_summary
})

return Spread