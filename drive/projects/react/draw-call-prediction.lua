--[[
  This program tries to predict, if a `_draw()` call will happen after the current `_update()` call.

  CPU throttling logic is based on drive/projects/cpu-usage.lua
]]

window({
  width = 200,
  height = 200,
  resizeable = true,
  moveable = true,
  has_frame = true,
  title = "Draw Call Prediction"
})

local minMag, mag, maxMag = 1, 1, 34
local btnUp, btnDown = 2, 3

-- Required Prediction variables
local prediction = "update"
local updatesThisFrame = 0

-- Stats
local statsFrameUpdates = 0 -- How many times `_update()` was called in the current frame.
local statsFrameDraws = 0   -- How many times `_draw()` was called in the current frame.
local statsTotalUpdates = 0
local statsTotalDraws = 0

-- Results variables
local correctDrawPredictions = 0     -- How many times we predicted a draw call and it happened.
local incorrectDrawPredictions = 0   -- How many times we predicted a draw call and it didn't happen.
local correctUpdatePredictions = 0   -- How many times we predicted an update call and it happened.
local incorrectUpdatePredictions = 0 -- How many times we predicted an update call and it didn't happen.

function _update()
  updatesThisFrame += 1

  statsTotalUpdates += 1
  statsFrameUpdates += 1

  if (prediction == "update") then
    correctUpdatePredictions += 1
  elseif (prediction == "draw") then
    incorrectDrawPredictions += 1
  else
    error("Unknown prediction: " .. prediction)
  end

  if btnp(btnUp) then mag = mid(minMag, mag + 1, maxMag) end
  if btnp(btnDown) then mag = mid(minMag, mag - 1, maxMag) end


  --- `predictedUpdatesThisFrame` is based on this code from `foot.lua`:
  --- ```lua
  --- _update()
  --- local fps = stat(7)
  --- if (fps < 60) __process_event_messages() _update()
  --- if (fps < 30) __process_event_messages() _update()
  --- ```
  local fps = stat(7)
  local predictedUpdatesThisFrame = fps < 30 and 3 or fps < 60 and 2 or 1

  if (updatesThisFrame == predictedUpdatesThisFrame) then
    prediction = "draw"
    -- ! Frameworks rendering exclusively in `_update` can run their draw code here, instead of in `_draw`.
    updatesThisFrame = 0
  else
    prediction = "update"
  end
end

function _draw()
  statsTotalDraws += 1
  statsFrameDraws += 1

  if (prediction == "draw") then
    correctDrawPredictions += 1
  elseif (prediction == "update") then
    incorrectUpdatePredictions += 1
  else
    error("Unknown prediction: " .. prediction)
  end


  cls()

  print("totalUpdate: " .. statsTotalUpdates)
  print("totalDraw: " .. statsTotalDraws)
  print("frameUpdates: " .. statsFrameUpdates)
  print("frameDraws: " .. statsFrameDraws)
  print("correctDrawPredictions: " .. correctDrawPredictions)
  print("incorrectDrawPredictions: " .. incorrectDrawPredictions)
  print("correctUpdatePredictions: " .. correctUpdatePredictions)
  print("incorrectUpdatePredictions: " .. incorrectUpdatePredictions)
  print("FPS (pre): " .. stat(7))
  print("CPU (pre): " .. stat(1))

  local n = flr(1.5 ^ mag)
  for i = 1, n do
    -- Do nothing.
  end

  print("CPU (post): " .. stat(1))
  print("FPS (post): " .. stat(7))
  print("mag: " .. mag)
  print("n: " .. n)

  prediction = "update"
  statsFrameUpdates = 0
  statsFrameDraws = 0
end
