local Data = require('__kry_stdlib__/stdlib/data/data') --[[@as StdLib.Data]]
local Space = require('__kry_stdlib__/stdlib/data/space')

--- Wrapper for Factorio space-location prototypes.
---@class StdLib.Data.SpaceLocation : StdLib.Data.Space
local SpaceLocation = {
    __class = 'SpaceLocation',
}

-- Custom __index function for function inheritance from both Space and Data.
---@param table StdLib.Data.SpaceLocation Space-location wrapper
---@param key any Field or method key
---@return any value
SpaceLocation.__index = function(table, key)
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

--- Looks up and wraps a space location by name.
---@param space_location string Space-location prototype name
---@return StdLib.Data.SpaceLocation space_location
function SpaceLocation:__call(space_location)
    local new = self:get(space_location, 'space-location')
    ---@cast new StdLib.Data.SpaceLocation
    return new
end

setmetatable(SpaceLocation, SpaceLocation)

return SpaceLocation