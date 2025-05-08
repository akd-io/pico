window(200, 100)

updates = 0
function _update()
  updates += 1
end

function _update60()
  printh("Hello")
end

draws = 0
function _draw()
  draws += 1

  cls(0)
  color(7)
  print("updates: " .. draws)
  print("draws: " .. draws)
  print("stat(7): " .. stat(7))
  print("stat(330): " .. stat(330))
end
