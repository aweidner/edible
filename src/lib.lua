-- Contains utility functions or other dependencies that are used
-- throughout the code base

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


    if comparator(argument_to_comparator) > 0 then
        return find_recursive(array, comparator, midpoint + 1, last, index_to_comparator)
    elseif comparator(argument_to_comparator) < 0 then
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
    if value <= extractor(array[1]) then
        return 1
    end

    -- Special case for when we need to insert this element at the end of the list
    if value >= extractor(array[#array]) then
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
        if value_at_left_index <= value and value <= value_at_current_index then
            return 0
        elseif value_at_current_index > value then
            return -1
        elseif value_at_current_index < value then
            return 1
        end
    end, 1, #array, true)
end

local function l_comprehend(values, transformer)
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
    l_comprehend = l_comprehend,
    NIL = {}
}
