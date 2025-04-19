--[[pod_format="raw",created="2025-04-14 14:04:50",modified="2025-04-14 14:25:06",revision=2]]
include("/lib/describe.lua")
include("/lib/utils.lua")
include("/lib/react.lua")
renderRoot, useState, createContext, useContext, useMemo = __initReact()
include("/lib/react-motion.lua")
useSprings, useSpring, useTransition, AnimatePresence, Motion = __initMotion()
include("/hooks/usePrevious.lua")
include("/hooks/useMouse.lua")
MouseProvider, useMouse = __initMouseProvider()
include("/hooks/useClickableArea.lua")
include("/projects/deqoi/deqoi.lua")
include("/lib/mkdirr.lua")
include("/hooks/useDir.lua")

include("components/Wrap.lua")
include("components/Label.lua")
include("hooks/useLabels.lua")
include("hooks/useCartPaths.lua")

local width = 480
local height = 270

function _init()

end

function _update()

end

local ramExploreCacheDirPath = "/ram/explore-cache"
local cartCachePodFilePath = ramExploreCacheDirPath .. "/allCartPaths.pod"

local categoryPaths = {
  "bbs://new",
  "bbs://featured",
  "bbs://wip"
}

local labelCachePodFilePath = ramExploreCacheDirPath .. "/labels.pod"

local frame = 0
function App()
  mkdirr(ramExploreCacheDirPath)

  local state = useState({
    categoryIndex = 1,
    selectedCartIndex = 1,
  })

  local categoryIndexDiff = tonum(btnp(3)) - tonum(btnp(2))
  if categoryIndexDiff != 0 then
    state.categoryIndex = ((state.categoryIndex + categoryIndexDiff - 1) % #categoryPaths) + 1
  end

  local function getOffsetIndex(currentIndex, offset, length)
    return ((currentIndex + offset - 1) % length) + 1
  end

  local allCartPaths = useCartPaths(categoryPaths, cartCachePodFilePath)
  --printh("allCartPaths:")
  --printh(describe(allCartPaths))

  local selectedCategoryPath = categoryPaths[state.categoryIndex]
  local categoryCartPaths = allCartPaths[selectedCategoryPath]
  --printh("categoryCartsPaths:")
  --printh(describe(categoryCartsPaths))

  local selectedCartIndexDiff = tonum(btnp(1)) - tonum(btnp(0))
  if selectedCartIndexDiff != 0 then
    state.selectedCartIndex = getOffsetIndex(state.selectedCartIndex, selectedCartIndexDiff, #categoryCartPaths)
  end

  local selectedCartPath = categoryCartPaths[state.selectedCartIndex]

  local drawnCartPaths = useMemo(function()
    return {
      categoryCartPaths[getOffsetIndex(state.selectedCartIndex, -3, #categoryCartPaths)],
      categoryCartPaths[getOffsetIndex(state.selectedCartIndex, -2, #categoryCartPaths)],
      categoryCartPaths[getOffsetIndex(state.selectedCartIndex, -1, #categoryCartPaths)],
      categoryCartPaths[state.selectedCartIndex],
      categoryCartPaths[getOffsetIndex(state.selectedCartIndex, 1, #categoryCartPaths)],
      categoryCartPaths[getOffsetIndex(state.selectedCartIndex, 2, #categoryCartPaths)],
      categoryCartPaths[getOffsetIndex(state.selectedCartIndex, 3, #categoryCartPaths)],
    }
  end, { state.selectedCartIndex, categoryCartPaths })

  local labels = useLabels(drawnCartPaths, labelCachePodFilePath)

  cls() -- TODO: Probably don't need cls() later, when rendering on every part of the screen anyway.
  return {
    labels[2] and { drawnCartPaths[2], Label, labels[2], 1, width, height } or false,
    labels[3] and { drawnCartPaths[3], Label, labels[3], 2, width, height } or false,
    labels[4] and { drawnCartPaths[4], Label, labels[4], 3, width, height } or false,
    labels[5] and { drawnCartPaths[5], Label, labels[5], 4, width, height } or false,
    labels[6] and { drawnCartPaths[6], Label, labels[6], 5, width, height } or false,

    { Wrap, clip },
    { Wrap, print, "frame: " .. frame,                               0, 0,      12 },
    { Wrap, print, "fps: " .. stat(7),                               0, 0 + 10, 12 },
    { Wrap, print, "selectedCartIndex: " .. state.selectedCartIndex, 0, 0 + 20, 12 },
    { Wrap, print, "selectedCartPath: " .. tostr(selectedCartPath),  0, 0 + 30, 12 },

    arrayMap(drawnCartPaths, function(cartPath, i)
      return { Wrap, print, cartPath, 0, 0 + 40 + i * 10, 12 }
    end),
  }
end

function _draw()
  frame += 1
  renderRoot(App)
end
