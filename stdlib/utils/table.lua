--- Extensions to Lua's standard `table` library.
---@class StdLib.Utils.Table
---@see table
---@usage local table = require('__kry_stdlib__/stdlib/utils/table') --[[@as StdLib.Utils.Table]]
local Table = {}

Table.remove = table.remove
Table.sort = table.sort
Table.pack = table.pack
Table.unpack = table.unpack
Table.insert = table.insert
Table.concat = table.concat

-- Import base lua table into Table
for k, v in pairs(table) do if not Table[k] then Table[k] = v end end

--- Given a mapping function, creates a transformed copy of the table
--- by calling the function for each element and using the result as the new value for the key.
--- Passes the index as the second argument to the function.
---@usage local a = {1, 2, 3, 4, 5}
--- table.map(a, function(v) return v * 10 end) -- {10, 20, 30, 40, 50}
---@usage local a = {1, 2, 3, 4, 5}
--- table.map(a, function(v, k, x) return v * k + x end, 100) -- {101, 104, 109, 116, 125}
---@param tbl table
---@param func function
---@param ... any
---@return table
function Table.map(tbl, func, ...)
    local new_tbl = {}
    for k, v in pairs(tbl) do new_tbl[k] = func(v, k, ...) end
    return new_tbl
end

--- Given a filter function, creates a filtered copy of the table
--- by calling the function for each element and removing entries for which it returns false.
--- Passes the index as the second argument to the function.
---@usage local a = {1, 2, 3, 4, 5}
--- table.filter(a, function(v) return v % 2 == 0 end) -- {2, 4}
---@usage local a = {1, 2, 3, 4, 5}
--- table.filter(a, function(v, k) return k % 2 == 1 end) -- {1, 3, 5}
---@param tbl table
---@param func function
---@param ... any
---@return table
function Table.filter(tbl, func, ...)
    local new_tbl = {}
    local add = #tbl > 0
    for k, v in pairs(tbl) do
        if func(v, k, ...) then
            if add then
                Table.insert(new_tbl, v)
            else
                new_tbl[k] = v
            end
        end
    end
    return new_tbl
end

--- Searches a table and returns the first value for which the search function returns true.
--- Passes the index as the second argument to the function.
---@usage local a = {1, 2, 3, 4, 5}
--- table.find(a, function(v) return v % 2 == 0 end) -- 2, 2
---@usage local a = {1, 2, 3, 4, 5}
--- table.find(a, function(v, k) return k % 2 == 1 end) -- 1, 1
---@param tbl table
---@param func function
---@param ... any
---@return any? value The first matching value.
---@return any? key The key of the first matching value.
function Table.find(tbl, func, ...)
    for k, v in pairs(tbl) do if func(v, k, ...) then return v, k end end
    return nil,nil
end

--- Returns true if the search function returns true for any element in the table.
--- Passes the index as the second argument to the function.
---@see StdLib.Utils.Table.find
---@usage local a = {1, 2, 3, 4, 5}
--- table.any(a, function(v) return v % 2 == 0 end) -- true
---@usage local a = {1, 2, 3, 4, 5}
--- table.any(a, function(v, k) return k % 2 == 1 end) -- true
---@param tbl table
---@param func function
---@param ... any
---@return boolean
function Table.any(tbl, func, ...)
    return Table.find(tbl, func, ...) ~= nil
end

--- Returns true if the search function returns true for every element in the table.
--- Passes the index as the second argument to the function.
---@param tbl table
---@param func function
---@param ... any
---@return boolean
function Table.all(tbl, func, ...)
    for k, v in pairs(tbl) do if not func(v, k, ...) then return false end end
    return true
end

--- Applies a function to each element in the table.
--- Passes the index as the second argument to the function.
--- Iteration stops if the function returns true for any element.
---@usage local a = {10, 20, 30, 40}
--- table.each(a, function(v) game.print(v) end) -- prints 10, 20, 30, 40
---@param tbl table
---@param func function
---@param ... any
---@return table tbl The original table.
function Table.each(tbl, func, ...)
    for k, v in pairs(tbl) do if func(v, k, ...) then break end end
    return tbl
end

