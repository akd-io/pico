--[[pod_format="raw",created="2025-04-18 23:14:10",modified="2025-04-18 23:18:49",revision=13]]
Label = createComponent("Label", function(labelUserdata, index, width, height)
  local xTargets = {
    0,
    0,
    width * 0.5 / 10,
    width * 1.5 / 10,
    width * 8.5 / 10,
    width * 9.5 / 10,
    width * 10 / 10,
    width * 10 / 10
  }

  local targetX1 = xTargets[index]
  local targetX2 = xTargets[index + 1]
  local x1 = useSpring(targetX1)
  local x2 = useSpring(targetX2)

  --local centerIndexDiff = (index - 4)
  --local spriteTargetOffsetX = 50 * centerIndexDiff
  local spriteTargetOffsetX = (-width / 2) + x1 + ((x2 - x1) / 2)
  --local spriteOffsetX = useSpring(spriteTargetOffsetX)
  local spriteOffsetX = spriteTargetOffsetX

  local halfPixelOffset = 0.5 -- Used to prevent spring positions oscillating around pixel boundaries.

  palt(0)                     -- Treat all colors as opaque.
  clip(x1 + halfPixelOffset, 0, x2 + halfPixelOffset, height)
  spr(labelUserdata, spriteOffsetX + halfPixelOffset, 0)
end)
