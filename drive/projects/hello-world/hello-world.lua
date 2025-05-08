-- Run `picotron` from the command line to access printh logs
printh("Hello world") -- [<PID>] Hello world

window({
  width = 60,
  height = 10,
  resizeable = true,
  moveable = true,
  has_frame = true,
  title = tostr(pid())
})

function _draw()
  cls()
  print("Hello world")
end