--- Returns true if the unkeyed array contains the given value.
---@param tbl any[] The array to search.
---@param value any The value to find.
---@return boolean
function Table.contains(tbl, value)
    assert(type(tbl) == "table", "Expected first argument to be a table")
    return util.contains_value(tbl, value)
end

--- Returns a recursively flattened copy of an array.
--- Nested arrays are expanded into the resulting one-dimensional array.
--- If `level` is supplied, recursion is limited to that many levels.
--- Only integer-indexed arrays are flattened; associative tables are preserved.
---@param tbl any[] The array to flatten.
---@param level? uint Maximum recursion depth.
---@return any[] flattened
function Table.flatten(tbl, level)
    local flattened = {}
    Table.each(tbl, function(value)
        if type(value) == 'table' and #value > 0 then
            if level then
                if level > 0 then
                    Table.merge(flattened, Table.flatten(value, level - 1), true)
                else
                    Table.insert(flattened, value)
                end
            else
                Table.merge(flattened, Table.flatten(value), true)
            end
        else
            Table.insert(flattened, value)
        end
    end)
    return flattened
end

--- Returns the first element of an array, or nil if the array is empty.
---@param tbl any[]
---@return any? value
function Table.first(tbl)
    return tbl[1]
end

--- Returns the last element of an array, or nil if the array is empty.
---@param tbl any[]
---@return any? value
function Table.last(tbl)
    local size = #tbl
    if size == 0 then return nil end
    return tbl[size]
end

--- Returns the smallest numeric value in an array, or nil if the array is empty.
---@param tbl number[]
---@return number? minimum
function Table.min(tbl)
    if #tbl == 0 then return nil end

    local min = tbl[1]
    for _, num in pairs(tbl) do min = num < min and num or min end
    return min
end

--- Returns the largest numeric value in an array, or nil if the array is empty.
---@param tbl number[]
---@return number? maximum
function Table.max(tbl)
    if #tbl == 0 then return nil end

    local max = tbl[1]
    for _, num in pairs(tbl) do max = num > max and num or max end
    return max
end

--- Returns the sum of all numeric values in an array.
--- Returns 0 for an empty array.
---@param tbl number[]
---@return number sum
function Table.sum(tbl)
    local sum = 0
    for _, num in pairs(tbl) do sum = sum + num end
    return sum
end

--- Returns the average of all numeric values in an array, or nil if the array is empty.
---@param tbl number[]
---@return number? average
function Table.avg(tbl)
    local cnt = #tbl
    return cnt ~= 0 and Table.sum(tbl) / cnt or nil
end

--- Returns a new array containing a slice of the given array.
---@param tbl any[] The array to slice.
---@param start? integer Starting index. Defaults to 1.
---@param stop? integer Ending index. Negative values count backwards from the end.
---@return any[] slice
---@usage local a = {10, 20, 30, 40, 50}
--- table.slice(a, 2, -2) -- {20, 30, 40}
function Table.slice(tbl, start, stop)
    local res = {}
    local n = #tbl

    start = start or 1
    stop = stop or n
    stop = stop < 0 and (n + stop + 1) or stop

    if start < 1 or start > n then return {} end

    local k = 1
    for i = start, stop do
        res[k] = tbl[i]
        k = k + 1
    end
    return res
end

--- Merges two tables, with values from the second table overwriting values from the first.
--- When `array_merge` is true, values from the second table are appended instead.
---@usage local args = table.merge({option1 = false}, {option1 = true})
---@param tblA table The destination table.
---@param tblB? table The table to merge into `tblA`.
---@param array_merge? boolean Append values instead of merging by key.
---@param raw? boolean Use `rawset` when merging associative tables.
---@return table tblA The merged destination table.
function Table.merge(tblA, tblB, array_merge, raw)
    if not tblB then return tblA end
    if array_merge then
        for _, v in pairs(tblB) do Table.insert(tblA, v) end
    else
        for k, v in pairs(tblB) do
            if raw then
                rawset(tblA, k, v)
            else
                tblA[k] = v
            end
        end
    end
    return tblA
end

--- Combines the values from multiple arrays into a new array.
---@param ... table Arrays to combine.
---@return any[] combined
function Table.array_combine(...)
    local tables = { ... }
    local new = {}
    for _, tab in pairs(tables) do for _, v in pairs(tab) do Table.insert(new, v) end end
    return new
