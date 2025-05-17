include("/lib/describe.lua")
include("/lib/utils.lua")
include("/projects/react/react-p64.lua")()
include("/lib/react-motion.lua")
useSprings, useSpring, useTransition, AnimatePresence, Motion = __initMotion()
include("/hooks/usePrevious.lua")
include("/hooks/useMouse.lua")
include("/hooks/useClickableArea.lua")
include("/projects/deqoi/deqoi.lua")
include("/lib/mkdirr.lua")
include("/hooks/useDir.lua")
include("/projects/rpc/rpc.lua")

include("components/Wrap.lua")
include("components/Label.lua")
include("hooks/useLabels.lua")
include("hooks/useCartPaths.lua")

local width = 480
local height = 270

local ramExploreCacheDirPath = "/ram/explore-cache"
local cartCachePodFilePath = ramExploreCacheDirPath .. "/allCartPaths.pod"
local categories = {
  {
    name = "Featured",
    path = "bbs://featured"
  },
  {
    name = "New",
    path = "bbs://new"
  },
  {
    name = "WIP",
    path = "bbs://wip"
  }
}
local categoryPaths = arrayMap(categories, function(category) return category.path end)

local labelCachePodFilePath = ramExploreCacheDirPath .. "/labels.pod"

local StatsOverlay = component("StatsOverlay", function()
  return {
    Wrap(print, "\^o0ffFrame: " .. frame, 2, 2, 12),
    Wrap(print, "\^o0ffMEM: " .. stat(0), 2, 2 + 10, 12),
    Wrap(print, "\^o0ffCPU: " .. stat(1), 2, 2 + 20, 12),
    Wrap(print, "\^o0ffFPS: " .. stat(7), 2, 2 + 30, 12),
  }
end)

local CenteredText = component("CenteredText", function(text, y, col)
  local lines = text:split("\n")
  for line in all(lines) do
    local textWidth = getTextWidth(line)
    print(line, width / 2 - textWidth / 2, y, col)
    y += 10
  end
end)

local cartMetadata = {}
local cartMetadataRPC = createRPC({
  funcName = "fetch_metadata",
  event = "cartMetadataResponse",
  onEvent = function(msg)
    --printh("[explore fetch_metadata] Msg: " .. describe(msg))
    cartMetadata = msg.rpc.unpackResult()
    --printh("[explore fetch_metadata] cartMetadata:" .. describe(cartMetadata))
  end
})

local App = component("App", function()
  mkdirr(ramExploreCacheDirPath)

  local state = useState({
    categoryIndex = 1,
    selectedCartIndex = 1,
  })

  local categoryIndexDiff = tonum(btnp(3)) - tonum(btnp(2))
  if categoryIndexDiff != 0 then
    state.categoryIndex = ((state.categoryIndex + categoryIndexDiff - 1) % #categoryPaths) + 1
  end

  --printh("[explore] categoryPaths: " .. describe(categoryPaths))

  local allCartPaths = useCartPaths(categoryPaths, cartCachePodFilePath)
  --printh("[explore] allCartPaths:" .. describe(allCartPaths))

  local selectedCategoryPath = categoryPaths[state.categoryIndex]
  local categoryCartPaths = allCartPaths[selectedCategoryPath]
  --printh("[explore] categoryCartPaths:" .. describe(categoryCartPaths))

  local function getOffsetIndex(currentIndex, offset, length)
    return ((currentIndex + offset - 1) % length) + 1
  end

  local selectedCartIndexDiff = tonum(btnp(1)) - tonum(btnp(0))
  if selectedCartIndexDiff != 0 then
    state.selectedCartIndex = getOffsetIndex(state.selectedCartIndex, selectedCartIndexDiff, #categoryCartPaths)
  end

  local selectedCartPath = categoryCartPaths[state.selectedCartIndex] or false

  assert(state.selectedCartIndex != nil, "state.selectedCartIndex cannot be nil") -- Or useMemo's dep array might change length
  assert(categoryCartPaths != nil, "categoryCartPaths cannot be nil")             -- Or useMemo's dep array might change length
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
  end, deps(state.selectedCartIndex, categoryCartPaths))


  local categoryName = categories[state.categoryIndex].name
  local cartFile = selectedCartPath and selectedCartPath:match("([^/]+)$") or false
  local safeBBSCartPath = cartFile and "bbs://" .. cartFile or false
  local cartFileName = cartFile and cartFile:match("(.+)%.") or false

  assert(selectedCartPath != nil, "selectedCartPath cannot be nil") -- Or useMemo's dep array might change length
  useMemo(function()
    if (not safeBBSCartPath) then return end
    cartMetadataRPC({ funcArgs = { safeBBSCartPath } })
  end, deps(selectedCartPath))

  local cartNameWithoutExtension = cartFileName and cartFileName:match("(.+)%.") or false

  local labels = useLabels(drawnCartPaths, labelCachePodFilePath)

  --printh("[explore] cartMetadata: " .. describe(cartMetadata))

  cls()

  return Fragment(
    labels[1] and { drawnCartPaths[1], Label(labels[1], 1, width, height) } or false,
    labels[2] and { drawnCartPaths[2], Label(labels[2], 2, width, height) } or false,
    labels[3] and { drawnCartPaths[3], Label(labels[3], 3, width, height) } or false,
    labels[4] and { drawnCartPaths[4], Label(labels[4], 4, width, height) } or false,
    labels[5] and { drawnCartPaths[5], Label(labels[5], 5, width, height) } or false,
    labels[6] and { drawnCartPaths[6], Label(labels[6], 6, width, height) } or false,
    labels[7] and { drawnCartPaths[7], Label(labels[7], 7, width, height) } or false,
    Wrap(clip),

    --{ Wrap,         print,                    "\^o0ffselectedCategoryPath: " .. selectedCategoryPath, 2, 2 + 40, 12 },
    --{ Wrap,         print,                    "\^o0ffselectedCartIndex: " .. state.selectedCartIndex, 2, 2 + 50, 12 },
    --{ Wrap,         print,                    "\^o0ffselectedCartPath: " .. tostr(selectedCartPath),  2, 2 + 60, 12 },

    CenteredText("\^o0ff" .. categoryName, 2, 12),
    (cartMetadata and cartMetadata.icon) and Fragment(
      Wrap(palt),
      Wrap(spr, cartMetadata.icon, width / 2 - cartMetadata.icon:width() / 2, height - 1 - 60 - 16 - 2)
    ) or false,
    CenteredText("\^o0ff" .. (cartFileName or ""), height - 1 - 60, 12),
    CenteredText("\^o0ff" .. (cartMetadata.title or cartNameWithoutExtension or ""), height - 1 - 50, 12),
    CenteredText("\^o0ff" .. (cartMetadata.version or ""), height - 1 - 40, 12),
    CenteredText("\^o0ff" .. (cartMetadata.author or "Anonymous"), height - 1 - 30, 12),
    CenteredText("\^o0ff" .. (cartMetadata.notes or ""):gsub("\n", "\n\^o0ff"), height - 1 - 20, 12),
    StatsOverlay()
  )
end)

frame = 0
function _draw()
  frame += 1
  renderRoot(App)
end
