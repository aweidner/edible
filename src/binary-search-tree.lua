local BinarySearchTree = {}

function BinarySearchTree:new(root)
    local new_tree = {value = root, left = nil, right = nil}
    setmetatable(new_tree, self)
    self.__index = self
    return new_tree
end

function BinarySearchTree:from_list(values)
    assert(values and #values > 0)
    local root = BinarySearchTree:new(values[1])

    for i = 2, #values do
        root:insert(values[i])
    end

    return root
end

function BinarySearchTree:insert_or_new(side, value)
    -- Eliminate some duplication for checking if the side
    -- is nil or not
    if side then
        side:insert(value)
        return side
    end
    return BinarySearchTree:new(value)
end

function BinarySearchTree:insert(value)
    if value > self.value then
        self.right = self:insert_or_new(self.right, value)
    else
        self.left = self:insert_or_new(self.left, value)
    end
end

function BinarySearchTree:yield_from_side(side)
    -- Eliminate some duplication for checking if the side
    -- is nil, debatable if this is warranted or if it should
    -- be inlined
    return coroutine.wrap(function()
        if side then
            for v in side:values() do
                coroutine.yield(v)
            end
        end
    end)
end

function BinarySearchTree:values()
    return coroutine.wrap(function()
        -- Really wishing for `yield from` here
        for v in self:yield_from_side(self.left) do
            coroutine.yield(v)
        end
        coroutine.yield(self.value)
        for v in self:yield_from_side(self.right) do
            coroutine.yield(v)
        end
    end)
end

return BinarySearchTree
