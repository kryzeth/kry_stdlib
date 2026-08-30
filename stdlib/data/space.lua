local Data = require('__kry_stdlib__/stdlib/data/data')
local Table = require('__kry_stdlib__/stdlib/utils/table') --[[@as StdLib.Utils.Table]]

--- Field added by PlanetsLib that is generally used for moon orbits
---@class StdLib.Data.Orbit
---@field parent {type:string, name:string}
---@field distance number
---@field orientation number
--- Wrapper for planet, space-connection, and space-location prototypes. 
---@class StdLib.Data.Space : StdLib.Data
---@field asteroid_spawn_definitions? table[]
---@field distance? number
---@field orientation? number
---@field orbit? StdLib.Data.Orbit
local Space = {
    __class = 'Space',
    __index = Data,
    __call = Data.__call
}
setmetatable(Space, Space)

-- ----------------------------
-- Internal helpers
-- ----------------------------
--- Ensures this function is only used on planet or space location.
---@param object StdLib.Data.Space
---@param method string
local function assert_planet_location(object, method)
	assert(
		mods["PlanetsLib"],
		method .. "() requires PlanetsLib. Please add a requirement to this mod before using this function"
	)
	assert(
		PlanetsLib and PlanetsLib.current_stage ~= "data-final-fixes",
		method .. "() cannot be used during data-final-fixes"
	)
	assert(
		object:is_valid("planet") or object:is_valid("space-location"),
		method .. "() can only be used on planet or space-location prototypes"
	)
end

--- Returns whether this location has a relative orbit around another location.
---@param object StdLib.Data.Space
---@return boolean
local function has_parent_orbit(object)
	local parent = object.orbit and object.orbit.parent

	return parent
		and not (parent.type == "space-location" and parent.name == "star")
		or false
end

--- Returns the effective distance field for a location.
---@param object StdLib.Data.Space
---@return number
local function get_distance(object)
	if has_parent_orbit(object) then
		return object.orbit.distance
	end

	return object.distance
end

--- Returns the effective orientation field for a location.
---@param object StdLib.Data.Space
---@return number
local function get_orientation(object)
	if has_parent_orbit(object) then
		return object.orbit.orientation
	end

	return object.orientation
end

--- Shorthand to update planet or location orbit via PlanetsLib.
---@param object StdLib.Data.Space
---@param orbit StdLib.Data.Orbit
---@return self
local function update_orbit(object, orbit)
	PlanetsLib:update({
		type = object.type,
		name = object.name,
		orbit = orbit,
	})

	return object
end

--- Removes the first matching asteroid spawn definition.
---@param asteroid_spawn_definitions table[] Asteroid spawn definitions
---@param name string Asteroid prototype name
---@return boolean? removed
local function remove_asteroid(asteroid_spawn_definitions,name) -- expected table, string
	for key, asteroid in pairs(asteroid_spawn_definitions) do
        if asteroid.asteroid == name then
            table.remove(asteroid_spawn_definitions, key)
            return true
        end
	end
end

