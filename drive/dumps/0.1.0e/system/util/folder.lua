--[[pod_format="raw",created="2023-29-10 02:29:44",modified="2023-29-10 02:29:44",revision=0]]
cd(env().path)
local path = fullpath(env().argv[1] or ".")

-- send a message to process manager
send_message(2, {event="open_host_path", path = path})
