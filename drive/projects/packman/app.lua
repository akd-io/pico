--[[pod_format="raw",created="2025-04-09 22:01:06",modified="2025-04-10 15:15:04",revision=9]]
include("/hooks/usePrevious.lua")
include("/hooks/useMouse.lua")
MouseProvider, useMouse = __initMouseProvider()
include("/hooks/useClickableArea.lua")

function CameraClip(x, y, w, h)
  if not x or not y or not w or not h then
    camera()
    clip()
    return
  end
  camera(-x, -y)
  clip(x, y, w, h)
end

function Camera(x, y)
  if not x or not y then
    camera()
    return
  end
  camera(-x, -y)
end

function Clip(x, y, w, h)
  if not x or not y or not w or not h then
    clip()
    return
  end
  clip(x, y, w, h)
end

---@param props { text: string, x: number, y: number, color: number }
local function Text(props)
  local text, x, y, color = props.text, props.x, props.y, props.color
  assert(type(text) == "string", "text must be a string, got " .. type(text))
  assert(type(x) == "number", "x must be a number, got " .. type(x))
  assert(type(y) == "number", "y must be a number, got " .. type(y))
  assert(type(color) == "number", "color must be a number, got " .. type(color))

  print(text, x, y, color)
end

---@param props { x1: number, y1: number, x2: number, y2: number, color: number, children?: table }
local function Rectfill(props)
  local x1, y1, x2, y2, color, children = props.x1, props.y1, props.x2, props.y2, props.color, props.children
  assert(type(x1) == "number", "x1 must be a number, got " .. type(x1))
  assert(type(y1) == "number", "y1 must be a number, got " .. type(y1))
  assert(type(x2) == "number", "x2 must be a number, got " .. type(x2))
  assert(type(y2) == "number", "y2 must be a number, got " .. type(y2))
  assert(type(color) == "number", "color must be a number, got " .. type(color))

  rectfill(x1, y1, x2, y2, color)
  return { children }
end

local buttonXPadding = 4

---@param props { text: string, x1: number, y1: number, x2: number, y2: number, onClick: function }
local function Button(props)
  local text, x1, y1, x2, y2, bgColor = props.text, props.x1, props.y1, props.x2, props.y2, props.bgColor
  assert(type(text) == "string", "text must be a string, got " .. type(text))
  assert(type(x1) == "number", "x1 must be a number, got " .. type(x1))
  assert(type(y1) == "number", "y1 must be a number, got " .. type(y1))
  assert(type(x2) == "number", "x2 must be a number, got " .. type(x2))
  assert(type(y2) == "number", "y2 must be a number, got " .. type(y2))
  assert(type(props.onClick) == "function", "onClick must be a function, got " .. type(props.onClick))
  assert(x1 < x2, "x1 must be less than x2")
  assert(y1 < y2, "y1 must be less than y2")

  local clickArea = useClickableArea(x1, y1, x2, y2)

  if (clickArea.leftClicked) then
    props.onClick()
  end

  return {
    { Rectfill, {
      x1 = x1,
      y1 = y1,
      x2 = x2,
      y2 = y2,
      color = bgColor or clickArea.isHovering and 7 or 6,
      children = {
        { Text, {
          text = text,
          x = x1 + buttonXPadding,
          y = y1 + 4,
          color = 0
        } }
      }
    } }
  }
end

