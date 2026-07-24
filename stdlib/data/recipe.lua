local Data = require('__kry_stdlib__/stdlib/data/data')
local Tech = require('__kry_stdlib__/stdlib/data/technology')
local Category = require('__kry_stdlib__/stdlib/data/category')

--- Recipe class
---@class StdLib.Data.Recipe : StdLib.Data
local Recipe = {
    __class = 'Recipe',
    __index = Data,
}

---@param recipe string Recipe prototype name
---@return StdLib.Data.Recipe recipe
function Recipe:__call(recipe)
    local new = self:get(recipe, 'recipe')
    -- rawset(new, 'Ingredients', {})
    -- rawset(new, 'Results', {})
    ---@cast new StdLib.Data.Recipe
    return new
end
setmetatable(Recipe, Recipe)

--- Remove an ingredient from an ingredients table.
---@param ingredients table
---@param name string Name of the ingredient to remove
local function remove_ingredient(ingredients, name)
    for i, ingredient in pairs(ingredients or {}) do
        if ingredient[1] == name or ingredient.name == name then
            table.remove(ingredients, i)
            return true
        end
    end
end

--- Replace an ingredient.
---@param ingredients table
---@param find string ingredient to replace
---@param replace Ingredient
---@param replace_name_only boolean Don't replace amounts
local function replace_ingredient(ingredients, find, replace, replace_name_only)
    for i, ingredient in pairs(ingredients or {}) do
        if ingredient.name == find then
            if replace_name_only then
                local amount = ingredient.amount
                replace.amount = amount
            end
            ingredients[i] = replace
            return true
        end
    end
end

--- Remove a product from results table.
---@param results table
---@param name string|Product Name of the product to remove
local function remove_result(results, name)
    name = type(name)=="string" and name or name.name
    for i, product in pairs(results or {}) do
        if product[1] == name or product.name == name then
            table.remove(results, i)
            return true
        end
    end
end

--- Finds a product from results table.
---@param results table
---@param name string Name of the product to find
---@return Product?
local function find_result(results, name)
    for i, product in pairs(results or {}) do
        if product.name == name then
            return product
        end
    end
end

--- Replace a product.
---@param results table
---@param find string product to replace
---@param replace Product product
local function replace_result(results, find, replace)
    for i, product in pairs(results or {}) do
        if product[1] == find or product.name == find then
            results[i] = replace
            return true
        end
    end
end

--- Add a new ingredient to a recipe.
---@param ingredient table to add (no longer supports string/count)
---@return StdLib.Data.Recipe
function Recipe:add_ingredient(ingredient)
	assert(type(ingredient)=="table",'argument must be a valid ingredient table')
    if self:is_valid() then
		self.ingredients = self.ingredients or {}
		-- check if ingredient already exists in recipe table
		for _, existing in pairs(self.ingredients) do
			if existing.name == ingredient.name then
				-- immediately break loop if ingredient already exists in table
				return self
			end
		end
		table.insert(self.ingredients, ingredient)
	end
    return self
end
Recipe.add_ing = Recipe.add_ingredient

--- Remove one ingredient completely.
---@param ingredient string Name of ingredient to remove
---@return StdLib.Data.Recipe
function Recipe:remove_ingredient(ingredient)
    if self:is_valid() then
        if self.ingredients then
            remove_ingredient(self.ingredients, ingredient)
        end
    end
    return self
end
Recipe.rem_ing = Recipe.remove_ingredient

--- Replace one ingredient with another.
---@param replace string Name of ingredient to be replaced
---@param ingredient string|Ingredient Name or table to add
---@param count number? [opt] Amount of ingredient
---@return StdLib.Data.Recipe
function Recipe:replace_ingredient(replace, ingredient, count)
    assert(replace, 'Missing recipe to replace')
    if self:is_valid() then
		local replace_name_only = false
		if type(ingredient)=="string" and count then
			ingredient = {name=ingredient,amount=count,type="item"}
		elseif type(ingredient)=="string" then
			replace_name_only = true
			ingredient = {name=ingredient,amount=1,type="item"}
		end
		if self.ingredients then
            replace_ingredient(self.ingredients, replace, ingredient, replace_name_only)
        end
    end
    return self
end
Recipe.rep_ing = Recipe.replace_ingredient

