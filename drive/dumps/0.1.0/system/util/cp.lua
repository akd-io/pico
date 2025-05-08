--[[pod_format="raw",created="2024-03-08 02:33:40",modified="2024-03-14 04:15:12",revision=17]]
--[[
	cp src dest

	to do:
		-r recursive // cp is currently recursive though!
		how to do interactive copying? (prompt for overwrite)
]]

cd(env().path)
local argv = env().argv

if (argv[1] == "--help") then
	?"usage: cp [options] src dest"
	?"options:"
	?"-o overwrite folders (instead of copying inside)"
	?"-n no clobber (do not overwrite existing files)"
	exit(0)
end


local overwrite_folder = false
local no_clobber = false

local files = {}

for i=1,#argv do
	local v = argv[i]
	if (sub(v,1,1) == "-") then
		if (v == "-o") overwrite_folder = true
		if (v == "-n") no_clobber = true
	else
		add(files, v)
	end
end

local src = files[1]
local dest = files[2]

if (not src or not dest) then
	print("usage: cp [options] src dest")
	exit(1)
end

local src_type  = fstat(src)
local dest_type = fstat(dest)

if (not src_type) then
	print("could not find "..src)
	exit(1)
end

-------

-- when destination is a folder, put /inside/ the folder instead of copying over it
if (dest_type == "folder" and not overwrite_folder) then
	if (sub(dest,-1,-1) == "/") then
		copy_inside = true -- take as an explicit indication (when copying p64)
		dest = sub(dest,1,-2) -- cut off trailing /
	end
	local segs = split(src,"/",false)
	dest = dest .. "/" .. segs[#segs]
	dest_type = fstat(dest) -- update 
end

if (no_clobber and fstat(dest)) then
	print("skipping copy over existing file: "..dest)
	exit(0)
end

-- refuse to copy a folder over a folder
if src_type  == "folder" and sub(src:ext(), 1,3) == "p64" and 
   dest_type == "folder" and sub(dest:ext(),1,3) == "p64" and
   not overwrite_folder and
   not copy_inside
then

	print("ambiguous! no action taken")
	print("  to copy inside: cp a.p64 b.p64/")
	print("  to overwrite: cp -o a.p64 b.p64")
	exit(1)
	
else
	print("copying "..src.." to "..dest)
	cp(src, dest)
end



