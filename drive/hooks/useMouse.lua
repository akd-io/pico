--[[pod_format="raw",created="2025-04-09 22:00:26",modified="2025-04-09 22:05:19",revision=4]]
--[[
  REQUIREMENTS:
  - react.lua
  - usePrevious.lua
]]

do
  local MouseContext = createContext()

  MouseProvider = component("MouseProvider", function(children)
    useMemo(function() poke(0x5F2D, 0x1) end, deps())

    local x, y, buttonBitfield, wheel_x, wheel_y = mouse()

    local leftDown = buttonBitfield & 0x1 > 0
    local rightDown = buttonBitfield & 0x2 > 0

    local leftDragStart = useMemo(
      function() return { x, y } end,
      deps(leftDown)
    )
    local rightDragStart = useMemo(
      function() return { x, y } end,
      deps(rightDown)
    )

    local leftHasMovedWhileDown = x != leftDragStart[1] or y != leftDragStart[2]
    local rightHasMovedWhileDown = x != rightDragStart[1] or y != rightDragStart[2]

    local leftJustReleased = usePrevious(leftDown) and not leftDown
    local rightJustReleased = usePrevious(rightDown) and not rightDown

    return MouseContext.Provider(
      {
        x = x,
        y = y,
        wheel_x = wheel_x,
        wheel_y = wheel_y,
        leftDown = leftDown,
        rightDown = rightDown,
        leftClicked = leftJustReleased and not leftHasMovedWhileDown,
        rightClicked = rightJustReleased and not rightHasMovedWhileDown,
        leftDragged = leftJustReleased and leftHasMovedWhileDown,
        rightDragged = rightJustReleased and rightHasMovedWhileDown,
        leftDragStart = leftDragStart,
        rightDragStart = rightDragStart,
        leftSelection = leftDown and leftHasMovedWhileDown and { x, y, leftDragStart[1], leftDragStart[2] },
        rightSelection = rightDown and rightHasMovedWhileDown and { x, y, rightDragStart[1], rightDragStart[2] }
      },
      children
    )
  end)

  function useMouse()
    return use(MouseContext)
  end
end