--- Removes all ingredients from recipe completely.
---@return self
function Recipe:clear_ingredients()
    if self:is_valid() then
		self.ingredients = {}
    end
    return self
end
Recipe.clr_ing = Recipe.clear_ingredients

--- Copies ingredients from one recipe to another.
---@param recipe string Name of the recipe to copy ingredients from
---@param keep_ingredients boolean? [opt] Whether to keep the original ingredients
---@return self
function Recipe:copy_ingredients(recipe, keep_ingredients)
	if self:is_valid() then
		local recipe = Recipe(recipe)
		if recipe:is_valid() then
			if not keep_ingredients then
				self:clear_ingredients()
			end
			for _, ingredient in pairs(recipe:get_ingredients()) do
				self:add_ingredient(ingredient)
			end
		end
	end
    return self
end
Recipe.copy_ing = Recipe.copy_ingredients

--- Returns a copy of this recipe's ingredients.
---@return Ingredient[]? ingredients
function Recipe:get_ingredients()
    if self:is_valid() then
		return table.deepcopy(self.ingredients)
    end
end
Recipe.get_ing = Recipe.get_ingredients

--- Gets the amount of a specified ingredient.
---@param ingredient_name string Name of the ingredient
---@return number? amount
function Recipe:get_ingredient_amount(ingredient_name)
    if self:is_valid() then
		for _, ingredient in pairs(self.ingredients) do
			if ingredient.name == ingredient_name then
				return ingredient.amount
			end
		end
    end
end
Recipe.get_ingredient_count = Recipe.get_ingredient_amount

--- Sets the ingredients for this recipe.
---@param ingredients string|Ingredient[] Ingredient name or complete ingredient array
---@param amount number? Amount when `ingredients` is a name
---@param ingredient_type "item"|"fluid"? Ingredient type when `ingredients` is a name
---@return boolean success
function Recipe:set_ingredients(ingredients, amount, ingredient_type)
	if self:is_valid() then
		if type(ingredients) == "table" then
			self.ingredients = ingredients
			return true
		elseif type(ingredients) == "string" then
			local ingredient_type = ingredient_type or "item"
			local amount = amount or 1
			self.ingredients = {{name = ingredients, amount = amount, type = ingredient_type}}
			return true
		end
	end
	log("Failed to modify ingredients table for " .. self.name)
	return false
end
Recipe.set_ing = Recipe.set_ingredients

--- Sets the amount of a specific ingredient in a recipe.
---@param find string Name of the ingredient to modify
---@param amount number New amount to assign to the ingredient
---@return boolean success
function Recipe:set_ingredient_amount(find, amount)
	if self:is_valid() then
		for _, ingred in pairs(self.ingredients or {}) do
			if ingred.name == find then
				-- Replace the current ingredient amount with the desired amount
				ingred.amount = amount
				return true
			end
		end
	end
	log("Failed to locate " .. find .. " in the ingredient list for " .. self.name)
	return false
end
Recipe.set_ingredient_count = Recipe.set_ingredient_amount

--- Multiplies the amount of one ingredient.
---@param find string Name of the ingredient
---@param mult number Multiplier
---@return boolean success
function Recipe:multiply_ingredient(find, mult)
	if self:is_valid() then
		for _, ingred in pairs(self.ingredients or {}) do
			if ingred.name == find then
				ingred.amount = mult*ingred.amount
				return true
			end
		end
	end
	log("Failed to locate "..find .." in the ingredient list for "..self.name)
	return false
end

--- Multiplies the amount of each ingredient in a recipe.
---@param mult number Amount to multiply each ingredient by
---@return self
function Recipe:multiply_ingredients(mult)
	if self:is_valid() then
		if self.ingredients then
			for _, ingred in pairs(self.ingredients) do
				ingred.amount = mult*ingred.amount
			end
		end
	end
	return self
end

--- Add a recipe category to the list of categories
---@param category_name string The crafting category to add
---@return self
function Recipe:add_category(category_name)
    if self:is_valid() then
		-- ensure category is valid before modifying recipe.categories
		local category = Category(category_name, 'recipe-category')
		if category:is_valid() then
			-- 'crafting' is set by default when recipe.categories is undefined
			self.categories = self.categories or {'crafting'}
			category:add_to(self, 'categories')
		end
    end
    return self
