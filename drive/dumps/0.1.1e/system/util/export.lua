--[[pod_format="raw",created="2024-08-02 21:52:44",modified="2024-08-05 01:31:27",revision=149]]
--[[

	html exporter

]]

cd(env().path)

p64_file = "/ram/cart" -- to do: allow export something else

pwc = fetch"/ram/system/pwc.pod"
if (pwc) then
	out_file = pwc:basename()..".html"
else
	out_file = "out.html"
end

if (env().argv[1]) out_file = env().argv[1]


-- make sure it is .p64.rom
rm("/ram/expcart.p64.rom") -- safety; to do: shouldn't be necessary
cp(p64_file, "/ram/expcart.p64.rom")


-- *** need to flush here! ***
--[[
print("waiting to flush..")
for i=1,120 do flip() end
]]

dat = fetch"/ram/expcart.p64.rom"

local shell_str = fetch("/system/exp/exp_html.p64.rom/shell.html")

-- grab metadata

meta = fetch_metadata(p64_file) or {}
title = meta.title or "Picotron Cartridge"

print(title)

shell_str = shell_str:gsub("##page_title##", title)

-- generate label if there is one
if (fstat(p64_file.."/label.png")) then
	cp(p64_file.."/label.png", "/ram/label.bin")
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
--store(out_file, 
--	shell_str:gsub("##pcart##", picotron_js),
--	{metadata_format="none"})

-- to do: file appending; otherwise size of cart that can be exported
-- is extra limited by these string operations

local q = string.find(shell_str, "##pcart##") + 10

store(out_file, 
	shell_str:sub(1,q)..picotron_js..shell_str:sub(q+1),
	{metadata_format="none"})


print("wrote: "..out_file)