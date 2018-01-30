local function find_recursive(array, comparator, first, last)
    if first > last then
        return -1
    end

    local midpoint = math.floor((first + last) / 2)

    if comparator(array[midpoint]) < 0 then
        return find_recursive(array, comparator, midpoint + 1, last)
    elseif comparator(array[midpoint]) > 0 then
        return find_recursive(array, comparator, first, midpoint - 1)
    else
        return midpoint
    end
end

return {
    sum = function(iterator)
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
