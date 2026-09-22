--- The game module.
---@class StdLib.Game : StdLib.Core
---@usage local Game = require('__kry_stdlib__/stdlib/game')
local Game = {
    __class = 'Game',
    __index = require('__kry_stdlib__/stdlib/core') --[[@as StdLib.Core]]
}
setmetatable(Game, Game)
local inspect = _ENV.inspect

--- Returns a valid player from a player identification or event containing `player_index`.
---@param mixed PlayerIdentification|table
---@return LuaPlayer? player
function Game.get_player(mixed)
	local type = type(mixed)
    if type == 'table' or type == 'userdata' then
		if mixed["object_name"] and mixed["object_name"]=="LuaPlayer" then
			return mixed.valid and mixed --[[@as LuaPlayer]]
        elseif mixed.player_index then
            return game.get_player(mixed.player_index)
        end
    elseif mixed then
        return game.get_player(mixed--[[@as string|number]])
    end
end

--- Returns a valid force from a force name, LuaForce, or object/event containing `force`.
---@param mixed string|LuaForce|table
---@return LuaForce? force
function Game.get_force(mixed)
	local mixed_type = type(mixed)
    if mixed_type == 'table' or mixed_type == 'userdata' then
        if mixed["object_name"] and mixed["object_name"]=="LuaForce" then
            return mixed and mixed.valid and mixed --[[@as LuaForce]]
        elseif mixed.force then
            return Game.get_force(mixed.force)
        end
    elseif mixed_type == 'string' then
        local force = game.forces[mixed]
        return (force and force.valid) and force --[[@as LuaForce|nil]]
    end
end

--- Returns a valid surface from a surface identification or object/event containing `surface`.
---@param mixed SurfaceIdentification|table
---@return LuaSurface? surface
function Game.get_surface(mixed)
    local type = type(mixed)
    if type == 'table' or type == 'userdata' then
		if mixed["object_name"] and mixed["object_name"]=="LuaSurface" then
            return mixed.valid and mixed --[[@as LuaSurface]]
        elseif mixed.surface then
            return Game.get_surface(mixed.surface)
        end
    elseif mixed then
        local surface = game.surfaces[mixed]
        return surface and surface.valid and surface or nil
    end
end

--- Messages all players currently connected to the game.
--- Offline players are not counted as having received the message.
--- If no players exist, the message is stored in `storage._print_queue`.
---@param msg string The message to send.
---@param condition? fun(player: LuaPlayer): boolean Optional condition a player must satisfy.
---@return uint count Number of players who received the message.
function Game.print_all(msg, condition)
    local num = 0
    if #game.players > 0 then
        for _, player in pairs(game.players) do
            if condition == nil or select(2, pcall(condition, player)) then
                player.print(msg)
                num = num + 1
            end
        end
        return num
    else
        storage._print_queue = storage._print_queue or {}
        storage._print_queue[#storage._print_queue + 1] = msg
		return 0
    end
end

--- Gets or sets data in the storage variable.
---@param sub_table string The name of the table used to store the data.
---@param index? any Optional nested index.
---@param key any The key used to store the data.
---@param set? boolean When true, sets `value` and returns the previously stored value.
---@param value? any Value to store.
---@return any value The stored value or previous value.
function Game.get_or_set_data(sub_table, index, key, set, value)
    assert(type(sub_table) == 'string', 'sub_table must be a string')
    storage[sub_table] = storage[sub_table] or {}
    local this
    if index then
        storage[sub_table][index] = storage[sub_table][index] or {}
        this = storage[sub_table][index]
    else
        this = storage[sub_table]
    end
    local previous

    if set then
        previous = this[key]
        this[key] = value
        return previous
    elseif not this[key] and value then
        this[key] = value
        return this[key]
    end
    return this[key]
end

--- Writes the currently active mods to `Mods.lua`.
function Game.write_mods()
    helpers.write_file('Mods.lua', 'return ' .. inspect(script.active_mods))
end

--- Writes pollution and production statistics for all surfaces and forces.
function Game.write_statistics()
    local pre = 'Statistics/' .. game.tick .. '/'
    for _, surface in pairs(game.surfaces) do
        local pollution = game.get_pollution_statistics(surface)
        for _, count_type in pairs {'input_counts', 'output_counts'} do
            helpers.write_file(
                pre .. surface.name .. '/pollution-' .. count_type .. '.json',
                helpers.table_to_json(pollution[count_type])
            )
        end

        for _, force in pairs(game.forces) do
            local folder = pre .. surface.name .. '/' .. force.name .. '/'
            local statistics = {
                item = force.get_item_production_statistics(surface),
                fluid = force.get_fluid_production_statistics(surface),
                kill = force.get_kill_count_statistics(surface),
                build = force.get_entity_build_count_statistics(surface)
            }
            for name, flow in pairs(statistics) do
                for _, count_type in pairs {'input_counts', 'output_counts'} do
                    helpers.write_file(
                        folder .. name .. '-' .. count_type .. '.json',
                        helpers.table_to_json(flow[count_type])
                    )
                end
            end
        end
    end
end

--- Writes the map generation settings for every surface.
function Game.write_surfaces()
    helpers.remove_path('surfaces')
    for _, surface in pairs(game.surfaces) do
        helpers.write_file('surfaces/' .. (surface.name or surface.index) .. '.lua', 'return ' .. inspect(surface.map_gen_settings))
    end
end

return Game