end

--- Combines multiple dictionaries into a new table.
--- Later tables overwrite values from earlier tables with the same key.
---@param ... table Dictionaries to combine.
---@return table combined
function Table.dictionary_combine(...)
    local tables = { ... }
    local new = {}
    for _, tab in pairs(tables) do for k, v in pairs(tab) do new[k] = v end end
    return new
end

--- Creates a merged dictionary without overwriting values already present in the first table.
---@usage local a = {one = "A"}
--- local b = {one = "Z", two = "B"}
--- local merged = table.dictionary_merge(a, b) -- {one = "A", two = "B"}
---@param tbl_a table
---@param tbl_b table
---@return table merged
function Table.dictionary_merge(tbl_a, tbl_b)
    local meta_a = getmetatable(tbl_a)
    local meta_b = getmetatable(tbl_b)
    setmetatable(tbl_a, nil)
    setmetatable(tbl_b, nil)

    local new_t = {}
    for k, v in pairs(tbl_a) do new_t[k] = v end
    for k, v in pairs(tbl_b or {}) do if not new_t[k] then new_t[k] = v end end
    setmetatable(tbl_a, meta_a)
    setmetatable(tbl_b, meta_b)
    return new_t
end

--- Recursively compares two values for equality.
--- Table contents are compared recursively.
--- Based on Factorio's `util.lua` implementation and work by Sparr, Nexela, and luacode.org.
---@param t1 any
---@param t2 any
---@param ignore_mt? boolean Ignore the `__eq` metamethod.
---@return boolean
-- @author Sparr, Nexela, luacode.org
function Table.deep_compare(t1, t2, ignore_mt)
    local ty1, ty2 = type(t1), type(t2)
    if ty1 ~= ty2 then return false end
    -- non-table types can be directly compared
    if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
    -- as well as tables which have the metamethod __eq
    if not ignore_mt then
        local mt = getmetatable(t1)
        if mt and mt.__eq then return t1 == t2 end
    end
    for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not Table.deep_compare(v1, v2) then return false end
    end
    for k in pairs(t2) do if t1[k] == nil then return false end end
    return true
end
Table.compare = Table.deep_compare

--- Creates a deep copy of a value without copying Factorio objects.
---@generic T
---@param object T The value to copy.
---@return T copy
---@usage local copy = table.deep_copy(data.raw["stone-furnace"]["stone-furnace"])
function Table.deep_copy(object)
    local lookup_table = {}

    local function _copy(inner)
        if type(inner) ~= 'table' then
            return inner
        elseif inner.__self then
            return inner
        elseif lookup_table[inner] then
            return lookup_table[inner]
        end
        local new_table = {}
        lookup_table[inner] = new_table
        for index, value in pairs(inner) do new_table[_copy(index)] = _copy(value) end
        return setmetatable(new_table, getmetatable(inner))
    end

    return _copy(object)
end
Table.deepcopy = Table.deep_copy

--- Creates a deep copy without preserving shared internal table references.
--- Repeated references to the same nested table are copied independently.
---@generic T
---@param object T The value to copy.
---@return T copy
---@usage local copy = table.full_copy(data.raw["stone-furnace"]["stone-furnace"])
function Table.full_copy(object)
    local lookup_table = {}

    local function _copy(inner)
        if type(inner) ~= 'table' then
            return inner
        elseif inner.__self then
            return inner
        elseif lookup_table[inner] then
            return _copy(lookup_table[inner])
        end
        local new_table = {}
        lookup_table[inner] = new_table
        for index, value in pairs(inner) do new_table[_copy(index)] = _copy(value) end
        return setmetatable(new_table, getmetatable(inner))
    end

    return _copy(object)
end
Table.fullcopy = Table.full_copy

--- Creates a flexible deep copy of a value.
--- Tables implementing `_copy_with` may provide their own copy behavior.
---@generic T
---@param object T The value to copy.
---@return T copy
---@usage local copy = table.flex_copy(data.raw["stone-furnace"]["stone-furnace"])
function Table.flex_copy(object)
    local lookup_table = {}

    local function _copy(inner)
        if type(inner) ~= 'table' then
            return inner
        elseif inner.__self then
            return inner
        elseif lookup_table[inner] then
            return lookup_table[inner]
        elseif type(inner._copy_with) == 'function' then
            lookup_table[inner] = inner:_copy_with(_copy)
            return lookup_table[inner]
        end
        local new_table = {}
        lookup_table[inner] = new_table
        for index, value in pairs(inner) do new_table[_copy(index)] = _copy(value) end
        return setmetatable(new_table, getmetatable(inner))
    end

    return _copy(object)