end

--- Remove a recipe category from the list of categories
---@param category_name string The crafting category to remove
---@return self
function Recipe:remove_category(category_name)
    if self:is_valid() then
		-- remove_from performs category validity checking
		Category(category_name, 'recipe-category'):remove_from(self, 'categories')
    end
    return self
end

--- Add to technology as a recipe unlock.
---@param tech_name string Name of the technology to add the unlock too
---@return self
function Recipe:add_unlock(tech_name)
    if self:is_valid() then
        local tech = Tech(tech_name)
        if tech:is_valid() then
            self:set_enabled(false)
            tech:add_effect(self.name)
        end
    end
    return self
end

--- Remove the recipe unlock from the technology.
---@param tech_name string Name of the technology to remove the unlock from
---@return self
function Recipe:remove_unlock(tech_name)
    if self:is_valid('recipe') then
        Tech.remove_effect(self, tech_name, 'unlock-recipe')
    end
    return self
end

--- Returns all technologies that unlock this recipe.
---@return table<string, true>? technologies
function Recipe:get_technologies()
    if self:is_valid('recipe') then
		local technologies = {}
		-- for each technology, get list of unlocked recipes, check if this recipe is in list
		for tech_name in pairs(data.raw.technology) do
			local recipes = Tech(tech_name):get_recipes()
			if recipes and recipes[self.name] then
				technologies[tech_name] = true
			end
		end
		return technologies
	end
end
Recipe.get_tech = Recipe.get_technologies

--- Copies recipe unlocks from another recipe.
---@param copy_name string Source recipe name
function Recipe:copy_unlock(copy_name)
	local copy_recipe = Recipe(copy_name)
	if self:is_valid() and copy_recipe:is_valid() then
		-- get list of technologies that unlock copy_recipe
		local technologies = copy_recipe:get_technologies()
		if technologies then
			for tech_name in pairs(technologies) do
				self:add_unlock(tech_name)
			end
		else
			self:set_enabled(true)	-- otherwise assume recipe begins enabled
			log("Failed to locate source techs for: "..copy_name..". Setting enabled to true for: "..self.name)
		end
	else log("Failed to copy unlock: self or copy_name were invalid")
	end
end

--- Set the enabled status of the recipe.
---@param enabled boolean Enable or disable the recipe
---@return self
function Recipe:set_enabled(enabled)
    if self:is_valid() then
        self.enabled = enabled
    end
    return self
end

--- Get the recipe's main product item.
--- Attempts to use main_product first, then falls back to the first result.
---@return StdLib.Data.Item
function Recipe:get_main_product()
    local Item = require('__kry_stdlib__/stdlib/data/item') --[[@as StdLib.Data.Item]]

    if self:is_valid('recipe') then
        local main_product = self.main_product

        if main_product and main_product ~= "" then
            return Item(main_product, nil, self.options)
        end

        local results = self.results
        local result = results and results[1]

        if result then
            return Item(result.name or result[1], nil, self.options)
        end
    end

    return Item()
end

--- Set the main product of the recipe.
---@param main_product string
---@return self
function Recipe:set_main_product(main_product)
    if self:is_valid('recipe') then
		local Item = require('__kry_stdlib__/stdlib/data/item')
		if Item(main_product):is_valid() then
			self.main_product = main_product
		end
    end
    return self
end

--- Remove the main product of the recipe.
---@return self
function Recipe:remove_main_product()
    if self:is_valid('recipe') then
        self.main_product = ""
    end
    return self
end

--- Add a new product to results table.
---@param product string|Product product Name or table to add
---@param count number? [opt] Amount of product
---@param probability number? [opt] A value in range [0, 1]. Item is only given with this probability; otherwise no product is produced.
---@return StdLib.Data.Recipe
function Recipe:add_result(product, count, probability)
    if self:is_valid() then
		if type(product)=="string" then
			local count = count or 1
			local probability = probability or 1
			---@diagnostic disable-next-line: missing-fields
			product = {type="item", name=product, amount=count, independent_probability=probability}
		end
        if self.results then
			table.insert(self.results, product)
        end
    end
    return self
end

--- Remove a product from results table.
---@param product string|Product Name or table to add
---@return StdLib.Data.Recipe
function Recipe:remove_result(product)
    if self:is_valid() then
        if self.results then
            remove_result(self.results, product)
        end
    end
    return self
