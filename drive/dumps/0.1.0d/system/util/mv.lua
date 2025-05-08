--[[

	** dangerous!
	need to check that copy succeeded before removing original
	and/or use host mv when available

]]

cd(env().path)
local argv = env().argv

if (#argv < 2) then
	print("usage: mv old new")
	exit(1)
end

local src = argv[1]
local dest = argv[2]

local segs = split(src,"/",false)

if (fstat(dest) == "folder") then
 dest = dest .. "/" .. segs[#segs]
end

mv(src, dest)

