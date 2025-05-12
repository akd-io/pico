---Wrap is a component that simply takes a function and arguments and runs the function on render.
---This is useful for calling builtin functions like clip() at a specific point in the render tree,
---as it's not possible to specify a function like clip as a component in the render tree,
---as its return value is not a valid react element.
Wrap = createComponent("Wrap", function(func, ...)
  func(...)
  -- Do not return func's return value, as it is not a valid react element.
end)