end

--- Replace a product from results with a new product.
---@param replace string Name of product to be replaced
---@param product string|Product Name or table to add
---@param count number? [opt] Amount of product
---@param probability number? [opt] A value in range [0, 1]. Item is only given with this probability; otherwise no product is produced.
---@return StdLib.Data.Recipe
function Recipe:replace_result(replace, product, count, probability)
    if not self:is_valid() then return self end
	if type(product)=="string" then
		local p0 = find_result(self.results, replace)
		if not p0 then return self end
		local count = (p0.amount and p0.amount > 0) and p0.amount or ((count and count > 1) and count or 1)
		local probability = (p0.independent_probability and p0.independent_probability > 0) and p0.independent_probability
			or ((probability and probability >= 0 and probability <= 1) and probability or 1)
		---@diagnostic disable-next-line: missing-fields
		product = {name=product, amount=count, type="item", independent_probability=probability}
	end
	if self.results then
		replace_result(self.results, replace, product)
	end
    return self
end

--- Removes all results from recipe completely.
---@return self
function Recipe:clear_results()
    if self:is_valid() then
		self.results = {}
    end
    return self
end

--- Copies results from one recipe to another.
---@param recipe string Name of the recipe to copy results from
---@param keep_results boolean? [opt] Whether to keep the original results
---@return self
function Recipe:copy_results(recipe, keep_results)
	if self:is_valid() then
		local recipe = Recipe(recipe)
		if recipe:is_valid() then
			if not keep_results then
				self:clear_results()
			end
			for _, result in pairs(recipe:get_results()) do
				self:add_result(result)
			end
		end
	end
    return self
end

--- Returns this recipe's results.
---@return Product[]? results
function Recipe:get_results()
    if self:is_valid() then
		return self["results"]
    end
end

--- Gets the amount of a specified result.
---@param result_name string Name of the result
---@return number? amount
function Recipe:get_result_count(result_name)
    if self:is_valid() then
		for _, result in pairs(self.results) do
			if result.name == result_name then
				return result.amount
			end
		end
		log('Could not locate result '..result_name..' for this recipe '..self.name)
    end
end
Recipe.get_result_amount = Recipe.get_result_count

--- Sets the results for this recipe.
---@param results string|Product[] Result name or complete product array
---@param amount number? Amount when `results` is a name
---@param result_type "item"|"fluid"? Result type when `results` is a name
---@return boolean success
function Recipe:set_results(results, amount, result_type)
	if self:is_valid() then
		if type(results) == "table" then
			self.results = results
			return true
		elseif type(results) == "string" then
			local result_type = result_type or "item"
			---@diagnostic disable-next-line: missing-fields
			self.results = {{name = results, amount = amount, type = result_type}}
			return true
		end
	end
	log("Failed to modify results table for " .. self.name)
	return false
end

--- Sets the amount of a specific result in a recipe.
---@param find string Name of the result to modify
---@param amount number New amount to assign to the result
---@return boolean success
function Recipe:set_result_amount(find, amount)
	if self:is_valid() then
		for _, result in pairs(self.results or {}) do
			if result.name == find then
				-- Replace the current result amount with the desired amount
				result.amount = amount
				return true
			end
		end
	end
	log("Failed to locate " .. find .. " in the result list for " .. self.name)
	return false
end

--- Multiplies the amount of one result.
---@param find string Name of the result
---@param mult number Multiplier
---@return boolean success
function Recipe:multiply_result(find, mult)
	if self:is_valid() then
		for _, result in pairs(self.results or {}) do
			if result.name == find then
				result.amount = mult*result.amount
				return true
			end
		end
	end
	log("Failed to locate "..find .." in the result list for "..self.name)
	return false
end

--- Multiplies the amount of each result in a recipe.
---@param mult number Amount to multiply each result by
---@return self
function Recipe:multiply_results(mult)
	if self:is_valid() then
		if self.results then
			for _, result in pairs(self.results) do
				result.amount = mult*result.amount
			end
		end
	end
	return self
end

--- Removes all surface conditions from recipe completely.
---@return self
function Recipe:clear_surface_conditions()
    if self:is_valid() then
		self.surface_conditions = {}
    end
    return self
end

return Recipe
