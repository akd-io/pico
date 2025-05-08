--[[
  usePrevious will return the value from the previous render.

  REQUIREMENTS:
  - react.lua
]]
function usePrevious(current)
  local state = useState({
    prev = nil,
    current = nil
  })
  state.prev = state.current
  state.current = current
  return state.prev
end
