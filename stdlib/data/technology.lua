local Data = require('__kry_stdlib__/stdlib/data/data')

--- Wrapper for Factorio technology prototypes.
---@class StdLib.Data.Technology : StdLib.Data
---@field effects? table[] Technology effects
---@field prerequisites? string[] Prerequisite technology names
---@field unit? table Technology research-unit properties
local Technology = {
    __class = 'Technology',
    __index = Data,
}

--- Looks up and wraps a technology by name.
---@param tech string Technology prototype name
---@return StdLib.Data.Technology technology
function Technology:__call(tech)
    local new = self:get(tech, 'technology')
    ---@cast new StdLib.Data.Technology
    return new
end
setmetatable(Technology, Technology)

--- Adds an effect to a technology.
---@param effect string|number|boolean|table Effect target, modifier value, or complete effect definition
---@param effect_type? string Technology effect type; defaults to `"unlock-recipe"`
---@return self
function Technology:add_effect(effect, effect_type)
    assert(effect ~= nil, 'effect must not be nil')

    if self:is_valid('technology') then
        self.effects = self.effects or {}

        -- Complete effect definition
        if type(effect) == 'table' and effect.type then
            table.insert(self.effects, effect)
            return self
        end

        effect_type = effect_type or 'unlock-recipe'

        local effect_fields = {
            ['unlock-recipe'] = 'recipe',
            ['unlock-space-location'] = 'space_location',
            ['unlock-quality'] = 'quality',
            ['give-item'] = 'item'
        }

        local new_effect = { type = effect_type }

        if effect_type == 'nothing' then
            new_effect.effect_description = effect
        elseif type(effect) == 'table' then
            new_effect = table.deepcopy(effect)
            new_effect.type = effect_type
        else
            local field = effect_fields[effect_type] or 'modifier'
            new_effect[field] = effect
        end

        table.insert(self.effects, new_effect)
    end

    return self
end

--- Removes an effect from a technology or removes a recipe unlock.
---@param tech_name? string Technology prototype name
---@param unlock_type? string Technology effect type
---@param name? string Effect target name
---@return self
---@return string? name
---@return string? unlock_type
function Technology:remove_effect(tech_name, unlock_type, name)
    if self:is_valid('technology') then
        return self, name, unlock_type ---@todo implement
    elseif self:is_valid('recipe') then
        if tech_name then
            local tech = Technology(tech_name)
            if tech:is_valid() then
                for index, effect in pairs(tech.effects or {}) do
                    if effect.type == 'unlock-recipe' and effect.recipe == self.name then
                        table.remove(tech.effects, index)
                    end
                end
            end
        else
            for _, tech in pairs(data.raw['technology']) do
                for index, effect in pairs(tech.effects or {}) do
                    if effect.type == 'unlock-recipe' and effect.recipe == self.name then
                        table.remove(tech.effects, index)
                    end
                end
            end
        end
    end
    return self
end

--- Checks whether this technology contains a science pack.
---@param pack string Science-pack item name
---@return boolean has_pack
---@return integer? index
function Technology:has_pack(pack)
    if self:is_valid('technology') and self.unit then
        for i, ing in pairs(self.unit.ingredients or {}) do
            if ing[1] == pack then
                return true, i
            end
        end
    end
    return false
end

