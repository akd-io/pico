--[[

	resources.lua

	on program boot, load everything in gfx/[0..9].gfx

	later: maybe also sfx

]]


local function _autoload_resources()

	--printh("autoloading..")
	
	local gfx_files = ls("gfx")
	if (not gfx_files or #gfx_files == 0) then return end

	for i=1,#gfx_files do
		local fn=gfx_files[i]
		local num = tonum(string.sub(fn,1,1))
		fn = "gfx/"..fn
		if (num and num >= 0 and num <= 63) then

			--printh("fetchin' "..fn)
			local gfx_dat = fetch(fn)
			if (type(gfx_dat) == "userdata") then
				local w,h = fstat(gfx_dat)

				w = w // 16
				h = h // 16

				--printh("cel w "..w)

				-- load sprite bank from gfx_dat
				for y=0,15 do
					for x=0,15 do
						local sprite = userdata("u8",w,h)
						blit(gfx_dat, sprite, x*w, y*h, 0, 0, w, h)

						--printh("## found "..found.." pixels")

						--set(sprite,2,2,14) -- test pixel
						set_spr(x + y * 16 + num * 256, sprite); --> hrrm
					end
				end

			elseif (type(gfx_dat == "table") and gfx_dat[0] and gfx_dat[0].bmp) then

				-- format saved by sprite editor
				-- sprite flags are written to 0xc000 + index

				for i=0,#gfx_dat do
					set_spr(num * 256 + i, gfx_dat[i].bmp, gfx_dat[i].flags or 0)
				end
			end

		end
	end


	-- load default map layer if there is one (for PICO-8 style map())
	-- map0.map for dev legacy -- should use 0.map
	local mm = fetch("map/0.map") or fetch("map/map0.map")

	-- dev legacy
	if (mm and mm.layer) then
		if (mm.layer[0] and mm.layer[0].bmp) map(mm.layer[0].bmp, true) ?"legacy map"
	end

	-- 0.1 version: layers are in file root
	if (mm) then
		if (mm[1] and mm[1].bmp) map(mm[1].bmp, true)
	end


	-- load default sound bank
	local ss = fetch("sfx/0.sfx")
	if type(ss) == "userdata" then
		for i=0,2 do
			poke(0x30000+i*0x10000, get(ss,i*0x10000,0x10000))
		end
	end

end


-- only autoload in the context of running cproj or a .p64?
-- update: can autoload when running a .lua file -- can run main.lua from commandline

--if pwd() == "/ram/cart" or sub(pwd(),-4) == ".p64" then -- update: wrong now anyway
	if (_autoload_resources) then
		_autoload_resources()
	end
--end 


