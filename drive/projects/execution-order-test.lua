-- Execution order seems to be pids sorted in ascending order.

-- Output after running this script many times and deleting random processes throughout:
-- [037] 37
-- [038] 38
-- [040] 40
-- [041] 41
-- [043] 43
-- [045] 45
-- [047] 47
-- [049] 49
-- [051] 51
-- [053] 53
-- [055] 55
-- [056] 56
-- [057] 57
-- [058] 58
-- [059] 59
-- [061] 61
-- [062] 62
-- [064] 64
-- [065] 65

window({
  width = 60,
  height = 10,
  resizeable = true,
  moveable = true,
  has_frame = true,
  title = tostr(pid())
})

function _draw()
  printh(tostr(pid()))
end
