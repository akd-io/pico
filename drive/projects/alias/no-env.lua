--[[
  This script shows what `env()` looks like in both parent and child processes,
  when no `env_patch` is passed to `create_process()`.
]]

include("/lib/describe.lua")
include("/lib/printPrint.lua")

printPrint("no-env.lua pwd(): " .. describe(pwd()))
printPrint("no-env.lua env(): " .. describe(env()))

create_process("/projects/alias/sub-dir/child-process.lua")

--[[
  Output running `alias/no-env.lua arg1 arg2` from `/projects`:

  [057] no-env.lua pwd(): "/projects/alias"
  [057] no-env.lua env(): {
    "path" = "/projects",
    "parent_pid" = 16,
    "print_to_proc_id" = 16,
    "argv" = {
      0 = "/projects/alias/no-env.lua",
      1 = "arg1",
      2 = "arg2",
    },
    "fileview" = [],
    "window_attribs" = {
      "show_in_workspace" = true,
    },
  }
  [058] child-process.lua pwd(): "/projects/alias/sub-dir"
  [058] child-process.lua env(): {
    "parent_pid" = 57,
    "argv" = {
      0 = "/projects/alias/sub-dir/child-process.lua",
    },
    "fileview" = [],
  }
]]
