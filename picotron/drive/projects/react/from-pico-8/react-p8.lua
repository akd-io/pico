--[[
  React.p8
  This library tries to implement the most relevant features of the React.js library for Pico-8.
  See the original library here: https://react.dev/
  Note that regular rules of hooks apply. Check them out here: https://react.dev/reference/rules/rules-of-hooks
]]

--[[
  TODOs:
  - Remove mentions of "Fragment". Upon review, we have implemented support for arrays, which is also available in React.js. Fragments are a JSX-specific construct.
    - To emphasize this; As per https://stackoverflow.com/a/55236980, none of the pros of fragments apply to our array support:
      > Using array notation has has some confusing differences from normal JSX:
      > 1. Children in an array must be separated by commas.
      > 2. Children in an array must have a key to prevent React’s key warning.
      > 3. Strings must be wrapped in quotes.
      To summarize,
      1. As we have no compile step, unlike JSX, we can't do away with commas.
      2. As we have no warnings specific to arrays, this is not an issue for the array syntax.
      3. Back to 1; as we have no compile step, unlike JSX, we can't do away with quotes.
  - Should we implement component wrappings for the different drawing operations?
    - Like the HTML elements in react-dom, we could provide components like Circle, Rect, Line, Text, etc..
    - What value would that provide though? Unless we do the next idea, and the component wrappings would provide these insets automatically.
    - Should we provide a createLayoutComponent or something, that provides a default inset for drawing ops of child components? I have a feeling this could be made third party if useContext was supported. Maybe other hacks could make it work too.
  - Benchmark library
  - Consider refactoring `instances` to be a tree.
    - This way, instance IDs won't balloon in size. Just 3 levels gives an ID of `0x1cf83f4c_1-0x1cf592cc_3-4-0x1cf591dc_3`
    - I imagine instance ID size becoming a problem rather quickly. Imagine 100 components rendered at level 10. That's 12*100*10 = 12000 characters.
  - Optimizations for minified production version:
    - Turn __initComponents into an immediately invoked anonymous function expression
    - Delete comments
    - Delete assertions
    - Save `local` tokens by initializing multiple variables on the same line
]]

