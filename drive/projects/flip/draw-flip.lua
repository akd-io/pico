window(200, 50)

local frame = 0
function _draw()
  frame += 1
  cls()
  print("frame: " .. frame)
  print("_draw")
  if (btn(0)) then
    printh("Button 0 pressed!")
    for i = 0, 120 do
      print("flip")
      flip()
      frame += 1
    end
    printh("Done!")
  end
end
