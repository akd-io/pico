local React = include("/projects/react/react.lua")()
include("/hooks/useDir.lua")

window({
  width = 240,
  height = 200,
})

local f = 0
local App = createComponent("App", function()
  f += 1

  local paths = useState({
    "bbs://new/0",
    "bbs://new/1",
    "bbs://new/2",
    "bbs://new/3",
    "bbs://new/4",
    "bbs://new/5",
    "bbs://new/6",
    "bbs://new/7",
    "bbs://new/8",
    "bbs://new/9",
    "bbs://new/10"
  })

  local dirs = useDirs(paths)

  cls()
  print("frame: " .. f)
  for i, path in ipairs(paths) do
    local dir = dirs[path]
    print(path .. ": " .. (dir.loading and "loading" or tostr(#dir.result)))
  end
end)

function _draw()
  renderRoot(App)
end