--- Adds a science pack to this technology's research ingredients.
---@param new_pack string|table Science-pack name or `{name, count}` pair
---@param count? number Ingredient count; defaults to `1`
---@return self
function Technology:add_pack(new_pack, count)
    if self:is_valid('technology') then
        local Item = require('__kry_stdlib__/stdlib/data/item')
        if type(new_pack) == 'table' then
            count = new_pack[2] or 1
            new_pack = new_pack[1]
        elseif type(new_pack) == 'string' then
            count = count or 1
        else
            error('new_pack must be a table or string')
        end
        -- check if science pack is valid, and not already used in technology
        if not self.unit then   -- empty unit field
            log(self.name .. ' has no science cost to modify.')
        elseif not Item(new_pack):is_valid() then   -- invalid science pack
            log(new_pack .. ' is not a valid science pack.')
        elseif self:has_pack(new_pack) then -- duplicate science pack
            log(self.name .. ' already contains ' .. new_pack .. '.')
        else
            self.unit.ingredients = self.unit.ingredients or {}
            self.unit.ingredients[#self.unit.ingredients + 1] = { new_pack, count }
        end
    end
    return self
end

--- Removes a science pack from this technology's research ingredients.
---@param pack string Science-pack item name
---@return self
function Technology:remove_pack(pack)
    if self:is_valid('technology') then
        -- check for index of science pack, then remove that index
        local _, index = self:has_pack(pack)
        if index then
            table.remove(self.unit.ingredients, index)
        end
    end
    return self
end

--- Replaces a science pack in this technology's research ingredients.
---@param old_pack string Existing science-pack item name
---@param new_pack string Replacement science-pack item name
---@param count? number Replacement ingredient count
---@return self
function Technology:replace_pack(old_pack, new_pack, count)
    if self:is_valid('technology') then
        local Item = require('__kry_stdlib__/stdlib/data/item')
        if not self.unit then
            log(self.name .. ' has no science cost to modify.') -- empty unit field
        elseif not Item(new_pack):is_valid() then
            log(new_pack .. ' is not a valid science pack.')    -- invalid new_pack
        else
            local _, index = self:has_pack(old_pack)
            -- check for index of old_pack, then replace the values for that index
            if not index then
                log(self.name .. ' does not contain ' .. old_pack .. '.')   -- missing old_pack
            elseif old_pack ~= new_pack and self:has_pack(new_pack) then
                log(self.name .. ' already contains ' .. new_pack .. '.')   -- duplicate new_pack
            else
                local ing = self.unit.ingredients[index]
                ing[1] = new_pack
                ing[2] = count or ing[2] or 1
            end
        end
    end
    return self
end

--- Sets the amount of an existing science pack.
---@param pack string Science-pack item name
---@param count number New ingredient count
---@return self
function Technology:set_pack_count(pack, count)
    if self:is_valid('technology') then
        if not self.unit then
            log(self.name .. ' has no science cost to modify.') -- empty unit field
        else
            local _, index = self:has_pack(pack)
            -- check for index of science pack, then adjust the count for that index
            if not index then
                log(self.name .. ' does not contain ' .. pack .. '.') -- missing science pack
            else
                self.unit.ingredients[index][2] = count
            end
        end
    end
    return self
end
Technology.set_pack_amount = Technology.set_pack_count

--- Adds a prerequisite technology.
---@param tech_name string Prerequisite technology name
---@return self
function Technology:add_prereq(tech_name)
    if self:is_valid('technology') and Technology(tech_name):is_valid() then
        self.prerequisites = self.prerequisites or {}
        ---@type string[]
        local pre = self.prerequisites
        for _, existing in pairs(pre) do
            if existing == tech_name then
                return self
            end
        end

        pre[#pre + 1] = tech_name
    end
    return self
end

--- Removes a prerequisite technology.
---@param tech_name string Prerequisite technology name
---@return self
function Technology:remove_prereq(tech_name)
    if self:is_valid('technology') then
        local pre = self.prerequisites or {}
        for i = #pre, 1, -1 do
            if pre[i] == tech_name then
                table.remove(pre, i)
                break
            end
        end
        if #pre == 0 then
            self.prerequisites = nil
        end
    end
    return self
end

--- Replaces one prerequisite technology with another.
---@param old_tech string Existing prerequisite technology name
---@param new_tech string Replacement prerequisite technology name
---@return self
function Technology:replace_prereq(old_tech, new_tech)
    if self:is_valid('technology') then
		self:remove_prereq(old_tech)
		self:add_prereq(new_tech)
	end
	return self
end

--- Copies research-unit properties from another technology.
---@param tech_name string Source technology name
---@return self|false result
function Technology:copy_cost(tech_name)
	local original = Technology(tech_name)
    if self:is_valid('technology') and original:is_valid() then
		if original.unit then	-- ensure this exists before referencing it
			self.unit = table.deepcopy(original.unit)
		else
			log(self.name .. " has no science cost to copy.")
			return false
		end
	end
	return self
end

--- Multiplies this technology's research-unit count.
---@param mult number Cost multiplier
---@return self|false result
function Technology:multiply_cost(mult)
    if self:is_valid('technology') then
		if self.unit then	-- ensure this exists before referencing it
			self.unit.count = mult*self.unit.count
		else
			log(self.name .. " has no science cost to multiply.")
			return false
		end
	end
	return self
end

--- Adds a recipe-unlock effect to this technology.
---@param recipe string Recipe prototype name
---@return nil
function Technology:add_unlock(recipe)
    if self:is_valid('technology') then
        self.effects = self.effects or {}
        table.insert(self.effects, {type = "unlock-recipe", recipe = recipe})
    end
end

--- Returns the recipes unlocked by this technology.
---@return table<string, true>? recipes
function Technology:get_recipes()
    if self:is_valid('technology') and self.effects then
        local recipes = {}
		for _, effect in pairs(self.effects) do
			if effect.type == "unlock-recipe" then
				recipes[effect.recipe] = true
			end
		end
		return recipes
    end
end

--- Removes a recipe-unlock effect from this technology.
---@param recipe string Recipe prototype name
---@return nil
function Technology:remove_unlock(recipe)
	if self:is_valid('technology') then
		for index, effect in pairs(self.effects) do
			if effect.type == "unlock-recipe" and effect.recipe == recipe then
				table.remove(self.effects, index)
			end
		end
	end
end

return Technology
