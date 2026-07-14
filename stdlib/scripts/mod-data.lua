-------------------------------------------------------------------------------
-- [ModData] -- Shorthand for safer access to mod-data tables during runtime
-------------------------------------------------------------------------------

local ModData = {}

--- Safely returns the data table from prototypes.mod_data[name].
--- Returns an empty table if the mod-data table does not exist or has no data.
---@param name string
---@return table
function ModData.get(name)
	assert(type(name) == "string", "mod-data name must be a string")

	local mod_data = prototypes.mod_data and prototypes.mod_data[name]

	if mod_data and type(mod_data.data) == "table" then
		return mod_data.data
	end

	return {}
end

setmetatable(ModData, {
	__call = function(_, name)
		return ModData.get(name)
	end
})

return ModData