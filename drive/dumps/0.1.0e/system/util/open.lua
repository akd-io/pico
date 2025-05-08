--[[pod_format="raw",created="2024-47-08 23:47:10",modified="2024-47-08 23:47:10",revision=0]]
--[[

	edit a file

	choose an editor based on extension [and possibly content if needed]

	** never runs the file -- up to caller to manage that depending on context **

	used by:
		filenav.p64: double click on file
		load.lua: to restore workspace tabs

]]

cd(env().path)

-- to do: could be stored in /appdata/system/util/edit.pod
-- can edit in settings
prog_for_ext =
{
	lua = "/system/apps/code.p64",
	txt = "/system/apps/notebook.p64",
	pn  = "/system/apps/notebook.p64",
	gfx = "/system/apps/gfx.p64",
	map = "/system/apps/map.p64",
	sfx = "/system/apps/sfx.p64",
	pod = "/system/apps/podtree.p64",
	theme = "/system/apps/themed.p64"
}

local argv = env().argv
if (#argv < 1) then
	print("usage: edit filename")
	exit(1)
end


local show_in_workspace = true

for i = 1, #argv do

	if (argv[i] == "-b") then
		-- open in background
		show_in_workspace = false
	else

		filename = fullpath(argv[i])
		local prog_name = prog_for_ext[filename:ext()]


		if (fstat(filename) == "folder") then

			-- open folder / cartridge
			create_process("/system/apps/filenav.p64", 
			{
				argv = {filename},
				window_attribs = {show_in_workspace = show_in_workspace}
			})

		elseif (prog_name) then

			create_process(prog_name,
				{
					argv = {filename},
					
					window_attribs = {
						show_in_workspace = show_in_workspace,
						unique_location = true, -- to do: could be optional. wrangle also sets this.
					}
				}
			)

		else
			-- to do: use podtree (generic pod editor)
			print("no program found to open this file")

			notify("* * * file type not found * * *")
		end
	end

end
