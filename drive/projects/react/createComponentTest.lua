include("./react.lua")

local renderFunction = function(a, b)
  -- noop component
end

local Component = createComponent(renderFunction)

local element = Component(1, 2)

assert(element[1] == renderFunction, "First element should be the render function")
assert(element[2] == 1, "Second element should be the first argument")
assert(element[3] == 2, "Third element should be the second argument")

print("All tests passed!")
