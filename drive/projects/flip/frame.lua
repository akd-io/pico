window(200, 50)

local frame = 0
function _draw()
  frame += 1
  cls()
  print("frame: " .. frame)
end
