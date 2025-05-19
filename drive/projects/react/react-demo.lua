--local React = include("bbs://react64-1.p64/main.lua") -- ✅ Include normally to keep it
--                                                      --    under a `React` namespace.
include("bbs://react64-1.p64/main.lua")() -- ✅ Or add an extra pair of parentheses, `()`,
--                                        --    to add all react functions to the global scope.

window(100, 100)

local Print = component("Print", function(text)
  print(text) -- ✅ Run draw operations at the top level of the render function.
end)

local Counter = component("Counter", function(label, btnCode)
  local count, setCount = useState(0) -- ✅ Handle state with `useState`.

  if (btnp(btnCode)) then
    --counter += 1              -- ❌ Don't mutate state directly.
    count = setCount(count + 1) -- ✅ Set `count` using `setCount` to update
    --                          --    both the local `count` variable and
    --                          --    the internal state value (using `setCount`)
    --                          --    to persist it to next render.
  end

  return Fragment( -- ✅ Return components to build a component tree.
    Print(label),  -- ✅ Call components with arguments to pass props.
    Print(count)
  )
end)

local App = component("App", function()
  cls()                   -- ✅ Run draw operations at the top level of the render function.

  return Fragment(        -- ✅ Return components to build a component tree.
    Counter("Left: ", 0), -- ✅ Call components with arguments to pass props.
    Counter("Right: ", 1),
    Counter("Up: ", 2),
    Counter("Down: ", 3)
  )
end)

function _draw()
  renderRoot(App) -- ✅ Render the root component every frame.
end
