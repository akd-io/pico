include("/lib/describe.lua")

-- pwd means present working directory.
-- In contrast to conventions of cwd (current working directory)
-- and pwd (print working directory) in other systems,
-- picotron's pwd holds the location of the script being run.
print("pwd: " .. pwd())
printh("pwd: " .. pwd())

-- env().path holds the directory from which the script was run.
-- This is what other system normally call cwd (current working directory).
print("env(): " .. describe(env())) -- env().path holds the directory from which the script was run
printh("env(): " .. describe(env()))

--[[
  Output when run from `/` with command `projects/pwd-env-test.lua`
  [024] pwd: /projects
  [024] env(): {
    "path" = "/",
    "parent_pid" = 17,
    "print_to_proc_id" = 17,
    "argv" = {
      0 = "/projects/pwd-env-test.lua",
    },
    "fileview" = [],
    "window_attribs" = {
      "show_in_workspace" = true,
    },
  }

  Output when run from `/projects` with command `pwd-env-test.lua`
  [025] pwd: /projects
  [025] env(): {
    "path" = "/projects",
    "parent_pid" = 17,
    "print_to_proc_id" = 17,
    "argv" = {
      0 = "/projects/pwd-env-test.lua",
    },
    "fileview" = [],
    "window_attribs" = {
      "show_in_workspace" = true,
    },
  }
]]
