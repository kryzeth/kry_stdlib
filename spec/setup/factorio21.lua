-- Adapt the historical stdlib test harness to Factorio 2.1 runtime globals.
local direction = defines.direction
direction.north = 0
direction.northnortheast = 1
direction.northeast = 2
direction.eastnortheast = 3
direction.east = 4
direction.eastsoutheast = 5
direction.southeast = 6
direction.southsoutheast = 7
direction.south = 8
direction.southsouthwest = 9
direction.southwest = 10
direction.westsouthwest = 11
direction.west = 12
direction.westnorthwest = 13
direction.northwest = 14
direction.northnorthwest = 15

-- Factorio's util.contains_value accepts both arrays and keyed tables.
_G.util = _G.util or {}
_G.util.contains_value = _G.util.contains_value or function(list, value)
    for _, entry in pairs(list) do
        if entry == value then
            return true
        end
    end
    return false
end

_G.helpers = _G.helpers or {}
_G.helpers.write_file = _G.helpers.write_file or function(...)
    return _G.game.write_file(...)
end

return true
