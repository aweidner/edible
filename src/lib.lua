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
    -- Implements bisect right, an algorithm to find the index
    -- to insert a value to keep the array in sorted order
    --
    -- Arguments:
    --      * array - Array to search through, expected to be sorted
    --      * value - The value to insert into the array
    --      * extractor - Optional.  If extractor is defined it must be a
    --          function.  Extractor will be called with each element of
    --          the array being compared.  It should return the value to
    --          compare against

    -- Special case for bisect right: If we need to insert before the first
    -- element then handle it here

    extractor = extractor or function(x) return x end

    if #array == 0 or value < extractor(array[1]) then
        return 1
    end

    -- Perform a binary search with a special comparator.  The comparator
    -- compares the left and right values in the array against the value
    -- we are searching for.
    --
    -- If both left and right are less than the current value then we need
    -- to go more rightward (greater values)
    --
    -- If both left and right are greater than the current value than we
    -- need to go more leftward (lesser values)
    --
    -- When we hit a middle point then we have found the position to insert.
    -- Because this is bisect right, we add one to the resulting index to
    -- get the insert position usable by table.insert
    return find_recursive(array, function(comparison_index)
        local left = comparison_index - 1
        local right = comparison_index + 1

        if left < 1 or right > #array then
            return 0
        elseif extractor(array[left]) < value and extractor(array[right]) < value then
            return 1
        elseif extractor(array[left]) > value and extractor(array[right]) > value then
            return -1
        else
            return 0
        end
    end, 1, #array, true) + 1
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

    bisect = bisect
}
