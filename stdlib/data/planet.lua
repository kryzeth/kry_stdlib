local Data = require('__kry_stdlib__/stdlib/data/data') --[[@as StdLib.Data]]
local Space = require('__kry_stdlib__/stdlib/data/space')

--- Wrapper for Factorio planet prototypes.
---@class StdLib.Data.Planet : StdLib.Data.Space
local Planet = {
    __class = 'Planet',
}

-- Custom __index function for function inheritance from both Space and Data.
---@param table StdLib.Data.Planet Planet wrapper
---@param key any Field or method key
---@return any value
Planet.__index = function(table, key)
    -- Check if the key exists in Space first.
    if Space[key] then
        return Space[key]
    -- If not found in Space, fallback to Data.
    elseif Data[key] then
        return Data[key]
    end
    -- Return nil if key is not found in either Space or Data.
    return nil
end

--- Looks up and wraps a planet by name.
---@param planet string Planet prototype name
---@return StdLib.Data.Planet planet
function Planet:__call(planet)
    local new = self:get(planet, 'planet')
    ---@cast new StdLib.Data.Planet
    return new
end

setmetatable(Planet, Planet)

return Planet