end
Table.flexcopy = Table.flex_copy

--- Returns an array containing all values from a table.
---@param tbl? table The table whose values will be copied.
---@param sorted? boolean Sort the resulting array.
---@param as_string? boolean Convert values to strings.
---@return any[] values
function Table.values(tbl, sorted, as_string)
    if not tbl then return {} end
    local value_set = {}
    local n = 0
    if as_string then -- checking as_string /before/ looping is faster
        for _, v in pairs(tbl) do
            n = n + 1
            value_set[n] = tostring(v)
        end
    else
        for _, v in pairs(tbl) do
            n = n + 1
            value_set[n] = v
        end
    end
    if sorted then
        table.sort(value_set, function(x, y) -- sorts tables with mixed index types.
            local tx = type(x) == 'number'
            local ty = type(y) == 'number'
            if tx == ty then
                return x < y and true or false -- similar type can be compared
            elseif tx == true then
                return true -- only x is a number and goes first
            else
                return false -- only y is a number and goes first
            end
        end)
    end
    return value_set
end

--- Returns an array containing all keys from a table.
---@param tbl? table The table whose keys will be copied.
---@param sorted? boolean Sort the resulting array.
---@param as_string? boolean Convert keys to strings.
---@return any[] keys
function Table.keys(tbl, sorted, as_string)
    if not tbl then return {} end
    local key_set = {}
    local n = 0
    if as_string then -- checking as_string /before/ looping is faster
        for k, _ in pairs(tbl) do
            n = n + 1
            key_set[n] = tostring(k)
        end
    else
        for k, _ in pairs(tbl) do
            n = n + 1
            key_set[n] = k
        end
    end
    if sorted then
        table.sort(key_set, function(x, y) -- sorts tables with mixed index types.
            local tx = type(x) == 'number'
            local ty = type(y) == 'number'
            if tx == ty then
                return x < y and true or false -- similar type can be compared
            elseif tx == true then
                return true -- only x is a number and goes first
            else
                return false -- only y is a number and goes first
            end
        end)
    end
    return key_set
end

--- Removes the specified keys from a table.
---@usage local a = {1, 2, 3, 4}
--- table.remove_keys(a, {1, 3}) -- {nil, 2, nil, 4}
---@usage local b = {k1 = 1, k2 = "foo", old_key = "bar"}
--- table.remove_keys(b, {"old_key"}) -- {k1 = 1, k2 = "foo"}
---@param tbl table The table to modify.
---@param keys any[] Keys to remove.
---@return table tbl The modified table.
function Table.remove_keys(tbl, keys)
    for i = 1, #keys do tbl[keys[i]] = nil end
    return tbl
end

--- Counts the keys in a table.
--- If a filter function is supplied, also returns the number of entries for which it returns true.
---@usage local a = {1, 2, 3, 4, 5}
--- table.count_keys(a) -- 5, 5
---@usage local a = {1, 2, 3, 4, 5}
--- table.count_keys(a, function(v, k) return k % 2 == 1 end) -- 3, 5
---@param tbl table
---@param func? function Optional filter function.
---@param ... any Additional arguments passed to `func`.
---@return integer count Number of matching keys.
---@return integer total Total number of keys.
function Table.count_keys(tbl, func, ...)
    local count, total = 0, 0
    if type(tbl) == 'table' then
        for k, v in pairs(tbl) do
            total = total + 1
            if func then
                if func(v, k, ...) then count = count + 1 end
            else
                count = count + 1
            end
        end
    end
    return count, total
end

--- Returns a table with its keys and values exchanged.
--- If the original values are not unique, which key is retained depends on iteration order.
---@usage local a = {k1 = "foo", k2 = "bar"}
--- table.invert(a) -- {foo = "k1", bar = "k2"}
---@param tbl table
---@return table inverted
function Table.invert(tbl)
    local inverted = {}
    for k, v in pairs(tbl) do inverted[v] = k end
    return inverted
