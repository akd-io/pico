include("/projects/react/react64.lua")()
include("/hooks/useDir.lua")

window({
  width = 240,
  height = 70,
})

local f = 0
local App = component("App", function()
  f += 1

  local state = useState({
    path = "bbs://new/0"
  })

  if (keyp("x")) then
    state.path =
        state.path == "bbs://new/0"
        and "bbs://new/1"
        or "bbs://new/0"
  end

  local dir = useDir(state.path)

  cls()
  print("frame: " .. f)
  print("path: " .. tostr(state.path))
  print("result: " .. tostr(dir.result))
  print("loading: " .. tostr(dir.loading))
end)

function _draw()
  renderRoot(App)
end
