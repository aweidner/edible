local find = require("lib").find

describe("Binary Search", function()
  it('should return -1 when an empty array is searched', function()
    local array = {}
    assert.equal(-1, find(array, function(v) return 6 - v end))
  end)

  it('should be able to find a value in a single element array with one access', function()
    local array = { 6 }
    assert.equal(1, find(array, function(v) return 6 - v end))
  end)

  it('should return -1 if a value is less than the element in a single element array', function()
    local array = { 94 }
    assert.equal(-1, find(array, function(v) return 6 - v end))
  end)

  it('should return -1 if a value is greater than the element in a single element array', function()
    local array = { 94 }
    assert.equal(-1, find(array, function(v) return 602 - v end))
  end)

  it('should find an element in a longer array in less than log(n) accesses', function()
    local array = { 6, 67, 123, 345, 456, 457, 490, 2002, 54321, 54322 }
    assert.equal(8, find(array, function(v) return 2002 - v end))
  end)

  it('should find elements at the beginning of an array in less than log(n) accesses', function()
    local array = { 6, 67, 123, 345, 456, 457, 490, 2002, 54321, 54322 }
    assert.equal(1, find(array, function(v) return 6 - v end))
  end)

  it('should find elements at the end of an array in less than log(n) accesses', function()
    local array = { 6, 67, 123, 345, 456, 457, 490, 2002, 54321, 54322 }
    assert.equal(10, find(array, function(v) return 54322 - v end))
  end)

  it('should return -1 if a value is less than all elements in a long array', function()
    local array = { 6, 67, 123, 345, 456, 457, 490, 2002, 54321, 54322 }
    assert.equal(-1, find(array, function(v) return 2 - v end))
  end)

  it('should return -1 if a value is greater than all elements in a long array', function()
    local array = { 6, 67, 123, 345, 456, 457, 490, 2002, 54321, 54322 }
    assert.equal(-1, find(array, function(v) return 54323 - v end))
  end)

end)
