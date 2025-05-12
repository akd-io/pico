--[[pod_format="raw",created="2025-04-10 23:42:49",modified="2025-04-10 23:42:49",revision=0]]
include("/lib/describe.lua")
include("/lib/utils.lua")
include("/projects/react/react.lua")
include("/hooks/usePrevious.lua")
include("/hooks/useMouse.lua")
include("/hooks/useClickableArea.lua")

local min_width = 200
local min_height = 100
width, height = 300, 200

window({
  width = width,
  height = height,
  min_width = min_width,
  min_height = min_height,
  resizeable = true,
  moveable = true,
  has_frame = true,
  title = "Packman"
})
on_event("resize", function(msg)
  width = msg.width
  height = msg.height
end)

CameraClip = createComponent("CameraClip", function(x, y, w, h)
  if not x or not y or not w or not h then
    camera()
    clip()
    return
  end
  camera(-x, -y)
  clip(x, y, w, h)
end)

Camera = createComponent("Camera", function(x, y)
  if not x or not y then
    camera()
    return
  end
  camera(-x, -y)
end)

Clip = createComponent("Clip", function(x, y, w, h)
  if not x or not y or not w or not h then
    clip()
    return
  end
  clip(x, y, w, h)
end)

---@param props { text: string, x: number, y: number, color: number }
local Text = createComponent("Text", function(props)
  local text, x, y, color = props.text, props.x, props.y, props.color
  assert(type(text) == "string", "text must be a string, got " .. type(text))
  assert(type(x) == "number", "x must be a number, got " .. type(x))
  assert(type(y) == "number", "y must be a number, got " .. type(y))
  assert(type(color) == "number", "color must be a number, got " .. type(color))

  print(text, x, y, color)
end)

---@param props { x1: number, y1: number, x2: number, y2: number, color: number, children?: table }
local Rectfill = createComponent("Rectfill", function(props)
  local x1, y1, x2, y2, color, children = props.x1, props.y1, props.x2, props.y2, props.color, props.children
  assert(type(x1) == "number", "x1 must be a number, got " .. type(x1))
  assert(type(y1) == "number", "y1 must be a number, got " .. type(y1))
  assert(type(x2) == "number", "x2 must be a number, got " .. type(x2))
  assert(type(y2) == "number", "y2 must be a number, got " .. type(y2))
  assert(type(color) == "number", "color must be a number, got " .. type(color))

  rectfill(x1, y1, x2, y2, color)
  return { children }
end)

function getCameraClip()
  local clipx1, clipy1, clipx2, clipy2 = peek2(0x5528, 4)
  --printh("x1: " .. clipx1 .. " y1: " .. clipy1 .. " x2: " .. clipx2 .. " y2: " .. clipy2)
  local camerax, cameray = peek4(0x5510, 2)
  --printh("camerax: " .. camerax .. " cameray: " .. cameray)
  return { clipx1 = clipx1, clipy1 = clipy1, clipx2 = clipx2, clipy2 = clipy2, camerax = camerax, cameray = cameray }
end

function setCameraClip(state)
  poke2(0x5528, state.clipx1, state.clipy1, state.clipx2, state.clipy2)
  poke4(0x5510, state.camerax, state.cameray)
end

Pane = createComponent("Pane", function(x, y, width, height, color, children)
  rectfill(x, y, x + width, y + height, color)

  local parentCameraClipState = getCameraClip()

  return {
    CameraClip(x + parentCameraClipState.clipx1, y + parentCameraClipState.clipy1, width, height),
    children,
    { setCameraClip, parentCameraClipState }
  }
end)

function usePaneMouse(clip)
  local mouse = useMouse()
  -- TODO: Fix useMouse leftClicked and rightClicked triggering on drag release?

  local isMouseWithinPane = clip.x1 <= mouse.x and mouse.x <= clip.x2
      and clip.y1 <= mouse.y and mouse.y <= clip.y2

  -- TODO: Make mouse clicks only trigger within the pane?
  mouse.x -= clip.x1
  mouse.y -= clip.y1
  mouse.wheel_x = isMouseWithinPane and mouse.wheel_x or 0
  mouse.wheel_y = isMouseWithinPane and mouse.wheel_y or 0
  return mouse
end

ScrollablePane = createComponent("ScrollablePane", function(props)
  local x, y, width, height, color, scrollableX, scrollableY, children = props.x, props.y, props.width, props.height,
      props.color, props.scrollableX, props.scrollableY, props.children

  local parentCameraClipState = getCameraClip()
  local clipX = x + parentCameraClipState.clipx1
  local clipY = y + parentCameraClipState.clipy1

  local mouse = usePaneMouse({
    x1 = clipX,
    y1 = clipY,
    x2 = clipX + width,
    y2 = clipY + height
  })

  local state = useState({
    scrollX = 0,
    scrollY = 0
  })
  if scrollableX then state.scrollX += mouse.wheel_x end
  if scrollableY then state.scrollY += mouse.wheel_y end

  return {
    { rectfill,      x,                    y, x + width, y + height, color },
    Clip(clipX, clipY, width, height),
    Camera(clipX + state.scrollX, clipY + state.scrollY, width, height),
    children,
    { setCameraClip, parentCameraClipState }
  }
end)

App = createComponent("App", function()
  cls(7)
  return {
    MouseProvider({
      Pane(25, 25, 100, 100, 8, {
        Text({
          text =
          "Hello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world",
          x = 0,
          y = 0,
          color = 1
        }),
        Pane(50, 50, 25, 25, 24, {
          Text({
            text = "ABCDEFG\nABCDEFG\nABCDEFG\nABCDEFG\nABCDEFG",
            x = 0,
            y = 0,
            color = 1
          })
        }),
      }),
      ScrollablePane({
        x = 150,
        y = 25,
        width = 100,
        height = 100,
        scrollableX = true,
        scrollableY = true,
        color = 9,
        children = {
          Text({
            text =
            "Hello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world\nHello world hello world hello world",
            x = 0,
            y = 0,
            color = 1
          }),
          ScrollablePane({
            x = 10,
            y = 10,
            width = 50,
            height = 50,
            scrollableX = false,
            scrollableY = false,
            color = 10,
            children = {
              Text({
                text = "ABCDEFG\nABCDEFG\nABCDEFG\nABCDEFG\nABCDEFG",
                x = 0,
                y = 0,
                color = 1
              })
            }
          })
        }
      }),
    })
  }
end)

function _draw()
  -- TODO: Remove: If CTRL+R is pressed, restart process
  if (key "alt" and keyp "r") then
    send_message(2, { event = "restart_process", proc_id = pid() })
  end
  renderRoot(App)
end
