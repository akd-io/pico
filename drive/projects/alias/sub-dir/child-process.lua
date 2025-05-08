include("/lib/describe.lua")
include("/lib/printPrint.lua")

printPrint("child-process.lua pwd(): " .. describe(pwd()))
printPrint("child-process.lua env(): " .. describe(env()))