---@param props { x:number, y:number, width:number, tabs: { name: string, children: children }[] }
local function Tabs(props)
  local x, y, tabs, width = props.x, props.y, props.tabs, props.width
  assert(type(x) == "number", "x must be a number, got " .. type(x))
  assert(type(y) == "number", "y must be a number, got " .. type(y))
  assert(type(props.tabs) == "table", "tabs must be a table, got " .. type(props.tabs))
  assert(#props.tabs > 0, "tabs must have at least one tab, got " .. #props.tabs)
  assert(type(props.tabs[1].name) == "string", "tab name must be a string, got " .. type(props.tabs[1].name))
  assert(type(props.tabs[1].children) == "table", "tab children must be a table, got " .. type(props.tabs[1].children))
  assert(type(width) == "number", "width must be a number, got " .. type(width))

  local state = useState({
    selectedTabIndex = 1
  })

  local height = 14

  local xAccumulator = 0
  local buttonPadding = 2 * buttonXPadding
  local enrichedTabs = arrayMap(tabs, function(tab, i)
    local buttonWidth = print(tab.name, 0, 1000) - 1 + buttonPadding
    local result = { i, Button, {
      x1 = x + xAccumulator,
      y1 = y,
      x2 = x + xAccumulator + buttonWidth,
      y2 = y + height,
      text = tab.name,
      onClick = function()
        state.selectedTabIndex = i
      end,
      bgColor = state.selectedTabIndex == i and 7 or nil
    } }
    xAccumulator += buttonWidth
    return result
  end)

  return {
    { Rectfill, {
      x1 = x,
      y1 = y,
      x2 = x + width,
      y2 = y + height,
      color = 6
    } },

    enrichedTabs,

    tabs[state.selectedTabIndex].children,
  }
end

--[[
  BBS caching:
  `/appdata/packman/installed`:
  - Holds downloaded/installed carts.
  - These carts are managed from the "installed" tab.

  `/appdata/packman/bbsCartCache.pod`:
  {
    categories: [
      "new": { -- bbs://new
        "lastFetched": 1234567890, -- epoch seconds. Used to determine if the cache is stale.
        "carts": [
          {
            "id": "test-0",
          }
        ]
      },
      "featured": { -- bbs://featured
        "lastFetched": 1234567890, -- epoch seconds. Used to determine if the cache is stale.
        "carts": [
          {
            "id": "test-0",
          }
        ]
      },
      "wip": { -- bbs://wip
        "lastFetched": 1234567890, -- epoch seconds. Used to determine if the cache is stale.
        "carts": [
          {
            "id": "test-0",
          }
        ]
      },
    ]
  }
]]
local bbsCartCachePodPath = "/appdata/packman/bbsCartCache.pod"
local bbsCartCache = fetch(bbsCartCachePodPath)

--[[
  State data structure:
  {
    selectedTabIndex: 1,
    -- installed: ... -- Installed should not be saved, but derived from the filesystem.
  }
]]
local statePodPath = "/appdata/packman/state.pod"
local state = fetch(statePodPath)

local function useCategoryCarts(categoryUrl)
  return useMemo(
    function()
      local carts = {}

      local categoryDir = ls(categoryUrl)
      printh(categoryUrl .. ": " .. describe(categoryDir))
      for _, pageName in ipairs(categoryDir) do
        local pageUrl = categoryUrl .. "/" .. pageName
        local pageDir = ls(pageUrl)
        if (#pageDir == 0) then break end
        printh(pageUrl .. ": " .. describe(pageDir))
        for _, cart in ipairs(pageDir) do
          add(carts, cart)
        end
        -- TODO: Remove break when proper caching is in place
        break
      end

      return carts
    end,
    { categoryUrl }
  )
end

function ScrollView(props)
  local x, y, width, height, children = props.x, props.y, props.width, props.height, props.children

  local mouse = useMouse()
  local wheel_y = mouse.wheel_y
  local state = useState({
    scroll_y = 0,
  })

  state.scroll_y = state.scroll_y + 2 * wheel_y

  clip(x, y, width, height)
  rectfill(x, y, x + width, y + height, 12)

  return {
    children,
  }
end

---@param props { carts: string[], x: number, y: number, width: number, height: number }
function CartList(props)
  local carts, x, y, width, height = props.carts, props.x, props.y, props.width, props.height
  return {
    { ScrollView, {
      x = x,
      y = y,
      width = width,
      height = height,
      children = {
        { Text,
          {
            text = table.concat(carts, "\n"),
            x = x + 4,
            y = y + 4,
            color = 1
          }
        }
      }
    } },
    { CameraClip, x, y, width, height }
  }
end

function Pane(x, y, width, height, color, children)
  rectfill(x, y, x + width, y + height, color)
  return {
    { Camera, x, y },
    { Clip,   x, y, width, height },
    children,
  }
end

function App()
  cls(7)

  local new = useCategoryCarts("bbs://new")
  local featured = useCategoryCarts("bbs://featured")
  local wip = useCategoryCarts("bbs://wip")
  local all = {}
  for _, cart in ipairs(new) do
    add(all, cart)
  end
  for _, cart in ipairs(featured) do
    add(all, cart)
  end
  for _, cart in ipairs(wip) do
    add(all, cart)
  end

  local x, y = 0, 0
  local tabTitleHeight = 14

  return {
    { MouseProvider, {
      { Tabs, {
        x = x,
        y = y,
        width = width,
        tabs = {
          {
            name = "All",
            children = { CartList,
              {
                carts = all,
                x = x + 4,
                y = y + tabTitleHeight + 4,
                width = width - 8,
                height = height - tabTitleHeight - 8
              }
            }
          },
          {
            name = "New",
            children = { CartList,
              {
                carts = new,
                x = x + 4,
                y = y + tabTitleHeight + 4,
                width = width - 8,
                height = height - tabTitleHeight - 8
              }
            }
          },
          {
            name = "Featured",
            children = { CartList,
              {
                carts = featured,
                x = x + 4,
                y = y + tabTitleHeight + 4,
                width = width - 8,
                height = height - tabTitleHeight - 8
              }
            }
          },
          {
            name = "Work in progress",
            children = { CartList,
              {
                carts = wip,
                x = x + 4,
                y = y + tabTitleHeight + 4,
                width = width - 8,
                height = height - tabTitleHeight - 8
              }
            }
          },
          {
            name = "Installed",
            children = { CartList,
              {
                carts = {},
                x = x + 4,
                y = y + tabTitleHeight + 4,
                width = width - 8,
                height = height - tabTitleHeight - 8
              }
            }
          },
          {
            name = "Favorites",
            children = { CartList,
              {
                carts = {},
                x = x + 4,
                y = y + tabTitleHeight + 4,
                width = width - 8,
                height = height - tabTitleHeight - 8
              }
            }
          },
        }
      } },
      { Pane, 50, 50, 100, 100, 8, {
        { Text, {
          text =
          "Hello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\n",
          x = 0,
          y = 0,
          color = 1
        } },
        { Pane,       50, 50, 100, 100, 24 },
        { CameraClip, 50, 50, 100, 100 },
      } },
      { Camera },
      { Clip }
    } }
  }
end