--[[
  One might think; Why aren't we just calling our function components directly?
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
  But this would require us to declare function components using a `createComponent()` wrapper function.
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

--[[const]]
DEV = true

function __initReact()
  -- Holds the state of component instances
  local instances = {}

  -- Used during render
  local currentInstanceId = nil
  local frame = 0
  local currentContextValues = {}

  local function isArray(table)
    if (type(table) != "table") then return false end
    local i = 1
    for _ in pairs(table) do
      if table[i] == nil then return false end
      i += 1
    end
    return true
  end

  local internalRenderFunction

  local function renderElements(elements, prefix)
    if DEV then
      assert(type(elements) == "table", "Elements array was not an array. Got type " .. type(elements) .. ".")
      assert(isArray(elements),
        "Elements array was a table, but not an array. Arrays are tables with consecutive number keys. And arrays can't contain nil values. Replace nils in element arrays with false to unmount components.")
    end

    for index, element in ipairs(elements) do
      local elementType = type(element)
      if elementType == "boolean" or (elementType == "table" and #element == 0) then
        goto continue
      end

      -- TODO: Consider accepting elementType == "function" in the case of a propless unkeyed component, or just a function to call. Enables an API to run code after render.
      if DEV then
        assert(elementType == "table",
          "Element must be a table or boolean. Got type " .. elementType .. ".")
      end

      local firstValue = element[1]
      local firstValueType = type(firstValue)

      if DEV then
        assert(
          firstValueType == "table" or firstValueType == "number" or firstValueType == "string" or
          firstValueType == "function" or firstValueType == "boolean",
          "Unrecognized element syntax of the form { " .. firstValueType .. ", ... }."
        )
      end

      if (firstValueType == "table") then
        if (firstValue.type == "provider") then
          local value = element[2]
          local children = element[3]
          local context = firstValue.context
          local previousValue = currentContextValues[context]
          currentContextValues[context] = value
          renderElements(children, index .. "-")
          currentContextValues[context] = previousValue
        else
          -- If firstValueType == "table" and the element is not a context
          -- provider, the element is an array of elements and should have
          -- all its elements rendered.
          -- Their keys will be prefixed with the index of the fragment
          renderElements(element, index .. "-")
        end
      elseif (firstValueType == "boolean") then
        -- If firstValueType == "boolean", element[1] is a placeholder for
        -- a conditionally rendered element, and element is an array of
        -- elements.
        renderElements(element, index .. "-")
      else
        local isKeyedElement = firstValueType == "number" or firstValueType == "string"
        local key = isKeyedElement and firstValue or index
        local externalFunctionComponent = isKeyedElement and element[2] or firstValue

        local renderFuncType = type(externalFunctionComponent)
        if DEV then
          assert(renderFuncType == "function",
            "Elements must be tables with a function as the first element. Got type " .. renderFuncType .. ".")
        end
        local indexOfFirstProp = isKeyedElement and 3 or 2
        internalRenderFunction((prefix or "") .. key, externalFunctionComponent,
          select(indexOfFirstProp, unpack(element)))
      end

      ::continue::
    end
  end

  internalRenderFunction = function(key, externalFunctionComponent, ...)
    if DEV then assert(key != nil, "key must be provided") end
    -- TODO: assert key is string/number?

    -- Save parent/previous component instance and id
    local parentInstanceId = currentInstanceId

    -- Generate instance id
    -- We use tostring(func) to add the address of the external render function to the instance id.
    -- This is important to support conditionals like `condition and { ComponentA } or { ComponentB }`
    local prefix = parentInstanceId and parentInstanceId .. "-" or ""
    local instanceId = prefix .. sub(tostring(externalFunctionComponent), 13) .. "_" .. key

    -- printh("Rendering " .. instanceId)

    -- Initialize component state if missing (initial render)
    if not instances[instanceId] then
      instances[instanceId] = { hooks = {} }
    end

    -- Update current component context
    currentInstanceId = instanceId
    instances[instanceId].hookIndex = 1
    instances[instanceId].lastRenderFrame = frame

    -- Render component with remaining args
    local elementArray = externalFunctionComponent(...)
    -- TODO: Consider not only accepting a fragment here, but also the different element types supported in renderElements
    if elementArray != nil then
      renderElements(elementArray)
    end

    -- Restore parent component context
    currentInstanceId = parentInstanceId
  end

  -- useState is inspired by useState from React.
  -- In contrast to React's useState, it embraces mutability, as this library neither tracks nor rerenders on state changes.
  -- Along with the state, the function returns a setState function to enable updates to non-table types, or complete overrides of tables.
  -- Table states can largely ignore the setState function by updating table properties directly.
  -- useState can be called with a non-function value or a setter function.
  -- Storing functions can be achieved by wrapping the function in a table, or by returning the function from a setter function.
  local function useState(initialValue)
    if DEV then assert(currentInstanceId != nil, "useState must be called inside of components") end

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

  local function didDepsChange(prevDeps, newDeps)
    if DEV then
      assert(#prevDeps == #newDeps,
        "dependency arrays must be the same length between renders. Got lengths " ..
        #prevDeps .. " and " .. #newDeps .. ".")
    end
    if (#newDeps == 0) then
      return false
    end
    for i = 1, #newDeps do
      if (prevDeps[i] != newDeps[i]) then
        return true
      end
    end
    return false
  end

  local function useMemo(calculateValue, dependencies)
    if DEV then
      assert(currentInstanceId != nil, "useMemo must be called inside of components")
      assert(type(calculateValue) == "function", "useMemo must receive a calculateValue function")
      assert(type(dependencies) == "table", "useMemo must receive a dependency array")
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
        dependencies = dependencies
      }
    end

    currentInstance.hookIndex += 1
    return hooks[hookIndex].value
  end

  local function createContext(defaultValue)
    if DEV then assert(currentInstanceId == nil, "createContext must be called outside of components") end
    local context = {}
    currentContextValues[context] = defaultValue
    context.Provider = { type = "provider", context = context }
    return context
  end

  local function useContext(context)
    if DEV then assert(currentInstanceId != nil, "useContext must be called inside of components") end
    return currentContextValues[context]
  end

  local function renderRoot(externalFunctionComponent)
    internalRenderFunction("1", externalFunctionComponent)

    -- Clean up any unmounted component instances
    for instanceId, instance in pairs(instances) do
      -- If component wasn't rendered this frame, remove it completely
      if instance.lastRenderFrame != frame then
        instances[instanceId] = nil
      end
    end

    frame += 1
  end

  return renderRoot, useState, createContext, useContext, useMemo
end

local renderRoot, useState, createContext, useContext, useMemo = __initReact()
