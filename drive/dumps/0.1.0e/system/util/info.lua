local pwc = fetch("/ram/system/pwc.pod")

mkdir("/ram/temp") -- to do: should be allowed to assume this exists?
cp("/ram/cart", "/ram/temp/cartsize.p64.rom")
kind, size = fstat("/ram/temp/cartsize.p64.rom")


print("current cartridge: "..pwc)
if (size) print(size.." bytes")

