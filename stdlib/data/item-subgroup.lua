local Data = require('__kry_stdlib__/stdlib/data/data')
local Table = require('__kry_stdlib__/stdlib/utils/table')
local Groups = require('__kry_stdlib__/stdlib/data/modules/groups')

--- Wrapper for Factorio item-subgroup prototypes.
---@class StdLib.Data.ItemSubgroup : StdLib.Data
---@field group string Parent item-group prototype name
local ItemSubgroup = {
    __class = 'ItemSubgroup',
    __index = Data,
}

--- Looks up and wraps an item subgroup by name.
---@param item_subgroup string Item-subgroup prototype name
---@return StdLib.Data.ItemSubgroup item_subgroup
function ItemSubgroup:__call(item_subgroup)
    local new = self:get(item_subgroup, 'item-subgroup')
    ---@cast new StdLib.Data.ItemSubgroup
    return new
end
setmetatable(ItemSubgroup, ItemSubgroup)

-- ----------------------------
-- Internal helpers
-- ----------------------------

local prototype_types = Table.array_combine(
    Groups.item,
    Groups.entity,
    {'recipe'}
)

--- Returns whether the prototype should not be included in the row count.
---@param prototype table Prototype to inspect
---@return boolean? hidden
local function is_hidden(prototype)
    return prototype.hidden or prototype.hidden_in_factoriopedia
end

--- Counts visible prototypes assigned to the given subgroup.
--- Entries with the same internal name are only counted once.
---@param subgroup_name string Item-subgroup prototype name
---@return integer count
local function count_visible_subgroup_entries(subgroup_name)
    local count = 0
    local counted_names = {}

    for _, type_name in pairs(prototype_types) do
        for name, prototype in pairs(data.raw[type_name] or {}) do
            if prototype.subgroup == subgroup_name and not is_hidden(prototype) and not counted_names[name] then
                counted_names[name] = true
                count = count + 1
            end
        end
    end

    return count
end

--- Returns whether an item places one of the given entity types.
---@param prototype table Item prototype to inspect
---@param entity_types string[] Entity prototype types
---@return boolean
local function places_entity_type(prototype, entity_types)
    local place_result = prototype.place_result
    if not place_result then return false end

    for _, type_name in pairs(entity_types) do
        if data.raw[type_name] and data.raw[type_name][place_result] then
            return true
        end
    end

    return false
end

--- Counts the number of visible entries in this subgroup.
--- Hidden prototypes and Factoriopedia-hidden prototypes are ignored.
--- Prototypes with duplicate internal names are only counted once.
---@return integer? count
function ItemSubgroup:count_visible_entries()
    if self:is_valid('item-subgroup') then
        return count_visible_subgroup_entries(self.name)
    end
end
ItemSubgroup.get_visible_entry_count = ItemSubgroup.count_visible_entries

--- Counts the number of visible rows used by this subgroup.
--- Returns zero if the subgroup contains no visible entries.
--- Returns one for 1-10 visible entries, two for 11-20 visible entries, etc.
---@return integer? rows
function ItemSubgroup:count_rows()
    if self:is_valid('item-subgroup') then
        local count = self:count_visible_entries()
        ---@cast count integer

        if count <= 0 then
            return 0
        end

        return math.ceil(count / 10)
    end
end
ItemSubgroup.get_row_count = ItemSubgroup.count_rows
ItemSubgroup.count_subgroup_rows = ItemSubgroup.count_rows

--- Counts visible items in this subgroup that place one of the given entity types.
---@param entity_types string[] Entity prototype types
---@return integer? count
function ItemSubgroup:count_placeable_entries(entity_types)
    if self:is_valid('item-subgroup') then
        local count = 0
        local counted_names = {}

        for _, type_name in pairs(Groups.item) do
            for name, prototype in pairs(data.raw[type_name] or {}) do
                if prototype.subgroup == self.name
                    and not is_hidden(prototype)
                    and not counted_names[name]
                    and places_entity_type(prototype, entity_types)
                then
                    counted_names[name] = true
                    count = count + 1
                end
            end
        end

        return count
    end
end

--- Counts rows used by visible items that place one of the given entity types.
---@param entity_types string[] Entity prototype types
---@return integer? rows
function ItemSubgroup:count_placeable_rows(entity_types)
    if self:is_valid('item-subgroup') then
        local count = self:count_placeable_entries(entity_types)
        ---@cast count integer

        if count <= 0 then
            return 0
        end

        return math.ceil(count / 10)
    end
end

return ItemSubgroup
