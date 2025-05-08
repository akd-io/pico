--[[
  Testing library
  Basically a port of https://bun.sh/docs/test/writing

  TODOs:
  - Implenent
]]

local groups = {}

local stack = {}

---describe() is a function that groups related tests together.
---
---@param groupDescription string
---@param callback function
function describe(groupDescription, callback)
  local group = {
    type = "group",
    description = groupDescription,
  }
  add(stack, group)
  callback()
  deli(stack, #stack)
end

---test() is a function that defines a single test.
---
---A simple example:
---```lua
---test("2 + 2", () => {
---  expect(2 + 2).toBe(4);
---});
---```
---
---@param testDescription string
---@param callback function
function test(testDescription, callback)
  add(tests, callback)
end

function beforeEach(callback)
  error("Implement")
end

function beforeAll(callback)
  error("Implement")
end

function expect(actual)
  local function toBe(expected)
    --- shallow equals
    if actual ~= expected then
      error("Expected " .. actual .. " to be " .. expected)
    end
  end

  local function toEqual(expected)
    -- deep equals
    error("Implement")
  end

  return {
    toBe = toBe,
    toEqual = toEqual
  }
end
