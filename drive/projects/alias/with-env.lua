--[[
  This script shows what `env()` looks like in both parent and child processes,
  when `env()` is used as `create_process()`'s `env_patch` parameter.

  Results:
  - Not overwritten is `parent_pid` and `argv[0]`.
  - `argv[0]` not being overwritten is great!
  - `parent_pid` not being overwritten, I don't know if will be problematic yet.
]]

include("/lib/describe.lua")
include("/lib/printPrint.lua")

printPrint("with-env.lua pwd(): " .. describe(pwd()))
printPrint("with-env.lua env(): " .. describe(env()))

create_process("/projects/alias/sub-dir/child-process.lua", env())

--[[
  Output running `alias/with-env.lua arg1 arg2` from `/projects`:

  [059] with-env.lua pwd(): "/projects/alias"
  [059] with-env.lua env(): {
    "path" = "/projects",
    "parent_pid" = 16,
    "print_to_proc_id" = 16,
    "argv" = {
      0 = "/projects/alias/with-env.lua",
      1 = "arg1",
      2 = "arg2",
    },
    "fileview" = [],
    "window_attribs" = {
      "show_in_workspace" = true,
    },
  }
  [060] child-process.lua pwd(): "/projects/alias/sub-dir"
  [060] child-process.lua env(): {
    "path" = "/projects",
    "parent_pid" = 59,
    "print_to_proc_id" = 16,
    "argv" = {
      0 = "/projects/alias/sub-dir/child-process.lua",
      1 = "arg1",
      2 = "arg2",
    },
    "fileview" = [],
    "window_attribs" = {
      "show_in_workspace" = true,
    },
  }
]]
