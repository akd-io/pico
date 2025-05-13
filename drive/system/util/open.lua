--[[pod_format="raw",created="2024-10-08 23:47:10",modified="2024-11-20 20:35:50",revision=4]]
--[[

	edit a file

	choose an editor based on extension [and possibly content if needed]

	** never runs the file -- up to caller to manage that depending on context **

	used by:
		filenav.p64: double click on file
		load.lua: to restore workspace tabs
		open() // can be used from sandboxed programs

]]

cd(env().path)


local argv = env().argv
if (#argv < 1) then
	print("usage: edit filename")
	exit(1)
end

-- future: could be a list per extension (open a chooser widget)

local prog_for_ext = fetch("/appdata/system/default_apps.pod")

if (type(prog_for_ext) ~= "table") prog_for_ext = {}

prog_for_ext.lua   = prog_for_ext.lua   or "/system/apps/code.p64"
prog_for_ext.txt   = prog_for_ext.txt   or "/system/apps/notebook.p64"
prog_for_ext.pn    = prog_for_ext.pn    or "/system/apps/notebook.p64"
prog_for_ext.gfx   = prog_for_ext.gfx   or "/system/apps/gfx.p64"
prog_for_ext.map   = prog_for_ext.map   or "/system/apps/map.p64"
prog_for_ext.sfx   = prog_for_ext.sfx   or "/system/apps/sfx.p64"
prog_for_ext.pod   = prog_for_ext.pod   or "/system/apps/podtree.p64"
prog_for_ext.theme = prog_for_ext.theme or "/system/apps/themed.p64"


local show_in_workspace = true

for i = 1, #argv do

	if (argv[i] == "-b") then
		-- open in background
		show_in_workspace = false
	else

		filename = fullpath(argv[i])
		


		if (fstat(filename) == "folder") then

			-- open folder / cartridge
			create_process("/system/apps/filenav.p64", 
			{
				argv = {filename},
				window_attribs = {show_in_workspace = show_in_workspace}
			})

		else

			local prog_name = prog_for_ext[filename:ext()]
			if (not prog_name) then
				-- no preferred program to open with; check metadata for recommended bbs:// program
				-- (bbs:// only -- maybe dangerous to allow un-sandboxed programs to open a file that 
				-- could be crafted to exploit some weakness in that program's loader)
				-- note: bbs program includes the version number! could optionally strip it here
				-- to do: run most recent version by default? [if online]
				local meta = fetch_metadata(filename)
				if (meta and meta.prog and meta.prog:prot() == "bbs") prog_name = meta.prog
			end

			if (prog_name) then

				create_process(prog_name,
					{
						argv = {filename},
						fileview = {{location=filename, mode="RW"}}, -- let sandboxed app read/write file
						window_attribs = {
							show_in_workspace = show_in_workspace,
							unique_location = true -- to do: could be optional. wrangle also sets this.
						}
					}
				)

			else
				-- to do: use podtree (generic pod editor)
				print("no program found to open this file")

				notify("*** file type not found ***")
			end
		end
	end

end
