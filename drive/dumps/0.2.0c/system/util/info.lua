-- info.lua: show info about the present working cartridge (/ram/cart)

-- (dupe from save.lua) save all files and metadata
-- hack: need to wait to complete at each step. to do: need the concept of a blocking message
send_message(3, {event="save_working_cart_files"})
for i=1,12 do flip() end
send_message(3, {event="save_open_locations_metadata"})
for i=1,4 do flip() end


local pwc = fetch("/ram/system/pwc.pod")

mkdir("/ram/temp") -- to do: should be allowed to assume this exists?
cp("/ram/cart", "/ram/temp/cartsize.p64.rom")
kind, size = fstat("/ram/temp/cartsize.p64.rom")


print("\fecurrent cartridge: "..pwc)
if (size) print(size.." bytes")

