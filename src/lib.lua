-- Contains utility functions or other dependencies that are used
-- throughout the code base

local function find_recursive(array, comparator, first, last)
    -- Do a recursive binary search.  At each point in the search the
    -- comparator is called.  The comparator should return one of
    --      * a negative number, indicating the value is in the lower part of
    --        the array
    --      * a positive number, indicating the value is in the upper part of
    --        the array
    --      * zero, indicating the number is at this position
    if first > last then
        return -1
    end

    local midpoint = math.floor((first + last) / 2)

    if comparator(array[midpoint]) > 0 then
        return find_recursive(array, comparator, midpoint + 1, last)
    elseif comparator(array[midpoint]) < 0 then
        return find_recursive(array, comparator, first, midpoint - 1)
    else
        return midpoint
    end
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

    find = function(array, comparator)
        return find_recursive(array, comparator, 1, #array)
    end
}
