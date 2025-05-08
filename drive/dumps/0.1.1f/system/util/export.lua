--[[pod_format="raw",created="2024-08-02 21:52:44",modified="2024-08-05 01:31:27",revision=149]]
--[[

	export:

		foo.html 
		foo.p64.png
		foo.bin
]]

cd(env().path)

src_cart = "/ram/cart" -- to do: allow export something else

local outfile = nil

for i=1,#env().argv do
	local val = env().argv[i]
	if (val[1] == "-") then
		-- some option
	else
		outfile = val
	end
end

outfile = fullpath(outfile)

ext = type(outfile) == "string" and outfile:ext() or ""

supported_ext = {
	["p64.png"] = true,
	["html"] = true,
	["bin"] = true
}

if (not outfile or not supported_ext[ext]) then
	print("export usage: export [outfile]")
	print("outfile format is depermined by extension:")
	print("  .p64.png\t png cartridge (bbs format)")
	print("  .html   \t single html file")
	print("  .bin    \t windows, linux and mac binaries")
	exit()
end

-- export .p64.png -- just copy
if (ext == "p64.png") then
	rm(outfile) -- to require -f to copy over cart?
	cp(src_cart, outfile)
	print("saved a copy as "..outfile)
	exit()
end


--- html

-- make sure it is .p64.rom
rm("/ram/expcart.p64.rom") -- safety; to do: shouldn't be necessary
cp(src_cart, "/ram/expcart.p64.rom")

dat = fetch"/ram/expcart.p64.rom"

local shell_str = fetch("/system/exp/exp_html.p64.rom/shell.html")

-- grab metadata

meta = fetch_metadata(src_cart) or {}
title = meta.title or "Picotron Cartridge"

print(title)

shell_str = shell_str:gsub("##page_title##", title)

-- generate label if there is one
if (fstat(src_cart.."/label.png")) then
	cp(src_cart.."/label.png", "/ram/label.bin")
	labelpng = fetch"/ram/label.bin" -- fetch raw bytes without .png extension
	
	-- abuse pod() format to get base64 suitable for data url
	b64str = pod("@"..labelpng, 0x24):sub(24,-3)
	b64str = b64str:gsub("_","+")
	b64str = b64str:gsub("-","/")
	--b64str = table.concat(split(b64str,76),"\n")
	
	-- insert data url
	shell_str = shell_str:gsub("##label_file##", "data:image/png;base64,"..b64str)

end

--- generate cart+player

strs = {"\n"}

add(strs, "p64cart_str=\"")

fmt = string.rep("%02x", 1024)

for i=0,#dat\1024 do
	local idx = 1 + i*1024
	local num = min(1024, #dat - idx + 1)
	if (num > 0) then
		--print(pod{idx,num})
		if (num < 1024) fmt = string.rep("%02x", num)
		chunk = string.format(fmt, ord(dat, idx, num))
		add(strs, chunk)
	end
end
add(strs,"\"")
add(strs,";\n")

local player_str = fetch("/system/exp/exp_html.p64.rom/picotron_player.js")
add(strs, player_str)

picotron_js = table.concat(strs)

strs = nil -- free some memory for the file write

-- why doesn't this work? too big? ("invalid capture index %8")
--store(outfile, 
--	shell_str:gsub("##pcart##", picotron_js),
--	{metadata_format="none"})

-- to do: file appending; otherwise size of cart that can be exported
-- is extra limited by these string operations

local q = string.find(shell_str, "##pcart##") + 10

store(outfile, 
	shell_str:sub(1,q)..picotron_js..shell_str:sub(q+1),
	{metadata_format="none"})


print("wrote: "..outfile)