--- Generates spawn-point values at the supplied distances.
---@param origin table Origin asteroid spawn properties
---@param destination table Destination asteroid spawn properties
---@param distances number[] Normalized connection distances
---@return table[] values
local function generate_values_by_distance(origin,destination,distances)
	local results = {}
	-- define spike multiplier
	local spike_mult = 1.5
	local spike_dist = 0.5
	local start_dist = distances[1]
	local end_dist = distances[#distances]

	for _, dist in ipairs(distances) do
		local entry = {}

		-- Probability
		if dist == start_dist then	 -- origin point uses origin probability
			entry.probability = origin.probability
		elseif dist == end_dist then -- destination point uses destination probability
			entry.probability = destination.probability
		elseif dist == spike_dist then	-- middle spike point uses spiked max probability
			entry.probability = math.max(origin.probability, destination.probability) * spike_mult
		else -- middle points between origin/destination and spike uses average based on distance
			entry.probability = origin.probability + (destination.probability - origin.probability) * dist
		end

		-- Speed: similar logic
		if dist == start_dist then
			entry.speed = origin.speed
		elseif dist == end_dist then
			entry.speed = destination.speed
		else	-- don't need to worry about speed at the spike point
			entry.speed = origin.speed + (destination.speed - origin.speed) * dist
		end

		-- Distance
		entry.distance = dist

		table.insert(results, entry)
	end

	return results
end

--- Generates asteroid spawn points between two endpoints.
---@param origin table Origin asteroid spawn properties
---@param destination table Destination asteroid spawn properties
---@return table[] spawn_points
local function generate_spawn_points(origin,destination)
	local distances = {0.05, 0.35, 0.5, 0.65, 0.95}
	local values = generate_values_by_distance(origin, destination, distances)
	local spawn_points = {
		{	-- linear increase/decrease near origin point
			angle_when_stopped = origin.angle_when_stopped or destination.angle_when_stopped,
			speed = values[1].speed,
			probability = values[1].probability,
			distance = values[1].distance,
		},
		{	-- linear increase/decrease near origin point
			angle_when_stopped = origin.angle_when_stopped or destination.angle_when_stopped,
			speed = values[2].speed,
			probability = values[2].probability,
			distance = values[2].distance,
		},
		{	-- sharp increase in the middle, equivalent to 1.5x the highest probability
			angle_when_stopped = origin.angle_when_stopped or destination.angle_when_stopped,
			speed = values[3].speed,
			probability = values[3].probability,
			distance = values[3].distance,
		},
		{	-- linear increase/decrease near destination point
			angle_when_stopped = destination.angle_when_stopped or origin.angle_when_stopped,
			speed = values[4].speed,
			probability = values[4].probability,
			distance = values[4].distance,
		},
		{	-- linear increase/decrease near destination point
			angle_when_stopped = destination.angle_when_stopped or origin.angle_when_stopped,
			speed = values[5].speed,
			probability = values[5].probability,
			distance = values[5].distance,
		},
	}
	return spawn_points
end

--- Merges origin and destination asteroid definitions into one connection entry.
---@param origin? table Origin asteroid definition
---@param destination? table Destination asteroid definition
---@return table asteroid_definition
local function merge_asteroid_definitions(origin, destination)
	local asteroid_name, asteroid_type
	local asteroid_spawn_points = {}
	-- destination does not contain this asteroid, use only origin properties
	if not destination then
		---@cast origin table
		asteroid_name = origin.asteroid
		asteroid_type = origin.type
		-- starts at origin probability near origin, ends at 0 probability near destination
		-- retain all other properties same as origin, slow linear decrease
		asteroid_spawn_points = {
			{
				angle_when_stopped = origin.angle_when_stopped,
				speed = origin.speed,
				probability = origin.probability,
				distance = 0.05,
			},	
			{
				angle_when_stopped = origin.angle_when_stopped,
				speed = origin.speed,
				probability = 0,
				distance = 0.95,
			},
		}
	-- origin does not contain this asteroid, use only properties of destination
	elseif not origin then
		asteroid_name = destination.asteroid
		asteroid_type = destination.type
		-- starts at 0 probability near origin, ends at destination probability
		-- retain all other properties same as destination, slow linear increase
		asteroid_spawn_points = {
			{
				angle_when_stopped = destination.angle_when_stopped,
				speed = destination.speed,
				probability = 0,
				distance = 0.05,
			},	
			{
				angle_when_stopped = destination.angle_when_stopped,
				speed = destination.speed,
				probability = destination.probability,
				distance = 0.95,
			},
		}
	-- asteroid exists in both origin and destination, so use properties of both
	else
		asteroid_name = origin.asteroid or destination.asteroid
		asteroid_type = origin.type or destination.type
		asteroid_spawn_points = generate_spawn_points(origin,destination)
	end
	return {asteroid = asteroid_name, type = asteroid_type, spawn_points= asteroid_spawn_points}
end

--- Generates the asteroid definitions for a connection between two locations.
---@param origin StdLib.Data.Space Origin planet or space location
---@param destination StdLib.Data.Space Destination planet or space location
---@return table[] asteroid_spawn_definitions
local function generate_connection_asteroids(origin, destination)
    local origin_asteroids = origin.asteroid_spawn_definitions or {}
    local destination_asteroids = destination.asteroid_spawn_definitions or {}

    local origin_map, destination_map = {}, {}
    local all_names = {}

    for _, asteroid in ipairs(origin_asteroids) do
        if asteroid.asteroid then
            origin_map[asteroid.asteroid] = asteroid
            all_names[asteroid.asteroid] = true
        end
    end

    for _, asteroid in ipairs(destination_asteroids) do
        if asteroid.asteroid then
            destination_map[asteroid.asteroid] = asteroid
            all_names[asteroid.asteroid] = true
        end
    end

    local merged = {}
    for name, _ in pairs(all_names) do
        table.insert(merged, merge_asteroid_definitions(origin_map[name], destination_map[name]))
    end

    return(merged)
end

-- ----------------------------
-- PlanetsLib orbit functions
-- ----------------------------
--- Sets this location's distance.
--- Updates orbit.distance through PlanetsLib when a valid orbit exists.
---@param distance number
---@return self
function Space:set_distance(distance)
	assert(type(distance) == "number", "distance must be a number")
	assert_planet_location(self, "set_distance")

	if self.orbit then
		local orbit = table.deepcopy(self.orbit)

		if has_parent_orbit(self) then
			orbit.distance = distance
		else
			-- Star-parent orbits mirror the normal starmap position.
			self.distance = distance
			orbit.distance = distance
			orbit.orientation = self.orientation
		end

		return update_orbit(self, orbit)
	end

	self.distance = distance
	return self
end


--- Adds a value to this location's current distance.
--- Uses orbit.distance when an orbit exists, otherwise the base distance field.
---@param delta number
---@return self
function Space:update_distance(delta)
	assert(type(delta) == "number", "delta must be a number")
	assert_planet_location(self, "update_distance")

	return self:set_distance(get_distance(self) + delta)
end


--- Copies another location's effective distance to this location.
--- The source and destination independently use orbit.distance or distance.
---@param other StdLib.Data.Space
---@return self
function Space:copy_distance(other)
	assert_planet_location(self, "copy_distance")
	assert_planet_location(other, "copy_distance")

	return self:set_distance(get_distance(other))
end


--- Sets this location's orientation.
--- Updates orbit.orientation through PlanetsLib when a valid orbit exists.
---@param orientation number
---@return self
function Space:set_orientation(orientation)
	assert(type(orientation) == "number", "orientation must be a number")
	assert_planet_location(self, "set_orientation")

	if self.orbit then
		local orbit = table.deepcopy(self.orbit)

		if has_parent_orbit(self) then
			orbit.orientation = orientation
		else
			-- Star-parent orbits mirror the normal starmap position.
			self.orientation = orientation
			orbit.distance = self.distance
			orbit.orientation = orientation
		end

		return update_orbit(self, orbit)
	end

	self.orientation = orientation
	return self
end

--- Sets this location's distance and orientation fields simultaneously.
---@param distance number
---@param orientation number
---@return self
function Space:set_position(distance, orientation)
	assert(type(distance) == "number", "distance must be a number")
	assert(type(orientation) == "number", "orientation must be a number")
	assert_planet_location(self, "set_position")

	if self.orbit then
		local orbit = table.deepcopy(self.orbit)

		if not has_parent_orbit(self) then
			self.distance = distance
			self.orientation = orientation
		end

		orbit.distance = distance
		orbit.orientation = orientation
		return update_orbit(self, orbit)
	end

	self.distance = distance
	self.orientation = orientation

	return self
end

--- Copies another location's effective distance and orientation.
--- Source and destination independently use orbit fields or base fields.
---@param other StdLib.Data.Space
---@return self
function Space:copy_position(other)
	assert_planet_location(self, "copy_position")
	assert_planet_location(other, "copy_position")

	return self:set_position(
		get_distance(other),
		get_orientation(other)
	)
end

-- ----------------------------
-- Asteroid spawn management
-- ----------------------------
--- Removes an asteroid from this prototype's spawn definitions.
---@param asteroid string Asteroid prototype name
---@return nil
function Space:remove_from_asteroid_spawn_definition(asteroid) 
	if self:is_valid() then
		remove_asteroid(self.asteroid_spawn_definitions,asteroid)
	end
end

--- Adds an asteroid spawn definition to this prototype.
---@param asteroid table Asteroid spawn definition
---@return nil
function Space:add_asteroid_spawn_definition(asteroid) 
    assert(type(asteroid) == "table", "asteroid must be a table")
	if self:is_valid() then
		table.insert(self.asteroid_spawn_definitions,asteroid)
	end
end

--- Returns a copy of this prototype's asteroid spawn definitions.
---@return table[]? asteroid_spawn_definitions
function Space:get_asteroid_spawn_definitions()
	if self:is_valid() then
		return table.deepcopy(self.asteroid_spawn_definitions)
	end
end

--- Removes all asteroid spawn definitions from this prototype.
---@return boolean cleared
function Space:clear_asteroid_spawn_definitions()
	if self:is_valid() then
		self.asteroid_spawn_definitions = {}
	end
	return true
end

--- Copies asteroid spawn definitions from another space prototype.
---@param copy_name string Source prototype name
---@param type_name string Source prototype type
---@return nil
function Space:copy_asteroid_spawn_definitions(copy_name,type_name) 
    assert(type(copy_name) == "string", "copy_name must be a string")
    assert(type(type_name) == "string", "type_name must be a string")
	if self:is_valid() then
		local object = Space(copy_name,type_name)
		if object:is_valid() then
			self:clear_asteroid_spawn_definitions()
			for _, asteroid in pairs(object:get_asteroid_spawn_definitions()) do
				self:add_asteroid_spawn_definition(asteroid)
			end
		end
	end
end

--- Creates a space connection between this location and a destination.
---@param destination StdLib.Data.Space Destination planet or space location
---@param length? number Connection length; defaults to `15000`
---@return StdLib.Data.Space connection
function Space:create_space_connection(destination, length)
    assert(self.type == "planet" or self.type == "space-location",
		"origin must be planet or space-location")
    assert(destination.type == "planet" or destination.type == "space-location",
		"destination must be planet or space-location")
	
	-- create the connection table with required properties
	local connection = {
		name = self.name.."-"..destination.name,
		type = "space-connection",
		from = self.name,
		to = destination.name,
		length = length or 15000,	-- default value for inner planet connections
		subgroup = "planet-connections",
		order = self.name.."-"..destination.name,
	}
	-- if both planet/space-locations has icon, use them in the connection icons
	if self.icon and destination.icon then
		local origin_scale = 0.33 * (64 / (self.icon_size or 64))
		local destination_scale = 0.33 * (64 / (destination.icon_size or 64))
		connection.icons = {
			{
				icon = "__space-age__/graphics/icons/planet-route.png",
				icon_size = 64,
			},
			{
				icon = self.icon,
				icon_size = self.icon_size or 64,
				scale = origin_scale,
				shift = {-6,-6},
			},
			{
				icon = destination.icon,
				icon_size = destination.icon_size or 64,
				scale = destination_scale,
				shift = {6,6},
			}
		}
	else
		connection.icon = "__space-age__/graphics/icons/planet-route.png"
		connection.icon_size = 64
	end
	connection.asteroid_spawn_definitions =
		generate_connection_asteroids(self, destination)
	data:extend({connection})
	return Space(connection.name, "space-connection")
end

return Space
