--[[pod_format="raw",created="2025-04-03 22:04:50",modified="2025-04-03 22:06:48",revision=3]]

--[[
  `wm.lua` is hard to patch, because it is run before user's startup script is
  run. This cart calls `restart_process` on `wm.lua` to prove it's possible to
  patch `wm.lua` by restarting it afterwards.
  A lot of work might go into finding out how to restart it without breaking.

  TODO:
  - Try to fix `wm.lua` restart by also restarting `pm.lua`?
  - Otherwise, try fixing the errors thrown by `wm.lua` one by one.
    - First error leaves no stack trace but reads `[no workspaces found] 0`,
      which string only occurs once here:
      `wm.lua`
      `1962,27: 		if (time() > 3) print("[no workspaces found] "..#workspace,20,20,13)`
      - Maybe try getting more info by replacing that print statement with a
        print of all procceses to see what's running?
        - Print a trace too?
]]

send_message(2, { event = "restart_process", proc_id = 3 })
