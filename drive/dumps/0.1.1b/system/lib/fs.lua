--[[

	fs.lua

	filesystem / pod

]]


do

	local _env = env
	local _sandboxed = _env().sandboxed

	local _fetch_local = _fetch_local
	local _fetch_remote = _fetch_remote
	local _fetch_anywhen = _fetch_anywhen
	local _fetch_remote_result = _fetch_remote_result
	local _store_local = _store_local
	local _fetch_metadata_from_file = _fetch_metadata_from_file
	local _store_metadata_str_to_file = _store_metadata_str_to_file
	local _pod = _pod
	local _fstat = _fstat
	local _pwd = _pwd
	local _mount = mount
	local _cd = _cd
	local _rm = _rm
	local _cp = _cp
	local _mv = _mv
	local _ls = _ls

	local _fcopy = _fcopy
	local _fdelete = _fdelete
	local _fullpath = _fullpath
	local _mkdir = _mkdir

	local _split = split
	local _printh = _printh

	----------------------------------------------------------------------------------------------------------------------------------
	-- path remapping
	--
	-- rule: local functions (_mkdir) all take raw paths, global functions (mkdir) takes sandboxed paths 
	----------------------------------------------------------------------------------------------------------------------------------

	-- to do: handle protocols here? 
	-- currently not needed, but would allow moving sandbox_path call to front of each disk op function to be clearer


	local function path_is_inside(path, container_path)
		local len = #container_path -- the shorter string
		return path:sub(1,len) == container_path and (#path == len or path[len + 1] == "/")
	end


	-- raw path -> sandboxed path
	local function _sandbox_path(path, writing)

		if (not _sandboxed) return path

		path = _fullpath(path) -- raw fullpath
		if (type(path) ~= "string") return nil -- couldn't resolve, or nil to start with

		if (not writing) then

			-- 1. read /system
			if (path_is_inside(path, "/system")) return path
			if (path_is_inside(path, "/appdata/system")) return path
			if (path_is_inside(path, _env().prog_name:dirname())) return path
			if (path_is_inside(path, "/ram/shared")) return path

		end

		-- read/write /appdata/shared and /appdata (remapped)
		if (path_is_inside(path, "/appdata/shared")) return path

		-- /appdata (but not /appdata/shared, which doesn't get mapped)
		if (path_is_inside(path, "/appdata") and _env().cart_id) then
			local cart_id_base = split(_env().cart_id, "-", false)[1] -- don't include the version
			--printh("cart_id_base: "..cart_id_base);
			_mkdir("/appdata/bbs/"..cart_id_base) -- make sure it exists
			return "/appdata/bbs/"..cart_id_base..path:sub(9)
		end
		
		--printh("no access from sandbox: "..path)

		-- anything else not allowed
		return nil
	end

	-- sandboxed -> raw path
	-- when raw pwd is "/ram/appdata/bbs/cart_id", a sandboxed pwd() should return "/ram/appdata"
	local function _un_sandbox_path(path)
		if (type(path) ~= "string") return nil
		
		-- /appdata mapping only when cart_id is set
		if (path:sub(1,9) == "/appdata/bbs/" and _env().cart_id)
		then  
			local cart_id_base = split(_env().cart_id, "-", false)[1] -- don't include the version
			local cart_dir = "/appdata/bbs/"..cart_id_base..path:sub(9)
			local cart_dir_len0 = #cart_dir
			local cart_dir_len1 = #cart_dir + 1
			if path:sub(1, cart_dir_len0) == cart_dir and (#path == cart_dir_len0 or path[cart_dir_len1] == "/") then
				return "/appdata"..path:sub(cart_dir_len1)
			end
		end

		-- return as-is
		return path
	end

	--------------------------------------------------------------------------------------------------------------------------------

		-- generate metadata string in plain text pod format
	local function _generate_meta_str(meta_p)

		-- use a copy so that can remove pod_format without sideffect
		local meta = unpod(pod(meta_p)) or {}

		local meta_str = "--[["

		if (meta.pod_format and type(meta.pod_format) == "string") then
			meta_str ..= "pod_format=\""..meta.pod_format.."\""
			meta.pod_format = nil -- don't write twice
		elseif (meta.pod_type and type(meta.pod_type) == "string") then
			meta_str ..= "pod_type=\""..meta.pod_type.."\""
			meta.pod_type = nil -- don't write twice
		else
			meta_str ..= "pod"
		end

		local meta_str1 = _pod(meta, 0x0) -- 0x0: metadata always plain text. want to read it!

		if (meta_str1 and #meta_str1 > 2) then
			meta_str1 = sub(meta_str1, 2, #meta_str1-1) -- remove {}
			meta_str ..= ","
			meta_str ..= meta_str1
		end

		meta_str..="]]"

		return meta_str

	end


	function pod(obj, flags, meta)

		-- safety: fail if there are multiple references to the same table
		-- to do: allow this but write a reference marker in C code? maybe don't need to support that!
		local encountered = {}
		local function check(n)
			local res = false
			if (encountered[n]) return true
			encountered[n] = true
			for k,v in pairs(n) do
				if (type(v) == "table") res = res or check(v)
			end
			return res
		end
		if (type(obj) == "table" and check(obj)) then
			-- table is not a tree
			return nil, "error: multiple references to same table"
		end

		if (meta) then
			local meta_str = _generate_meta_str(meta)
			return _pod(obj, flags, meta_str) -- new meaning of 3rd parameter!
		end

		return _pod(obj, flags)
	end

	


	

	local function _fix_metadata_dates(result)
		if (result) then
			
			-- time string generation bug that happened 2023-10! (to do: fix files in /system)
			if (type(result.modified) == "string" and tonumber(result.modified:sub(6,7)) > 12) then
				result.modified = result.modified:sub(1,5).."10"..result.modified:sub(8)
			end
			if (type(result.created) == "string" and tonumber(result.created:sub(6,7)) > 12) then
				result.created = result.created:sub(1,5).."10"..result.created:sub(8)
			end

			-- use legacy value .stored if .modified was not set
			if (not result.modified) result.modified = result.stored

		end
	end

	local function _fetch_metadata(filename)
		local result = _fetch_metadata_from_file(_fstat(filename) == "folder" and filename.."/.info.pod" or filename)
		_fix_metadata_dates(result)
		return result
	end

	function fetch_metadata(filename)
		filename = _sandbox_path(filename)
		return _fetch_metadata(filename)
	end



	-- fetch and store can be passed locations instead of filenames

	function fetch(location, do_yield, ...)
		if (type(location) != "string") return nil

		local filename, hash_part = table.unpack(_split(location, "#", false))
		local prot = location:prot()

		if (prot == "anywhen") then

			-- anywhen: used for testing rollback (please don't use this for anything important yet!)
			-- fetch("anywhen://foo.txt@2024-04-05_13:02:27"
			-- to do: allow fetch("foo.txt@2024-04-05_13:02:27") -- shorthand for anywhen://..

			if (_sandboxed) return nil
			local ret, meta = _fetch_anywhen(filename:sub(10)) -- include second '/' to give absolute path 
			return ret, meta, hash_part

		elseif (prot == "https" or prot == "https") then
			--[[
				remote fetches are logically the same as local ones -- they block the thread
				but.. can be put into a coroutine and polled
			]]

			-- _printh("[fetch] calling _fetch_remote: "..filename)
			local job_id, err = _fetch_remote(filename, ...)
			-- _printh("[fetch] job id: "..job_id)

			if (err) return nil, err

			local tt = time()

			while time() < tt + 10 do -- to do: configurable timeout.

				-- _printh("[fetch] about to fetch result for job id "..job_id)

				local result, meta, hash_part, err = _fetch_remote_result(job_id)

				-- _printh("[fetch] result: "..type(result))

				if (result or err) then
					--_printh("[fetch remote] returned an obj type: "..type(result).."  // err: "..tostring(err))
					--_printh("[fetch remote] err: "..pod(err))
					return result, meta, hash_part, err
				end

				flip(0x1)
				yield() -- allow pollable pattern from program.  to do: review cpu hogging

			end
			return nil, nil, nil, "timeout"

		elseif prot then
			-- unknown protocol
			return nil, nil, nil, "unknown protocol"			
		else
			-- local file
			filename = _sandbox_path(filename)
			local ret, meta = _fetch_local(filename, do_yield, ...)
			_fix_metadata_dates(meta)
			return ret, meta, hash_part  -- no error
		end
	end

	
	function mkdir(p)
		p = _sandbox_path(p, true)

		if (_fstat(p)) return -- is already a file or directory

		-- create new folder
		local ret = _mkdir(p)

		-- couldn't create
		if (ret) return ret

		-- can store starting metadata to file directly because no existing fields to preserve
		-- // 0.1.0f: replaced "stored" with modified; not useful as a separate concept
		_store_metadata_str_to_file(p.."/.info.pod", _generate_meta_str{created = date(), modified = date()})
	end


	-- to do: errors
	function store(location, obj, meta)

		if (type(location) != "string") return nil

		-- currently no writeable protocols
		if (location:prot()) then
			return "can not write "..location:prot()
		end

		location = _sandbox_path(location, true)

		-- special case: can write raw .p64 / .p64.rom / .p64.png binary data out to host file without mounting it
		local ext = location:ext()

		if (type(obj) == "string" and (ext == "p64" or ext == "p64.rom" or ext == "p64.png")) then
			_rm(location:path()) -- unmount existing cartridge // to do: be more efficient
			return _store_local(location, obj)
		end

		-- ignore location string
		local filename = _split(location, "#", false)[1]
		
		-- grab old metadata
		local old_meta = _fetch_metadata(filename)
		
		if (type(old_meta) == "table") then
			if (type(meta) == "table") then			
				-- merge with existing metadata.   // to do: how to remove an item?			
				for k,v in pairs(meta) do
					old_meta[k] = v
				end
			end
			meta = old_meta
		end

		if (type(meta) != "table") meta = {}
		if (not meta.created) meta.created = date()
		if (not meta.revision or type(meta.revision) ~= "number") meta.revision = -1
		meta.revision += 1   -- starts at 0
		meta.modified = date()

		-- use pod_format=="raw" if is just a string
		-- (_store_local()  will see this and use the host-friendly file format)

		if (type(obj) == "string") then
			meta.pod_format = "raw"
		else
			-- default pod format otherwise
			-- (remove pod_format="raw", otherwise the pod data will be read in as a string!)
			meta.pod_format = nil 
		end


		local result, err_str = _store_local(filename, obj, _generate_meta_str(meta))

		-- notify program manager (handles subscribers to file changes)
		send_message(2, {
			event = "_file_stored",
			filename = _fullpath(filename), -- pm expects raw path
			proc_id = pid()
		})
		
		-- no error
		return nil

	end


	local function _store_metadata(filename, meta)

		local old_meta = _fetch_metadata(filename)
		
		if (type(old_meta) == "table") then
			if (type(meta) == "table") then			
				-- merge with existing metadata.   // to do: how to remove an item? maybe can't! just recreate from scratch if really needed.
				for k,v in pairs(meta) do
					old_meta[k] = v
				end
			end
			meta = old_meta
		end

		if (type(meta) != "table") meta = {}
		meta.modified = date() -- 0.1.0f: was ".stored", but nicer just to have a single, more general "file was modified" value.


		local meta_str = _generate_meta_str(meta)

		if (_fstat(filename) == "folder") then
			-- directory: write the .info.pod
			_store_metadata_str_to_file(filename.."/.info.pod", meta_str)
		else
			-- file: modify the metadata fork
			_store_metadata_str_to_file(filename, meta_str)
		end
	end

	function store_metadata(filename, meta)
		return _store_metadata(_sandbox_path(filename, true), meta)
	end


	_rm = function(f0, flags, depth)

		flags = flags or 0x0
		depth = depth or 0

		local attribs, size, origin = _fstat(f0)

		if (not attribs) then
			-- does not exist
			return
		end

		if (attribs == "folder") then

			-- folder: first delete each entry using this function
			-- dont recurse into origin! (0.1.0h: unless it is cartridge contents)
			-- e.g. rm /desktop/host will just unmount that host folder, not delete its contents
			if (not origin or (origin:sub(1,11) == "/ram/mount/")) then 
				local l = ls(f0)
				for k,fn in pairs(l) do
					_rm(f0.."/"..fn, flags, depth+1)
				end
			end
			-- remove metadata (not listed)
			_rm(f0.."/.info.pod", flags, depth+1)

			-- flag 0x1: remove everything except the folder itself (used by cp when copying folder -> folder)
			-- for two reasons:

			-- leave top level folder empty but stripped of metadata; used by cp to preserve .p64 that are folders on host
			if (flags & 0x1 > 0 and depth == 0) then
				return
			end

		end


		-- delete single file / now-empty folder
		
		-- _printh("_fdelete: "..f0)
		return _fdelete(f0)
	end

	function rm(f0)
		return _rm(_sandbox_path(f0, true), 0, 0)
	end


	--[[	
		internal; f0, f1 are raw paths 

		if dest (f1) exists, is deleted!  (cp util / filenav copy operations can do safety)
	]]
	function _cp(f0, f1, moving, depth)

		depth = depth or 0
		f0 = _fullpath(f0)
		f1 = _fullpath(f1)

		if (not f0)   return "could not resolve source path"
		if (not f1)   return "could not resolve destination path"
		if (f0 == f1) return "can not copy over self"

		local f0_type = _fstat(f0)
		local f1_type = _fstat(f1)

		if (not f0_type) then
			-- print(tostring(f0).." does not exist") 
			return
		end

		-- explicitly delete in case is a folder -- want to make sure contents are removed
		-- to do: should be an internal detail of delete_path()?
		-- 0.1.0e: 0x1 to keep dest as a folder when copying a folder over a folder
		-- (e.g. dest.p64/ is a folder on host; preferable to keep it that way for some workflows)
		if (f1_type == "folder" and depth == 0) _rm(f1, f0_type == "folder" and 0x1 or 0x0) 

		-- folder: recurse
		if (f0_type == "folder") then

			-- 0.1.0c: can not copy inside itself   "cp /ram/cart /ram/cart/foo" or "cp /ram/cart/foo /ram/cart" 
			-- 0.1.1:  but cp foo foo2/ is ok (or cp foo2 foo/)
			local minlen = min(#f0, #f1)
			if (sub(f1, 1, minlen) == sub(f0, 1, minlen) and (f0[minlen+1] == "/" or f1[minlen+1] == "/")) then
				return "can not copy inside self" -- 2 different meanings!
			end

			-- get a cleared out root folder with empty metadata
			-- (this allows host folders to stay as folders even when named with .p64 extension -- some people use that workflow)
			_mkdir(f1)

			-- copy each item (could also be a folder)

			local l = _ls(f0)
			for k,fn in pairs(l) do
				local res = _cp(f0.."/"..fn, f1.."/"..fn, moving, depth+1)
				if (res) return res
			end

			-- copy metadata over if it exists (ls does not return dotfiles)
			-- 0.1.0f: also set initial modified / created values 

			local meta = _fetch_metadata(f0) or {}

			-- also set date [and created when not being used by mv())
			meta.modified = date()
			if (not moving) meta.created = meta.created or meta.modified -- don't want to clobber .created when moving

			-- store it back at target location. can just store file directly because no existing fields to preserve
			_store_metadata_str_to_file(f1.."/.info.pod", _generate_meta_str(meta))

			return
		end

		-- binary copy single file
		_fcopy(f0, f1)

	end

	--[[
		mv(src, dest)

		to do: rename / relocate using host operations if possible

		to do: currently moving a mount copies it into a regular file and removes the mount;
			-> should be possible to rename/move mounts around?
	]]
	function mv(src, dest)
		src  = _sandbox_path(src, true) 
		dest = _sandbox_path(dest, true)

		-- skip mv if src and dest are the same (or both nil)
		if (_fullpath(src) == _fullpath(dest)) return

		local res = _cp(src, dest, true)
		if (res) return res -- copy failed

		-- copy completed -- safe to delete src
		_rm(src)
	end

	function cp(src, dest)
		src  = _sandbox_path(src)
		dest = _sandbox_path(dest, true)
		return _cp(src, dest) -- don't expose the moving or depth parameters; they are internal details
	end

	-- 

	--[[
		ls
		note: ls("not_in_sandbox") returns {}, even if there subdirectories accessible to the sandbox
		--> ls("/") doesnt not list ("/appdata")
	]]
	function ls(p)
		p = p or pwd()
		p = _sandbox_path(p)
		if (not p) return {} -- not allowed to list if couldn't sandbox
		return _ls(p)
	end

	function cd(p)
		p = _sandbox_path(p)
		if (not p) return nil
		return _cd(p)
	end

	function pwd()
		if (_sandboxed) return _un_sandbox_path(_pwd())
		return _pwd()
	end

	function fullpath(p)
		if (_sandboxed) return _un_sandbox_path(_fullpath(_sandbox_path(p))) -- \m/
		return _fullpath(p)
	end

	function mount(a, b)
		if (_sandboxed) return nil -- can't mount anything when sandboxed (or read mount descriptions) 
		return _mount(a, b)
	end

	function fstat(p)
		if (_sandboxed) then
			p = _sandbox_path(p)
			local kind, size = _fstat(p)
			return kind, size -- no mount description -- might expose information outside of sandbox
		end
		return _fstat(p) -- includes mount description
	end

end
