--[[pod_format="raw",created="2025-04-08 13:22:17",modified="2025-04-08 13:23:01",revision=8]]
--[[
  remove jettison from head.lua

  TODOs:
  - This is very dangerous. Any process, including sandboxed carts, can now
    access jettisoned functions.
    - Consider if we should surface jettisoned functions via events to `wm.lua`
      or `pm.lua` instead.
      - This will introduce delays. But this way we can have a centralized
        place for checking sandbox.
      - We can also have a whitelist of functions that can be jettisoned.
    - Maybe we can wrap jettisoned functions in a sandboxed function that
      checks if the caller is allowed to access it.
      - If not, function instead opens a popup asking the user to enable this
        function for this cart.
        - If accepted, this state is saved to disc.
          - Make sure, that functions that would allow permission escalation
            are presented as potentially allowing full access to users.
        - If rejected, function returns a rejection that the app can handle.
        - We could also provide a way to ask for permission before using the
          functions.
          - This would provide better UX, over apps calling all 10 functions
            they need up front, which could have side effects, and would maybe
            prompt the user one by one.
]]

include("/lib/literal.lua")

local pattern = literal('include("/system/lib/jettison.lua")')
--print(pattern)

--[[
  TODO:
  - Implement a toggling helper.
    - Takes a literal string and a boolean show/hide.
      - Will look for the literal string inside `--[=====[AKD-PATCHER` and `]=====]`
        - If found, state is currently `hidden`.
        - If not found, will then look for the literal only.
          - If found, will update state.
          - If not found, report error.
]]

local filePath = "/system/lib/head.lua"
local contents = fetch(filePath)
local new_contents, count = contents:gsub(pattern, "")

assert(count <= 1) -- TODO: Possible to narrow more? We want to change 1 line exactly, but if code ran already, it's not there, and count is 0.
if (count == 0) then
  print("Already patched.")
else
  store(filePath, new_contents)
  print("Patch successful.")
end
