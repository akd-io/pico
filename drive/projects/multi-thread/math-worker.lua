--[[pod_format="raw",created="2025-03-30 21:12:50",modified="2025-03-31 11:24:42",revision=10]]

include("/lib/describe.lua")

on_event("add", function(request)
  printh("Received request:")
  printh("[math-worker] " .. describe(request))
  local result = request.a + request.b
  local response = { event = "add_result", result = result }
  printh("Sending response:")
  printh("[math-worker] " .. describe(response))
  send_message(request._from, response)
end)

function _update() end
