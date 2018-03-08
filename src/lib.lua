-- Contains utility functions or other dependencies that are used
-- throughout the code base

-- Comparison functions to implement a total ordering over non-traditional
-- data.  Primarily to support composite keys for indexes and temporary
-- tables.
local function lt(a, b)
    -- math.huge is supported as a cap within other parts
    -- of the application.  In order to support maintaining a
    -- total ordering, it's convenient to make it a cap here.
    --
    -- Every value is less than math.huge and no value is
    -- less than -math.huge.  This includes values of other types
    -- like strings or tables (even nil is not less than -math.huge).
    if a == math.huge or b == -math.huge then
        return false
    elseif a == -math.huge or b == math.huge then
        return true
    end

    -- We can only compare values of the same type obviously
    assert(type(a) == type(b))

    -- This gets a little complicated, what are the criteria to
    -- say if one table is less than another?  For the purposes of
    -- these comparisons, only the table valiant of a table is supported.
    if type(a) == "table" then

        -- Iterate over only the shorter of the two tables
        local shorter = a;
        if #b < #a then
            shorter = b
        end

        for index, _ in ipairs(shorter) do
            -- Both have to be of the same type in order to be comparable
            assert(type(a[index]) == type(b[index]))

            -- What we're looking for here is a clear differentiator.
            -- to say that one is less than the other.
            if a[index] < b[index] then
                return true
            elseif a[index] > b[index] then
                return false
            end
        end

        -- Everything was equal, the shorter of the two is the
        -- "lesser"
        return #a < #b
    end

    -- If we're not comparing a table, there's no magic.
    -- Just do the direct comparison
    return a < b
end

local function eq(a, b)
    -- The reason this assertion has to come first is because
    -- we have to know if both a and b are tables
    if type(a) ~= type(b) then
        return false
    end

    -- These are both tables, we can compare them evenly
    if type(a) == "table" then

        -- If they are not the same length, they are obviously inequal
        if #a ~= #b then
            return false
        end

        -- If any of their contents are unequal, they are unequal
        for index, _ in ipairs(a) do
            if a[index] ~= b[index] then
                return false
            end
        end

        -- These two are equal
        return true
    end
    return a == b
end

-- All other comparisons are done in terms of equals and lt
local function gt(a, b)
    return not (eq(a, b) or lt(a, b))
end

local function lte(a, b)
    return lt(a, b) or eq(a, b)
end

local function gte(a, b)
    return gt(a, b) or eq(a, b)
end

local function find_recursive(array, comparator, first, last, index_to_comparator)
    -- Do a recursive binary search.  At each point in the search the
    -- comparator is called.  The comparator should return one of
    --      * a negative number, indicating the value is in the lower part of
    --        the array
    --      * a positive number, indicating the value is in the upper part of
    --        the array
    --      * zero, indicating the number is at this position
    --
    --  Arguments:
    --      * array - The array to search through, expected to be sorted
    --      * comparator - The function to use to compare elements
    --      * first - The index in the list to start the search
    --      * last - The last index allowable in the search
    --      * index_to_comparator - If true send the index of the
    --          current comparison value instead of the value itself
    if first > last then
        return -1
    end

    local midpoint = math.floor((first + last) / 2)

    local argument_to_comparator = midpoint
    if not index_to_comparator then
        argument_to_comparator = array[midpoint]
    end

    local comparison_result = comparator(argument_to_comparator)

    if comparison_result > 0 then
        return find_recursive(array, comparator, midpoint + 1, last, index_to_comparator)
    elseif comparison_result < 0 then
        return find_recursive(array, comparator, first, midpoint - 1, index_to_comparator)
    else
        return midpoint
    end
end

local function bisect(array, value, extractor)
    -- Implements bisect left, an algorithm to find the index
    -- to insert a value to keep the array in sorted order
    --
    -- Arguments:
    --      * array - Array to search through, expected to be sorted
    --      * value - The value to insert into the array
    --      * extractor - Optional.  If extractor is defined it must be a
    --          function.  Extractor will be called with each element of
    --          the array being compared.  It should return the value to
    --          compare against

    extractor = extractor or function(x) return x end

    -- Special case for empty arrays, insert at position 1
    if #array == 0 then
        return 1
    end

    -- Special case for when we need to insert this element at the end of the list
    if lte(value, extractor(array[1])) then
        return 1
    end

    -- Special case for when we need to insert this element at the end of the list
    if gte(value, extractor(array[#array])) then
        return #array + 1
    end

    -- The special cases above are there to correct some deficiencies in
    -- binary search.  If we are searching in an array it will only allow us
    -- to compare within indicies in the array.  Technically we also want to
    -- compare on the extreme ends (positions not actually in the array) to see
    -- if values are supposed to be inserted there.  Since we can't do that with
    -- a conventional search, take care of the caps by special case.
    return find_recursive(array, function(comparison_index)
        local value_at_current_index = extractor(array[comparison_index])

        -- This is for convenience, we say that the left end of the
        -- array is always bounded by negative infinity.  If the left
        -- index is still "within" the array, then we can retrieve the
        -- actual left value
        local value_at_left_index = -math.huge
        if comparison_index - 1 > 0 then
            value_at_left_index = extractor(array[comparison_index - 1])
        end

        -- In order for this to be the correct position, the value we are attempting
        -- to insert must be between the current and left indicies.  It will then
        -- be inserted on the LEFT of the current index
        --
        -- If it is not between the current and left indicies than we need to keep
        -- searching, we therefore do the normal binary search operations
        if lte(value_at_left_index, value) and lte(value, value_at_current_index) then
            return 0
        elseif gt(value_at_current_index, value) then
            return -1
        elseif lt(value_at_current_index, value) then
            return 1
        else
            assert(false, "Programmer error, this condition occurs when there is not " ..
                          "a total ordering of all elements with the searched array.  " ..
                          "It indicates a deficiency in the ordering algorithms.")
        end
    end, 1, #array, true)
end

local function map(values, transformer)
    -- Map the table of values through the transformer function, producing
    -- a table of the result
    local result = {}
    for _, v in pairs(values) do
        table.insert(result, transformer(v))
    end

    return result
end

return {
    sum = function(iterator)
        -- Sum the contents of the iterator and return the total
        local total = 0
        for v in iterator do
            total = total + v
        end
        return total
    end,

    find = function(array, comparator, index_to_comparator)
        return find_recursive(
            array, comparator, 1,
            #array, index_to_comparator)
    end,

    bisect = bisect,
    map = map,
    -- Special NIL value to use in place of actual NIL.  Tables
    -- cannot contain the actual nil value, so use this as a
    -- substitute
    NIL = {},
    -- Expose operators in case they need to be used elsewhere
    lt = lt, gt = gt, gte = gte, lte = lte, eq = eq
}
