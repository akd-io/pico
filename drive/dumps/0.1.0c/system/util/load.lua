--[[pod_format="raw",created="2024-03-14 19:41:44",modified="2024-03-18 19:25:51",revision=2]]
--[[
	load
		copy to /ram/cart
]]

cd(env().path)

local argv = env().argv
if (#argv < 1) then
	print("usage: load filename -- can be file or directory")
	exit(1)
end


filename = argv[1]


-- bbs cart?

if (filename:sub(1,1) == "#") then
	-- print("downloading..")
	local cart_id = filename:sub(2)
	local cart_png, err = fetch("https://www.lexaloffle.com/bbs/get_cart.php?cat=8&lid="..cart_id)  -- ***** this is not a public api! [yet?] *****
	--local cart_png = fetch("http://localhost/bbs/get_cart.php?cat=8&lid="..cart_id)

	if (err) print(err)

	if (type(cart_png) == "string" and #cart_png > 0) then
		print(#cart_png.." bytes")
		-- rm "/ram/bbs_cart.p64.png" -- unmount. deleteme -- should be unnecessary
		store("/ram/bbs_cart.p64.png", cart_png)

		-- switcheroony
		filename = "/ram/bbs_cart.p64.png"
	else
		print("download failed")
		exit(0)
	end
end


attrib = fstat(filename)
if (attrib ~= "folder") then
	-- doesn't exist or a file --> try with .p64 extension
	filename = filename..".p64"
	if (fstat(filename) ~= "folder") then
		print("could not load")
		exit(1)
	end
end


-- remove currently loaded cartridge
rm("/ram/cart")

-- create new one
local result = cp(filename, "/ram/cart")
if (result) then
	print(result)
	exit(1)
end

-- set current project filename

store("/ram/system/pwc.pod", fullpath(filename))


-- tell window manager to clear out all workspaces
send_message(3, {event="clear_project_workspaces"})



dat = fetch_metadata("/ram/cart")
if (dat) dat = dat.workspaces

--[[ deleteme
	dat = fetch("/ram/cart".."/.workspaces.pod")
	if (not dat) printh("*** could not find\n")
]]

-- legacy location;  to do: deleteme
if (not dat) then
	dat = fetch("/ram/cart/_meta/workspaces.pod")
	if (dat) printh("** fixme: using legacy _meta/workspaces.pod")
end

-- legacy location;  to do: deleteme
if (not dat) then
	dat = fetch("/ram/cart/workspaces.pod")
	if (dat) printh("** fixme: found /workspaces.pod")
end


if (type(dat) == "table") then

	-- open in background (don't show in workspace)
	local edit_argv = {"-b"}

	for i=1,#dat do

		local ti = dat[i]
		local location = ti.location or ti.cproj_file -- cproj_file is dev legacy
		if (location) then

			-- separate the filename part of the location (/foo.lua#33 -> /foo.lua)
			-- local filename = split(location, "#", false)[1]  -- commented; includes the location string

			-- printh("@@ opening ".."/ram/cart/"..location)
			add(edit_argv, "/ram/cart/"..location)

		end
	end

	-- open all at once
	create_process("/system/util/open.lua",
		{
			argv = edit_argv,
			pwd = "/ram/cart"
		}
	)

end

print("loaded "..filename.." into /ram/cart")


