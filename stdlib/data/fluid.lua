local Data = require('__kry_stdlib__/stdlib/data/data') --[[@as StdLib.Data]]

--- Fluid
---@class StdLib.Data.Fluid : StdLib.Data
local Fluid = {
    __class = 'Fluid',
    __index = Data,
}

---@param fluid string Fluid prototype name
---@return StdLib.Data.Fluid fluid
function Fluid:__call(fluid)
    local new = self:get(fluid, 'fluid')
    ---@cast new StdLib.Data.Fluid
    return new
end
setmetatable(Fluid, Fluid)

return Fluid
