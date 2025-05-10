--[[pod_format="raw",created="2025-03-30 21:12:50",modified="2025-04-03 20:57:53",revision=12]]

local messageType = "gfx" -- "gfx" or "string"

local messageLength = 700
local messagesPerFrame = 50

local gfx51x51 = --[[pod_type="gfx"]] unpod(
  "b64:bHo0ABkFAAAYBQAA8v8wcHh1AEMgMzMEAB8fFz8UiQ4PEx4YDg8SEB8TABQdBD8fRAAHMAccTggpHAANDA8SAA0OAAwIHgQdJB0QDAAMYAcwDgweEB4IIDkNCwQNBA4cCAsdLxsNfmAHMAwOFB4ECBQcBwwAeY75Ag4MEB4HCBcADAscCo4NJS0FTDUYZRwADgcQCI4dHgwOHRgOPRwOHD4YZwAcfgwODE4NDgUMDSoIzRgHMBcABy4nCAcOPE4NHgwqCwg9LAAMIAgtFwBJHxUwCB4MDgw_Cy06Bws9PAAMEGlfFxwvFQgeLAslGw1KDAodrn8Xni8VfiouGr4vF54fEHEvFQsgGg0pIYocHxd1HxkfEBgcHggeHAEvFQkKKQEMLg0hHBgFDS8XRRAfGS8QGBwOGggKLCkvFQsdLjEPHQshCAAfFw0MJQ4QPADwCgAMAA4YOR4aAS8VHkENCgwKHx0xCh0KLg8eAPAHGgwHAElBGi4NLxUOLQwdDAQ-FwgxHRsA8AQAOgwAFwkhDhwOKgAfHR0FDC8VBwHxah8XDlgxDxAaLgw_DAAIABw6Cx8dHRotLxUeAB8XDhgMDgwODC8QMR4cHhgMCggKDBoOHx0LAC0ALQYeLxUPFx4NCBwGGh8QBxgLCDEoBwAMGBoGHhoLLQstBh4EDh8XHxUIHiofEAwYDhsOCwANMRcZGgwADiBdDCp7APH-0gofFRofEC4IDhsADgsMAAcdIQwaGR4gDQYtDAcgDUofFw8ZHxUPEC8ZPqMNCAocDjkNCy0LDARKUx8QDB8VDAcMCgsKTkMODQEKDAAeFjlKIwweDAgOHxAIDAgTHxVjXigKTxcTSikAHRwWCB8QCignDQQfFQUGBQwqDgc_AAoTSgcdByFZER8QERgMFwAMDQwFHxUcJRoICggeOm0ACwwLLQwGCh8QObEPFQEQBxgKGAoACB5dCAsNCwwtHAofEAAoeQsMDQ4MDqEMHl0YTQYMCRLZ0R4MEE1xCRKRFR5MDQYYJgg_DTNBBQsNORIFABgODAcMFQwaBgs8CwY9Pj0ELXMJHRIHKA4FLAocJgscXS4dDC0GrQkDEkMVCgytCxgHLgAIFj0OLxcdBhoOLRIJTXMLEAsAHAgHDg0OFhgAHR4dDwEdTxctEggpCEYMJgwzDBgGHQYOEAg9DgYFAF8BDg0fFwKRGRwEHAsECwwTLS4ACB0FDRYuLQUOLwESChgLGAUdDxsGwQ1FDh0FHQYVEB0FFw0HEgxaHg0OFwwHHCcZAxnxAQ0nLQAMGBAoSgwUDgweCB0TDAdJDklHDRAtACgMEAgOCAAeBA1KCB0PBx8SDAMQCA0uBQYNHkkNACAA8P8VBAgOCB4UDQwgCFocAx0AHgQGHQ8HWQg9GBwkCA8SABgEEAwNAAUdDAUOGzoDCh5pHhwOPRgEHAAUCAseCB4FDA0IHQwUGwQLHRMeGQodIAccFy0YABwkDggLBgUIFQwEHQAcABsQHRMOWgwnHCAIDQgkHBQOCA4LFhgADC1aGRMeGgYXHQwUHBQQDQgU_gQACzkTHicOEA0EDAQcJBBKHBAOGAULHwcGCA0OABw5CB0DHhAOBA4EHTxQDUAMAB4IAgULEAgNCBYMGQsYBw0uDBQOAA4ADTBeDQhQAh4IAAULBQgNCBUMGRgVLgUcRR01TgUNCCckHgQ4HUgJGBUeBQMHDDcAHSAiACUODQgiZxgdBwwIDAcLCRceJwMHDEUNhSAN")

--[[
| gfx width | gfx height | Primary CPU | Secondary CPU | Notes
|-----------|------------|-------------|---------------|-------
|        51 |         51 |       0.004 |         0.009 | Dropping FPS


| messageLength | messagesPerFrame | Primary CPU | Secondary CPU | Notes
|---------------|------------------|-------------|---------------|-------
|             1 |                1 |       0.004 |         0.009 |
|             1 |               10 |       0.010 |         0.015 |
|             1 |               50 |       0.038 |         0.042 |
|            10 |               50 |       0.040 |         0.042 |
|           100 |               50 |       0.060 |         0.047 |
|           650 |               50 |       0.183 |         0.073 | On the brink of dropping FPS
|           700 |               50 |       0.194 |         0.031 | Secondary starts to drop FPS, and messages handles per frame becomes inconsistent
|          1000 |               50 |       0.261 |         0.051 |
|          2592 |               50 |       0.369 |         0.041 | 2592 / 50 = 480 x 270
|         10000 |               50 |         n/a |           n/a | Primary's FPS drops massively
]]

include("/lib/describe.lua")

local environment = env()
local thisScriptPath = environment.argv[0]
local processType = (environment.argv[1] == nil) and "primary" or "secondary"

window({
  width = 80,
  height = 30,
  title = pid() .. " " .. processType,
})

local message = messageType == "gfx" and gfx51x51 or string.rep("a", messageLength)

local state

local functionMap = {
  primary = {
    _init = function()
      printh("Primary init")
      printh("Primary env: " .. describe(env()))
      state = {
        secondaryPid = create_process(thisScriptPath, { argv = { "secondary" } }),
        total = 0,
      }
    end,
    _draw = function()
      for _ = 1, messagesPerFrame do
        send_message(state.secondaryPid, { event = "ping", message = message })
      end
      state.total += messagesPerFrame
      cls()
      print("Total: " .. state.total .. "\n" .. "This frame: " .. messagesPerFrame, 0, 0)
    end
  },
  secondary = {
    _init = function()
      printh("Secondary init")
      printh("Secondary env: " .. describe(env()))
      state = {
        total = 0,
        lastFrame = 0,
        lastMessageLength = 0,
      }
      on_event("ping", function(response)
        state.total += 1
        state.lastFrame += 1
        --state.lastMessageLength = #response.message
        --printh("[send-message-cpu-usage] " .. type(response.message))
      end)
    end,
    _draw = function()
      cls()
      print("Total: " .. state.total ..
        "\nLast frame: " .. state.lastFrame ..
        "\nLast msg len: " .. state.lastMessageLength, 0, 0)
      state.lastFrame = 0
    end
  }
}

local functions = functionMap[processType]
_init = functions._init
_draw = functions._draw
