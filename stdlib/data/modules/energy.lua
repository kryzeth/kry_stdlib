--- Utilities for parsing, formatting, and scaling Factorio `Energy` strings.
---@class StdLib.Data.Energy
---@alias EnergyUnit "W"|"J"
local Energy = {}

-- List of Factorio-supported decimal multipliers. 'K' is accepted as a legacy alias
-- because some existing mods use it, but formatted values always use 'k'.
local multipliers = {
    [""] = 1,
    k = 1e3,
    K = 1e3,
    M = 1e6,
    G = 1e9,
    T = 1e12,
    P = 1e15,
    E = 1e18,
    Z = 1e21,
    Y = 1e24,
    R = 1e27,
    Q = 1e30,
}

local ordered_prefixes = {
    { prefix = "Q", multiplier = 1e30 },
    { prefix = "R", multiplier = 1e27 },
    { prefix = "Y", multiplier = 1e24 },
    { prefix = "Z", multiplier = 1e21 },
    { prefix = "E", multiplier = 1e18 },
    { prefix = "P", multiplier = 1e15 },
    { prefix = "T", multiplier = 1e12 },
    { prefix = "G", multiplier = 1e9 },
    { prefix = "M", multiplier = 1e6 },
    { prefix = "k", multiplier = 1e3 },
    { prefix = "", multiplier = 1 },
}

--- Converts a finite number to a decimal string without trailing zeroes.
---@param value number
---@return string
local function format_number(value)
    local formatted = string.format("%.15f", value)
        :gsub("0+$", "")
        :gsub("%.$", "")

    -- Avoid returning `-0` after floating-point rounding.
    return formatted == "-0" and "0" or formatted
end

--- Parses a Factorio 'Energy' string into its base-unit value.
--- For example, "1.5MW" returns 1500000, "W", "M".
--- Returns 'nil' when the value is not a valid energy string.
---@param energy string
---@return number? value Value expressed in plain watts or joules
---@return EnergyUnit? unit
---@return string? prefix Original SI prefix
function Energy.parse(energy)
    if type(energy) ~= "string" then return end

    -- splits the base string into three parts
    local amount, prefix, unit = energy:match("^([%+%-]?%d*%.?%d+)([kKMGTPEZYRQ]?)([WJ])$")
    -- convert the value to number
    local numeric_amount = tonumber(amount)
    -- then add in the multiplier from the unit prefix (i.e. 1.5kW -> 1500)
    local multiplier = prefix and multipliers[prefix]

    -- in case the input is unsupported in some way
    if not numeric_amount or not multiplier then return end

    return numeric_amount * multiplier, unit, prefix
end

--- Formats a base-unit energy value as a Factorio 'Energy' string.
--- When prefix is omitted, the largest suitable Factorio multiplier is used.
--- For example, `Energy.format(1500000, "W")` returns "1.5MW".
---@param value number Value expressed in plain watts or joules
---@param unit EnergyUnit
---@param prefix? string SI prefix to force; defaults to automatic selection
---@return string? energy
function Energy.format(value, unit, prefix)
    -- in case any of the required fields are incorrectly formatted
    if type(value) ~= "number" or (unit ~= "W" and unit ~= "J") then return end

    local multiplier
    if prefix ~= nil then
        multiplier = multipliers[prefix]
        if not multiplier then return end
        if prefix == "K" then prefix = "k" end
    else
        local absolute_value = math.abs(value)
        for _, definition in ipairs(ordered_prefixes) do
            if absolute_value >= definition.multiplier then
                prefix = definition.prefix
                multiplier = definition.multiplier
                break
            end
        end

        -- Zero and values below one watt/joule use the base unit.
        prefix = prefix or ""
        multiplier = multiplier or 1
    end

    return format_number(value / multiplier) .. prefix .. unit
end

--- Multiplies a Factorio 'Energy' string while retaining its original prefix.
--- For example, `Energy.scale("60kW", 1.5)` returns "90kW".
--- Returns 'nil' when 'energy' is invalid or 'scalar' is not a finite number.
---@param energy string
---@param scalar number
---@return string? scaled_energy
function Energy.scale(energy, scalar)
    if type(scalar) ~= "number" then return end

    local value, unit, prefix = Energy.parse(energy)
    if not value or not unit then return end

    return Energy.format(value * scalar, unit, prefix)
end

return Energy
