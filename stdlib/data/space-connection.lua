local Data = require('__kry_stdlib__/stdlib/data/data') --[[@as StdLib.Data]]
local Space = require('__kry_stdlib__/stdlib/data/space')

--- Wrapper for Factorio space-connection prototypes.
---@class StdLib.Data.SpaceConnection : StdLib.Data.Space
local SpaceConnection = {
    __class = 'SpaceConnection',
}

-- Custom __index function for function inheritance from both Space and Data.
---@param table StdLib.Data.SpaceConnection Space-connection wrapper
---@param key any Field or method key
---@return any value
SpaceConnection.__index = function(table, key)
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

--- Looks up and wraps a space connection by name.
---@param space_connection string Space-connection prototype name
---@return StdLib.Data.SpaceConnection space_connection
function SpaceConnection:__call(space_connection)
    local new = self:get(space_connection, 'space-connection')
    ---@cast new StdLib.Data.SpaceConnection
    return new
end

setmetatable(SpaceConnection, SpaceConnection)

return SpaceConnection
