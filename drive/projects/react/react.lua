--[[
  React.p8
  This library tries to implement the most relevant features of the React.js library for Picotron.
  See the original library here: https://react.dev/
  Note that regular rules of hooks apply. Check them out here: https://react.dev/reference/rules/rules-of-hooks
]]

--[[
  TODOs:
  - Should we implement component wrappings for the different drawing operations?
    (Circle, Rect, Line, Text, etc..)
    - I previously wanted to do this to provide default insets to support a kind-of react-dom experience.
      - Insets can be done third-party though, evident from the `Pane` and `ScrollablePane` components I've experimented with i #explore.
    - They would be a bit nicer to use than `Wrap(func, ...args)` is atm.
    - Would be a nice way to teach clients not to call arbitrary function in the component return element syntax.
  - Benchmark library
  - Consider refactoring `instances` to be a tree to prevent instance ids from ballooning in size using up memory.
  - Enhance error handling.
    - Send error to both printh and picotron log? `send_message(3, {event="report_error", content = "Error message goes here."})`
    - Print the component stack trace when an error occurs.
      - See if we can use `debug` to get actual file#line locations of component definitions.
  - Profiler? https://react.dev/reference/react/
    - Implement third party by exporting react internals as a `React.__reactInternals` property or similar?
]]

--[[
  --TODO: Merge this with later section on the same topic. It's called "Why `component`? React.js doesn't use `component`?"
  You might think; Why aren't we just calling our function components directly?
  The reason we don't call function components directly, is because that would make children render before their parents.
  Imagine the following example:

  Container(
    Header(),
    Body(
      Paragraph("Hello world"),
      Paragraph("Goodbye world")
    )
  )

  Here, the Paragraph components would run before being passed to Body.
  And Header and Body would run before being passed to Container.
  This is problematic if, for example, Body is painting a background to be displays behind the Paragraphs.
  Therefore, we use the element syntax below.

  React.js/JSX:                               Function syntax:                  Element syntax:
  <Container>                                 Container({                       { Container, {
    <Header />                                  Header(),                         { Header },
    <Body>                                      Body({                            { Body, {
      <Paragraph>Hello world</Paragraph>          Paragraph("Hello world"),         { Paragraph, "Hello world" },
      <Paragraph>Goodbye world</Paragraph>        Paragraph("Goodbye world")        { Paragraph, "Goodbye world" }
    </Body>                                     })                                }
  </Container>                                })                                }

  It is possible to implement a developer experience like the function syntax above, where we seemingly call our function components directly.
  But this would require us to declare function components using a `component()` wrapper function.
  The wrapper function would return simply return the element syntax hidden to the user.
  For now, I have chosen to embrace the simplicity and token/cpu savings of the element syntax.
]]

--[[
  JSX output example for reference:

  Input:
  <div>
    <h1>Using Context and useReducer</h1>
    {state}
    {state % 2 == 0 && <Counter />}
    {state % 2 == 1 && <Counter />}
  </div>

  Output:
  /*#__PURE__*/_jsxs(
    "div",
    {
      children: [
        /*#__PURE__*/_jsx("h1", {
          children: "Using Context and useReducer"
        }),
        state,
        state % 2 == 0 && /*#__PURE__*/_jsx(Counter, {}),
        state % 2 == 1 && /*#__PURE__*/_jsx(Counter, {})
      ]
    }
  );
]]

DEV = DEV == nil and true or DEV -- TODO: Try to put DEV onto React, so it can be set with `React.DEV = true`

-- Holds the state of component instances
local instances = {} -- TODO: Refactor into component tree?

-- TODO: Do we want to turn these into unique object references instead to minimize memory?
local COMPONENT_TYPE = "__REACT_COMPONENT"
local COMPONENT_ELEMENT_TYPE = "__REACT_COMPONENT_ELEMENT"
local CONTEXT_PROVIDER_ELEMENT_TYPE = "__REACT_PROVIDER_ELEMENT"
local KEY_ELEMENT_TYPE = "__REACT_KEY_ELEMENT"

-- Used during render
local frame = 0 -- TODO: If we end up running `renderRoot` in `_update`, rename `frame` to `updateIndex` or similar.
local currentInstanceId = nil
local currentContextValues = {}

local function getn(table)
  assert(type(table) == "table", "Expected table, got " .. type(table))
  return type(table.n) == "number" and table.n or #table
end
local function isArrayLike(table)
  if (type(table) != "table") then return false end
  if (type(table.n) == "number") then return true end
  local i = 1
  for _ in pairs(table) do
    if table[i] == nil then return false end
    i += 1
  end
  return true
end

--- # `component`
---
--- `component` creates a React component from a displayName and a render function.
---
--- The displayName is used for improved error reporting during development.
---
--- The render function is used to render the component.
---
--- ## Usage
---
--- ### Hello world
---
--- ```lua
--- local HelloWorld = component("HelloWorld", function()
---   print("Hello world!")
--- end)
--- ```
---
--- ### `Counter` example with some best practices
---
--- ```lua
--- local Print = component("Print", function(text)
---   print(text) -- ✅ Run draw operations at the top level of the render function.
--- end)
---
--- local Counter = component("Counter", function(initialCount)
---   local count, setCount = useState(initialCount) -- ✅ Handle state with `useState`
---
---   if (keyp(0)) then
---   --counter += 1                -- ❌ Don't mutate state directly
---     count = setCount(count + 1) -- ✅ Set `count` using `setCount` to update
---                                 --    both the local `count` variable and
---                                 --    the internal state value (using `setCount`)
---                                 --    to persist it to next render.
---   end
---
---   return Fragment(   -- ✅ Return components to build a component tree
---     Print("Count:"), -- ✅ Call components with arguments to pass props
---     print(count)     -- ⚠️ Be mindful when calling non-component functions in
---                      --    the return statement.
---                      --    In this example, `print` will be run before
---                      --    `Print`'s render function, which is likely
---                      --    not what you want.
---                      --    Try upper-casing `print` to fix the ordering.
---   )
--- end)
---
--- local App = component("App", function()
---   cls()            -- ✅ Run draw operations at the top level of the render function.
---
---   return Fragment( -- ✅ Return components to build a component tree
---     Counter(100)   -- ✅ Call components with arguments to pass props
---   )
--- end)
---
--- function _draw()
---   renderRoot(App())
--- end
--- ```
---
--- ## Why `component`? React.js doesn't use `component`?
---
--- TODO: Copy to docs, and replace with link.
---
--- React.js uses JSX, which is a syntax extension for JavaScript that allows you to write HTML-like code in JavaScript. In Lua, we don't have this luxury.
---
--- Now you might be thinking, sure but why not just define components using render functions, as in React.js, and then just call them in our rendering logic?
---
--- The problem with that approach is that child components will render before parent components, which is not the desired behavior.
--- `component` instead returns an element builder function that looks much like the JSX code generated using React.js.
---
--- In react.js, imagine the following JSX, `<Counter initialCount={0} />`. JSX is not JavaScript, and will throw a syntax error at runtime.
--- For this reason, a compiler will turn it into the JavaScript code `_jsx(Counter, { initialCount: 0 })`. Essentially, the `_jsx` function turns the component reference and props into a React element.
---
--- Similarly, the Lua code `local Counter = component(...)`, makes `Counter({ initialCount = 0 })` equivalent to the `_jsx(Counter, { initialCount: 0 })`.
--- That is, `Counter` becomes the element builder function for the Counter component.
---
--- All in all, we must turn render functions into elements *somehow*, to preserve rendering order.
--- `component` is relatively ergonomic, and has the added benefit of letting us set `displayName` easily.
---
--- ## Display names
---
--- TODO: Copy to docs, and replace with link.
---
--- In React.js `displayName` is either retrieved from the function using introspection, or set using `MyComponent.displayName = "MyComponent"`.
---
--- In Lua, we can't introspect functions to retrieve their names, and functions aren't objects, so we can't set properties on them.
---
--- Luckily, `component` actually returns a table that just happens to be callable thanks to the `__call` metamethod. So the `displayName` *can* be set with `MyComponent.displayName = "MyComponent"`.
---
--- But in the end, forcing users to set a `displayName`, by making it the first function argument, seems like the best solution, to ensure users get nice stack traces.
---
--- `component` will allow a `nil` `displayName` however. So in theory you can override `component` with a `component(renderFunction)` function that forwards to `component(nil, renderFunction)`.
---
--- @param displayName string The display name of the component. Often the same as the component variable's name.
--- @param renderFunction function The render function of the component.
--- @return function # The function component
local function component(displayName, renderFunction)
  -- TODO: Rename `component` to simply `component`
  if DEV then
    assert(displayName == nil or type(displayName) == "string", "displayName must be a string or nil.")
    assert(type(renderFunction) == "function", "renderFunction must be a function.")
  end

  local component = {
    type = COMPONENT_TYPE,
    displayName = displayName,
    renderFunction = renderFunction
  }
  setmetatable(component, {
    __call = function(self, ...)
      return { type = COMPONENT_ELEMENT_TYPE, self, ... }
    end
  })
  return component -- TODO: How to suppress this `return-type-mismatch` warning, or fix type?
end

local renderElement

local function renderComponentElement(componentElement, key)
  if DEV then
    -- TODO: Print component stack
    assert(type(componentElement) == "table" and componentElement.type == COMPONENT_ELEMENT_TYPE,
      "componentElement.type must be COMPONENT_ELEMENT_TYPE. Got " .. tostring(componentElement.type) .. ".")
    assert(type(key) == "string" or type(key) == "number", "key must be a string or a number")
  end

  local component = componentElement[1]
  if DEV then
    -- TODO: Print component stack
    assert(type(component) == "table" and component.type == COMPONENT_TYPE,
      "componentElement.component.type must be COMPONENT_TYPE. Got " .. tostring(component.type) .. ".")
  end

  local renderFunction = component.renderFunction
  if DEV then
    -- TODO: Print component stack
    assert(type(renderFunction) == "function",
      "componentElement.component.renderFunction must be a function. Got " .. type(renderFunction) .. ".")
  end

  -- Save parent/previous component instance and id
  local parentInstanceId = currentInstanceId

  -- Generate instance id
  -- We use tostring(component) to add the address of the component table to the instance id.
  -- This is important to support conditionals like `condition and { ComponentA } or { ComponentB }`
  local prefix = parentInstanceId and parentInstanceId .. "-" or ""
  local instanceId = prefix .. sub(tostring(component), 10) .. "_" .. key

  -- Initialize component state if missing (initial render)
  if not instances[instanceId] then
    -- TODO: Refactor into component tree?
    instances[instanceId] = { hooks = {} }
  end

  -- Update current component context
  currentInstanceId = instanceId
  instances[instanceId].hookIndex = 1
  instances[instanceId].lastRenderFrame = frame

  -- local layers = 0
  -- for w in instanceId:gmatch("%_") do
  --   layers += 1 -- TODO: Find better way to get layers.
  -- end
  -- local padding = ""
  -- for i = 1, layers do
  --   padding = padding .. "  "
  -- end
  -- printh(padding .. component.displayName .. " (" .. instanceId .. ")")

  -- Call component render function with remaining args
  local returnedElement = renderFunction(unpack(componentElement, 2))

  --printh("#returnedElement: " .. type(returnedElement) == "table" and #returnedElement or "nil")

  -- Render returned element
  renderElement(returnedElement)

  -- Restore parent component context
  currentInstanceId = parentInstanceId
end

--- `element` can be:
--- - `nil`
---   - Supported in `pack()`'ed arrays of elements.
---   - Ignored.
--- - boolean
---   - For conditional rendering in non-`pack()`'ed arrays of elements.
---   - Ignored.
--- - Component Element
---   - { Component, ..., type = COMPONENT_ELEMENT_TYPE }
--- - Keyed Element
---   - { key = string|number, <Element> }
--- - Context Provider Element
---   - { context, value, children, type = CONTEXT_PROVIDER_ELEMENT_TYPE }
--- - An array of elements
---   - { nil, true, false, <ComponentElement>, <KeyedComponentElement>, <ContextProviderElement>, ... }
renderElement = function(element, prefix, index)
  local prefix = prefix or ""
  local index = index or ""
  local prefixWithDash = prefix and prefix .. "-" or ""
  local prefixWithIndex = prefixWithDash .. index
  --[[
    I previously considered accepting elementType == "function" in the case of a propless unkeyed component, or just a function to call. Enables an API to run code after render.
    Nah, don't do this.
    - It will complicate the API.
    - It will prevent us from catching errors when users erroneously put a function in the element syntax.
    - Other solutions are okay-ish:
      - A `Wrap(function, arg1, arg2)` component that just passes `...` arg to the function works.
        - Syntax is a little weird of course. And type annotations are lost when passing parameters.
      - A series of specific wrappers for all the Picotron builtins, `Rectfill()`...
        - Solves the problems of `Wrap`.
  ]]

  local elementType = type(element)
  local isNil = elementType == "nil"
  local isBoolean = elementType == "boolean"
  local isEmptyArray = elementType == "table" and getn(element) == 0
  if isNil or isBoolean or isEmptyArray then
    return
  end

  if DEV then
    -- TODO: Print component stack
    assert(
      elementType == "table",
      "Unrecognizable element. Got element of type " .. elementType .. " but expected a table, boolean, or nil."
    )
  end

  local firstValue = element[1]
  local firstValueType = type(firstValue)

  local isContextProviderElement = element.type == CONTEXT_PROVIDER_ELEMENT_TYPE
  local isKeyElement = firstValueType == "string" or
      firstValueType ==
      "number" -- ❌ Don't use KEY_ELEMENT_TYPE here.
  --              Clients might want to write these themselves.
  --              We can still use `KEY_ELEMENT_TYPE` to know if users used `key()` or not.
  --              If not, and types are misaligned, they likely weren't trying to key an element.
  local isComponentElement = element.type == COMPONENT_ELEMENT_TYPE -- TODO: Should we not rely on this type either?

  if (isContextProviderElement) then
    --printh("Rendering context provider element")
    local context = firstValue
    local value = element[2]
    local children = element[3]
    local previousValue = currentContextValues[context]
    currentContextValues[context] = value
    renderElement(children, prefixWithIndex)
    currentContextValues[context] = previousValue
  elseif isKeyElement then
    --printh("Rendering key element")
    local key = firstValue
    local childElement = element[2]
    if DEV then
      assert(childElement.type == COMPONENT_ELEMENT_TYPE, "Key element must have a component element as its child.")
      -- TODO: Are there other elements we should support keying?
    end
    renderComponentElement(childElement, prefixWithDash .. key)
  elseif isComponentElement then
    --printh("Rendering component element")
    renderComponentElement(element, prefixWithIndex)
  else -- element must me an array of elements
    --printh("Rendering element array")
    if DEV then
      -- TODO: Print component stack
      assert(isArrayLike(element),
        "Element was a table, but not an array-like table. An array-like table has contiguous non-nil values, or an n-property with the array size.")
    end

    local min = 1
    local max = getn(element)
    for childIndex = min, max do
      renderElement(element[childIndex], prefixWithIndex, childIndex)
    end
  end
end

--- # `useState`
---
--- The `useState` hook is inspired by `useState` from React.js, and lets you set and retrieve state for a component.
---
--- `useState` returns `state, setState` where `state` is the current state, and `setState` is a function that updates the state.
---
--- In contrast to React.js`s `useState` hook, `setState` applies the state change immediately.
---
--- ## Usage
---
--- For example, you could use `useState` to store a frame count, incremented every frame:
---
--- ```lua
--- local FrameComponent = component("FrameComponent", function()
---   local frame, setFrame = useState(0)
---   frame += 1          -- ❌ Don't update state variables directly.
---                       --    This will update the `frame` variable,
---                       --    but not the internal state, and
---                       --    `frame` will be 0 again next render.
---   setFrame(frame + 1) -- ✅ Do update using setters.
---                       --    This will update the internal state such that
---                       --    `frame` will hold the incremented value next render.
--- end)
--- ```
---
--- If you need the frame variable to include the updated state after updating it, for example to print it, you should update it too:
---
--- ```lua
--- local FrameComponent = component("FrameComponent", function()
---   local frame, setFrame = useState(0)
---   frame = setFrame(frame + 1) -- ✅ Do update state variable with setters.
--- --^^^^^^^                     --    This will update the `frame` variable,
---                               --    and the internal state such that `frame`
---                               --    will hold the incremented value next render.
---   print(frame)
--- end)
--- ```
---
--- ### State tables
---
--- In React.js, when you store an object in state, `useState({})`, you are required to use `setState()` when modifying the object, to trigger a rerender.
---
--- Because react-p64 renders every frame, we aren't reliant on a state tables (passing tables, `{}`, to `useState()`) to change its reference every mutation, and thus, it is fine to mutate state tables directly.
---
--- For example:
--- ```lua
--- local FrameComponent = component("FrameComponent", function()
---   local state, setState = useState({ frame = 0 })
---   state.frame += 1 -- ✅ Do: Modify table state properties directly,
---                              instead of using `setState`.
---   print(state.frame)
--- end)
--- ```
---
--- If you need the state table to chance reference, for example, if used in a `useMemo` dependency array, you need to fall back to the setter, eg. `setState`.
---
--- ###
--- In contrast to React.js's `useState`, it embraces mutability, as this library neither tracks nor rerenders on prop/state changes.
---
--- For example, in React.js, you would use `useState` to store an object, and then use `setState` to update it, to make sure the state reference changes, to trigger a rerender.
---
--- In this library, you would use `local state = useState({})` to store a table, and then just update the table directly with `state.foo = "bar"`.
---
--- If you need to update non-table state, you still need to use
---
--- Along with the state, the function returns a `setState` function to enable overrides of tables or updates to non-table values.
---
--- Table states can largely ignore the setState function by updating table properties directly.
---
--- `useState` can be called with a non-function value or a setter function.
---
--- Storing functions can be achieved by wrapping the function in a table, or by returning the function from a setter function.
---
--- ## React.js reference
---
--- https://react.dev/reference/react/useState
---
--- @generic TValue
--- @param initialValue TValue | fun(): TValue
--- @return TValue, fun(newValue: TValue): void
local function useState(initialValue)
  if DEV then
    -- TODO: Print component stack
    assert(currentInstanceId != nil, "useState must be called inside of components")
  end

  local currentInstance = instances[currentInstanceId]
  local hooks = currentInstance.hooks
  local hookIndex = currentInstance.hookIndex

  if (hooks[hookIndex] == nil) then
    -- If initial render, initialize state
    if (type(initialValue) == "function") then
      -- We need an if statement here, because `a and b or c` doesn't work well with nils.
      initialValue = initialValue()
    end
    hooks[hookIndex] = {
      -- TODO: Possibly add type="useState", and assert it in subsequent renders in DEV?
      value = initialValue
    }
  end

  local function setState(newValue)
    hooks[hookIndex].value = newValue
    return newValue
  end

  currentInstance.hookIndex += 1
  return hooks[hookIndex].value, setState
end

--- # `Fragment()`
---
--- Fragment() is used to safely render an array of components.
---
--- Compared to returning an array of components, this allows us to include
--- `nil`, which can be useful for conditionally rendering components.
---
--- To understand why, it's a good idea to know how arrays sizes work in Lua.
--- You can learn that here: https://www.lua.org/pil/19.1.html
---
--- ## Usage
---
--- We can better understand `Fragment()` if we start by learning what not to do.
---
--- Assume we have a `Text` component defined elsewhere, and notice how returning an array containing `nil` breaks the expected behavior:
--- ```lua
--- local MyComponent = component("MyComponent", function()
---   local shouldRenderText = rnd(1) > 0.5
---   return {           -- ❌ Don't return arrays containing `nil`.
---                      --    It will cut short the array.
---     Text("Hello!"),
---     shouldRenderText
---       and Text("`shouldRenderText` is true!")
---       or nil,        -- ❌ Don't use `nil` in arrays.
---     Text("Goodbye!") -- ℹ️ Because the array is cut short,
---                      --    `Text("Goodbye!")` will not be rendered
---                      --    when `shouldRenderText` is `false`.
---   }
--- end)
--- ```
---
--- Using `Fragment` instead, we can return `nil` values in the array:
--- ```lua
--- local MyComponent = component("MyComponent", function()
---   local shouldRenderText = rnd(1) > 0.5
---   return Fragment(   -- ✅ Use `Fragment` to return arrays containing `nil`.
---     Text("Hello!"),
---     shouldRenderText
---       and Text("`shouldRenderText` is true!")
---       or nil,        -- ✅ Use `nil` in `Fragment`.
---     Text("Goodbye!") -- ℹ️ Because we're using `Fragment`,
---                      --    `Text("Goodbye!")` will always be rendered.
---   )
--- end)
--- ```
---
--- You can use `false` instead of `nil` in arrays, as react-p64 ignores `false` values.
--- But getting into the habit of using `Fragment` will save you some headaches down the line.
---
--- ## `Fragment` vs `pack`
---
--- TODO: Move to docs.
---
--- Currently, `Fragment` actually just a reference to the `pack`, which converts its parameters to an array,
--- but with the crucial difference of adding the array size `n`, which includes `nil` values.
--- As such you can replace `Fragment()` with `pack()` without issues.
--- This might change in the future though.
---
--- Note that our Fragment here is pretty different from that of React.js.
--- See this comparison of Fragments and arrays: https://stackoverflow.com/a/55236980.
--- The main appeal of `Fragment` in React.js is that you don't need to
--- separate components by commas, and strings don't need quotes.
--- As we have no compile step, unlike JSX, we can't do away with commas and quotes.
---
--- It just so happened that we need to pack arrays in Lua in the same place
--- we would use `Fragment` in React.js, so it makes sense to reuse the name.
local Fragment = pack

--- deps() is used to specify dependencies for `useMemo`.
---
--- Is it necessary to support `nil` values in dependency arrays.
---
--- To understand why, it's a good idea to know how array sizes work in Lua.
--- You can learn that here: https://www.lua.org/pil/19.1.html
---
--- TODO: Extend docs. Take inspiration from the `Fragment` docs.
local deps = pack

--- # `keyed`
---
--- `keyed` is used to give a unique identity to a component.
---
--- This is required when you want to render a list of components and you don't
--- want the components to re-mount and lose state when the list order changes.
---
--- To learn why, read the official React.js documentation on rendering lists:
--- https://react.dev/learn/rendering-lists
---
--- ## Usage
---
--- The following example assumes you have an `arrayMap` function that works
--- like `Array.prototype.map` in JavaScript.
---
--- ```lua
--- local ListItem = component("ListItem", function (text)
---   print(text)
--- end
---
--- local List = component("List", function (items)
---   return arrayMap(items, function(item)
---     return keyed(item.id, ListItem(item.text)) -- ✅ Do use `keyed(key, component)` components in dynamic lists
---   end)
--- end
---
--- local function App()
---   return List({
---     { id = 1, text = "Hello" },
---     { id = 2, text = "World" }
---   })
--- end
--- ```
---
--- Instead of `keyed(key, MyComponent())`, you can also use `{key, MyComponent()}`.
---
--- @param key string | number The key to use for the element
--- @param element table The element to render
--- @return table # The keyed element
local function keyed(key, element)
  assert(type(key) == "string" or type(key) == "number", "key must be a string or number")
  return { key, element, type = KEY_ELEMENT_TYPE }
end

local function didDepsChange(prevDeps, newDeps)
  if DEV then
    -- TODO: Print component stack
    assert(prevDeps.n == newDeps.n,
      "dependency arrays must be the same length between renders. Got lengths " ..
      prevDeps.n .. " and " .. newDeps.n .. ".")
  end
  if (newDeps.n == 0) then
    return false
  end
  for i = 1, newDeps.n do
    if (prevDeps[i] != newDeps[i]) then
      return true
    end
  end
  return false
end

--- # `useMemo`
---
--- `useMemo` is a React Hook that lets you cache the result of a calculation between re-renders.
---
--- TODO: Add examples. Remember to use `deps()` in all of them to cement its importance.
---
--- ## React.js reference
---
--- https://react.dev/reference/react/useMemo
---
--- @generic TValue
--- @param calculateValue fun(): TValue | nil
--- @param dependencies array
--- @return TValue
local function useMemo(calculateValue, dependencies)
  if DEV then
    -- TODO: Print component stack
    assert(currentInstanceId != nil, "useMemo must be called inside of components")
    assert(type(calculateValue) == "function", "useMemo must receive a calculateValue function")
    assert(type(dependencies) == "table", "useMemo must receive a dependency array")
    assert(dependencies.n != nil,
      "dependency array passed to useMemo must be created with `deps()`, eg. `useMemo(fn, deps(dep1, dep2, dep3))` or `useMemo(fn, deps())`")
  end

  local currentInstance = instances[currentInstanceId]
  local hooks = currentInstance.hooks
  local hookIndex = currentInstance.hookIndex

  if (hooks[hookIndex] == nil
        or didDepsChange(hooks[hookIndex].dependencies, dependencies)) then
    -- If initial render OR dependencies have changed, update hook value and deps
    hooks[hookIndex] = {
      -- TODO: Possibly add type="useMemo", and assert it in subsequent renders?
      value = calculateValue(),
      -- I thought about support multiple return values using pack/unpack.
      -- But clients can just return a table, and unpack it themselves.
      -- We better save the compute of packing/unpacking everything.
      dependencies = dependencies
    }
  end

  currentInstance.hookIndex += 1
  return hooks[hookIndex].value
end

--- # `createContext`
---
--- Creates a context that can be used to pass data through the component tree without having to pass props down manually at every level.
---
--- ## Usage
---
--- ```lua
--- local MyContext = createContext("default value")
---
--- local MyComponent = component("MyComponent", function()
---   local value = use(MyContext)
---   print(value)
--- end)
---
--- local App = component("App", function()
---   return Fragment(
---     MyContext.Provider({ value = "hello world" }, MyComponent())
---   )
--- end)
---
--- ## React.js reference
---
--- https://react.dev/reference/react/createContext
---
--- TODO: Generic typing
---
--- @param defaultValue any The default value of the context.
--- @return table context The context.
local function createContext(defaultValue)
  if DEV then
    -- TODO: Print component stack
    assert(currentInstanceId == nil, "`createContext` must be called outside of components")
  end
  local context = {}
  currentContextValues[context] = defaultValue
  context.Provider = function(value, children)
    return { context, value, children, type = CONTEXT_PROVIDER_ELEMENT_TYPE }
  end
  return context
end

--- ## `use`
--- Returns the value set by the closest instance of the given context provider
--- above the component that calls it.
---
--- ## Pitfall
--- `use` always looks for the closest context provider above
--- the component that calls it. It searches upwards and does not consider
--- context providers in the component from which you’re calling use(context).
---
--- ## React.js reference
---
--- https://react.dev/reference/react/use
---
---  TODO: Generic typing
---
--- @param context any The context to use.
--- @return any The value of the context.
local function use(context)
  if DEV then
    -- TODO: Print component stack
    assert(currentInstanceId != nil, "`use` must be called inside of components")
  end
  return currentContextValues[context]
end

--- ## `renderRoot`
--- Renders the root element.
---
--- This function should normally be called only once per frame.
---
--- For example:
--- ```lua
--- local App = component("App", function()
---   print("Hello from App component!")
--- end)
---
--- function _draw()
---   cls()
---   renderRoot(App)
--- end
---
--- @param componentOrElement function|table The root component or component element to render.
local function renderRoot(componentOrElement)
  --[[
    TODO: See if it's possible to predict if the current frame (main loop iteration)
          will include a `_draw()` call (is a drawing frame).
          The main loop in `foot.lua` seems to use:
          ```lua
          _update()
          local fps = stat(7)
          if (fps < 60) __process_event_messages() _update()
          if (fps < 30) __process_event_messages() _update()
          ```
          Can we also use `stat(7)` to predict if `_draw()` will be called?
          If so, we can override all draw function with no-operations if `_draw()` will not be called.
          This way we can save some CPU cycles.
    TODO: We should also surface a `willDraw()` function or `useDraw(function)`
          hook to further encapsulate draw logic.
  ]]

  assert(
    componentOrElement.type == COMPONENT_TYPE or
    componentOrElement.type == COMPONENT_ELEMENT_TYPE,
    "renderRoot's `componentOrElement` argument must be a component or component element."
  )

  local element = componentOrElement.type == COMPONENT_TYPE and componentOrElement() or componentOrElement

  --printh("[react][renderRoot] element: " .. describe(element))

  renderElement(element)

  -- Clean up any unmounted component instances
  for instanceId, instance in pairs(instances) do
    -- If component wasn't rendered this frame, remove it completely
    if instance.lastRenderFrame != frame then
      instances[instanceId] = nil
    end
  end

  frame += 1
end

local React = {
  component = component,
  renderRoot = renderRoot,
  useState = useState,
  useMemo = useMemo,
  use = use,
  createContext = createContext,
  Fragment = Fragment,
  deps = deps,
  keyed = keyed,
  -- TODO: Add an `__reactInternals` property or similar with all locals to support external devtools?
}
React.export = function( --[[self]])
  -- This function is also added to the returned table's `__call` metamethod,
  -- such that you can call `include("#react")()` instead.
  -- Problem with this solution is react library authors still need to set every method as a local variable,
  -- so it doesn't modify the global scope of users.
  for k, v in pairs(React) do
    if (k != "export") then
      if (_G[k] != nil and DEV) then
        printh("Warning: " .. k .. " already exists in the global scope.")
      end
      _G[k] = v
    end
  end
end
setmetatable(React, { __call = React.export })

return React
