return {
    sum = function(iterator)
        local total = 0
        for v in iterator do
            total = total + v
        end
        return total
    end
}