end

---@param tbl? table
---@return integer
local function _size(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do count = count + 1 end
    return count
end

--- Returns the number of entries in a table, using Factorio's `table_size` when available.
---@type fun(tbl: table): integer
Table.size = _ENV.table_size or _size

--- Converts an array into a dictionary.
--- String and numeric array values become keys whose values are either the original value or `true`.
--- If the input is already a dictionary, it is returned unchanged.
---@usage local a = {"v1", "v2"}
--- table.array_to_dictionary(a) -- {v1 = "v1", v2 = "v2"}
---@usage local a = {"v1", "v2"}
--- table.array_to_dictionary(a, true) -- {v1 = true, v2 = true}
---@param tbl table
---@param as_bool? boolean Map each key to `true` instead of its original value.
---@return table
function Table.array_to_dictionary(tbl, as_bool)
    if Table.is_array(tbl) then
        local new_tbl = {}
        for _, v in ipairs(tbl) do
            if type(v) == "string" or type(v) == "number" then
                new_tbl[v] = as_bool and true or v
            end
        end
        return new_tbl
    else
        return tbl
    end
end

--- Returns an array containing the unique values from a table.
---@param tbl table
---@return any[] values
function Table.unique_values(tbl)
    return Table.keys(Table.invert(tbl))
end

--- Returns true if the table contains no entries.
---@param tbl table
---@return boolean
function Table.is_empty(tbl)
    return _ENV.table_size and _ENV.table_size(tbl) == 0 or next(tbl) == nil
end

--- Removes all entries from a table.
---@param tbl table The table to clear.
---@return table tbl The cleared table.
function Table.clear(tbl)
    for k in pairs(tbl) do tbl[k] = nil end
    return tbl
end

--- Inserts a string before the first occurrence of another string.
--- If `before` is not found, the new value is appended to the array.
---@param tbl string[] The array to modify.
---@param before string The value before which the new string will be inserted.
---@param value string The string to insert.
---@return string[] tbl The modified array.
function Table.insert_string(tbl, before, value)
    assert(type(before) == "string", "Expected second argument to be a string")
    assert(type(value) == "string", "Expected third argument to be a string")

    for i, v in ipairs(tbl) do
        if v == before then
            table.insert(tbl, i, value)
            return tbl
        end
    end
    table.insert(tbl, value)
    return tbl
end

--- Removes the first occurrence of a string from an array.
--- If the string is not found, the array is returned unchanged.
---@param tbl string[] The array to modify.
---@param target string The string to remove.
---@return string[] tbl The modified array.
function Table.remove_string(tbl, target)
    assert(type(target) == "string", "Expected second argument to be a string")

	for i, v in ipairs(tbl) do
		if v == target then
			table.remove(tbl, i)
			return tbl
		end
	end
	return tbl
end

--- Scales a number or all numeric values contained in a table.
--- Tables are deep-copied before their numeric values are scaled recursively.
---@param object number|table The number or table to scale.
---@param scale number The scale factor.
---@return number|table scaled
function Table.scale(object, scale)
    ---@param obj table
    ---@param factor number
    local function scale_subtable(obj, factor)
        for k, v in pairs(obj) do
            if type(v) == "table" then
                scale_subtable(v, factor)
            elseif type(v) == "number" then
                obj[k] = v * factor
            end
        end
    end

    -- Check if object is a number
    if type(object) == "number" then
        return object * scale
    -- Else object is a table
    else
        -- Break reference, work on local copy
        object = table.deepcopy(object)
        -- Recursively call scale_subtable
        scale_subtable(object, scale)
        return object
    end
end

--- Returns true if the value is a simple array with sequential integer keys starting at 1.
--- For example, `{"a", "b", "c"}` is valid, while `{value1 = "a"}` or `{[1] = "a", [3] = "b"}` are not.
---@param tbl any
---@return boolean
function Table.is_array(tbl)
    if type(tbl) ~= "table" then return false end
    local n = #tbl
    for k in pairs(tbl) do
        if type(k) ~= "number" or k < 1 or k > n or k % 1 ~= 0 then
            return false
        end
    end
    return true
end

return Table
