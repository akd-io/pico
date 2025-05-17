include("./react.lua")
include("/lib/describe.lua")

local renderFunctionRan = false

local renderFunction = function(a, b)
  renderFunctionRan = true
end

local Component = component("MyComponent", renderFunction)

local element = Component(1, 2)

assert(element[1] == renderFunction, "First element should be the render function")
assert(element[2] == 1, "Second element should be the first argument")
assert(element[3] == 2, "Third element should be the second argument")
assert(not renderFunctionRan, "Render function should not have been called")

print("Element successfully created:")
print(describe(element))
