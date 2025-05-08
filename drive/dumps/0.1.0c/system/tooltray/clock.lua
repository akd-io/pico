--[[pod_format="raw",created="2024-03-10 04:01:54",modified="2024-03-10 04:04:33",revision=4]]

-- timezones not implemented yet! everything is stored/shown in GMT
show_date = false
function _draw()

	cls(0)
	if show_date then
		print(date():sub(1,10),0,0,13)
	else
		print(date():sub(12).."\fg GMT",0,0,13)
	end

	poke(0x547d,0xff) -- wm draw mask; colour 0 is transparent

end

function _update()
	mx,my,mb = mouse()
	if (mb > 0 and last_mb == 0) show_date = not show_date
	last_mb = mb
end
