function printPrint(str)
  print(str)
  if stat(315) == 0 then
    -- Only `printh()`, if not running as headless script to prevent duplicate
    -- logs, as `print()` already prints to host console when running as
    -- in headless mode, and `printh()` prints to host console in both modes.
    printh(str)
  end
end
