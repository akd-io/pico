--[[

	fs.lua

	filesystem / pod

]]


do


	local _env = env
	local _sandbox = _env().sandbox
	local _signal = _signal
	local _send_message = _send_message

	local _fetch_local = _fetch_local
	local _fetch_remote = _fetch_remote
	local _fetch_anywhen = _fetch_anywhen
	local _fetch_remote_result = _fetch_remote_result
	local _store_local = _store_local
	local _cache_store = _cache_store
	local _cache_fetch = _cache_fetch

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
	local _normalise_userland_path = _normalise_userland_path
	local _is_well_formed_bbs_path = _is_well_formed_bbs_path
	local _get_process_list = _get_process_list
	local _pid = pid

	local _fcopy = _fcopy
	local _fdelete = _fdelete
	local _fullpath = _fullpath
	local _mkdir = _mkdir

	local _split = split
	local _printh = _printh


	-- fileview can be extended via request_file_access messages
	local fileview = unpod(pod(_env().fileview))


	--[[--------------------------------------------------------------------------------------------------------------------------------

		extra protocols:  bbs // later: anywhen, podnet

		moving protocol handling into userspace means that some functionality normally handled by _fullpath needs 
		to be duplicated: path collapsing (_normalise_userland_path), auto mounting, pwd prefixing

	----------------------------------------------------------------------------------------------------------------------------------]]
	
	-- per-process record of prot://file cached as ram files
	-- later: lower-level mounting? need for writeable protocols (podnet)

	local prot_to_ram_path={}
	local ram_to_prot_path={}

	local prot_driver = {}
	
	-- test protocol
--[==[
	prot_driver["echo"] = {
		store_path_in_ram = function(path)
			mkdir("/ram/echo")					
			local fn=("/ram/echo/"..#prot_to_ram_path)
			if (path:ext()) fn ..= "."..path:ext()
			_store_local(fn, "["..path.."]", "--[[pod]]") -- no metadata; for bbs:// carts could inject bbs_id, bbs_author? too much magic
			return fn
		end,
		get_listing = function(path)
			return{"[listing: "..path.."]"}
		end,
		get_attr = function(path)
			return "file", #path
		end
	}
]==]
	
	local function get_bbs_host()
		-- bbs web player: works with empty host string as url is relative to lexaloffle.com
--		if ((stat(317) & 0x3) == 0x1) return "http://localhost" -- dev test
		if ((stat(317) & 0x3) == 0x1) return "https://www.lexaloffle.com"
		-- any other exports: bbs:// is not supported (to do: explicit error codepath -- just disable bbs:// ? )		
		if (stat(317) > 0) return "" 
		-- binaries: main server
		return "https://www.lexaloffle.com"
	end

	local function get_versioned_cart_url(bbs_id)
		-- bbs web player: just use get_cart for now -- later: use cdn
		if ((stat(317) & 0x3) == 0x1) return get_bbs_host().."/bbs/get_cart.php?cat=8&lid="..bbs_id
		-- exports: bbs:// otherwise not supported 
		if (stat(317) > 0) return ""
		-- binaries: use cdn
		return "https://carts.lexaloffle.com/"..bbs_id..".p64.png"
	end


	-- per session cache for listings 
	-- to do: review: cache to disk? maybe should be up to the calling app? (ref: splore list)
	local bbs_listing_cache = {}

	prot_driver["bbs"] = {

		store_path_in_ram = function(path)

			-- can assume /ram/bbs exists; see create_process()

			--printh("bbs store_path_in_ram: "..tostring(path))

			-- bbs://cart/foo.p64  (or bbs://foo.p64!)
			if (path:ext() == "p64") then
				local bbs_id = path:basename():sub(1,-5)
				local fn = "/ram/bbs/"..path:basename()..".png"

				-- already downloaded to ram by another process
				if (fstat(fn)) return fn

				local is_versioned = bbs_id:sub(-2,-2) == "-" or bbs_id:sub(-3,-3) == "-"

				-- check cache for versioned cartridge
				-- never changes on server, so can use this if it exists
				if (is_versioned) then
					local cached_cart_png = _cache_fetch("carts", bbs_id..".p64.png")
					if (cached_cart_png and #cached_cart_png > 0) then
						--printh("copying cached cart to ram: "..fn)
						_store_local(fn, cached_cart_png, "format=\"raw\"")
						return fn
					end
				end

				-- download
	
				-- printh("[bbs://] fetching cart from carts.lexaloffle.com/"..bbs_id..".p64.png -> "..fn)

				local cart_png, meta, err = fetch(get_versioned_cart_url(bbs_id))

				if (type(cart_png) ~= "string" or #cart_png == 0) then
					-- fall back to origin; might not be on cdn yet?, or cdn is down? or cloudflare rate-limiting requests?
					printh("get_cart fallback: "..bbs_id)
					cart_png, meta, err = fetch(get_bbs_host().."/bbs/get_cart.php?cat=8&lid="..bbs_id)
				end

				--if(err)printh("bbs prot error on fetch: "..err)
				if (type(cart_png) == "string" and #cart_png > 0) then
					-- printh("[bbs://] fetched and cache: "..#cart_png.." bytes")
					-- store(fn, cart_png, meta) -- wrong! can't access when sandboxed
					_store_local(fn, cart_png, "format=\"raw\"")
					_cache_store("carts", bbs_id..".p64.png", cart_png)
					return fn
				end

				-- for ids with no version, check in cache *after* trying download
				-- (always want the latest version if it exists)
				-- to do: could also scan for highest versioned copy in cache
				if (not is_versioned) then
					-- printh("[bbs://] attempting to use non-versioned cart from cache")
					local cached_cart_png = _cache_fetch("carts", bbs_id..".p64.png")
					if (cached_cart_png and #cached_cart_png > 0) then
						store(fn, cached_cart_png, {format="raw"})
						return fn
					end
				end

				return nil, "cart download failed"
				
			end

			-- test
			if (path == "bbs://news.txt") then
				local text_file, meta, err = fetch(get_bbs_host().."/dl/docs/picotron_bbs_news.txt")
				-- printh("@@ downloading: "..get_bbs_host().."/dl/docs/picotron_bbs_news.txt")

				if (type(text_file) == "string" and #text_file > 0) then
					mkdir("/ram/bbs")
					store("/ram/bbs/news.txt", text_file)
					return "/ram/bbs/news.txt"
				else
					return nil, "cart download failed"
				end
			end

			return nil -- couldn't resolve
		end,
	
		get_listing = function(path)

			--printh("bbs:// listing: "..tostring(path))
			
			-- ** not meant as a public endpoint, please use bbs:// instead! **
			local endpoint = get_bbs_host().."/bbs/pod.php?"
			local req

			local p_page = nil
			local q_str = nil

			-- show page 0 instead of pages

			if (sub(path,1,10) == "bbs://new/")       p_page=sub(path,11)  q_str="sub=2"
			if (sub(path,1,10) == "bbs://wip/")       p_page=sub(path,11)  q_str="sub=3"
			if (sub(path,1,15) == "bbs://featured/")  p_page=sub(path,16)  q_str="sub=2&orderby=featured"

			p_page=tonumber(p_page)
			if (type(p_page) == "number" and q_str) req = endpoint.."cat=8&max=32&start_index="..(p_page*32).."&"..q_str


			if (req) then

				-- printh("req:"..pod{path, req})

				local res = nil
				if (bbs_listing_cache[req] and time() < bbs_listing_cache[req].response_t + 10) then
					-- use session cache
					res = bbs_listing_cache[req].response
				else
					--printh("req:"..pod{path, req})
					res = fetch(req)
					if (res) then
						-- store session cache
						bbs_listing_cache[req] = {
							response = res,
							response_t = time()
						}

						-- also start downloading everything!
						for i=1, #res do
							-- start download if doesn't already exist in cache
							if (not _cache_fetch("carts", res[i].id..".p64.png")) then
								--printh("starting background download: "..res[i].id..".p64.png")
								local job_id, err = _fetch_remote(get_versioned_cart_url(res[i].id))
							end
						end


					elseif bbs_listing_cache[req] then
						-- fallback to session cache (e.g. went offline after getting listing a long time ago)
						res = bbs_listing_cache[req].response
					end
				end

				if (res) then
					local list = {}
					for i=1,#res do
						add(list, res[i].id..".p64")
					end
					return list
				end
			end

			if (path == "bbs://") then 
				return{
--[[
					-- visual test: with icons. maybe should be allowed to view by .label / .title when it exists
					-- or specify an icon to replace folder icon when available -- looks nice in list mode
					"\^:0000637736080800 new",
					"\^:00081c7f3e362200 featured",
					"\^:001c14363e777f00 wip",
]]
					"new",
					"featured",
					"wip",
--[[
					-- to do: browse these from settings
					-- use tags; one cart could be a screensaver or a live desktop (and possibly adapt itself!)
					"screensavers",
					"desktops",
					"widgets",
					"themes", -- a cart that demos theme? bundle multiple themes? separate podnet files?
]]
					"news.txt", -- test; probably want news.pod or news.p64 if do something like this
				}
			end

			-- page navigation
			if (path == "bbs://new" or path == "bbs://featured" or path == "bbs://wip") then
				local ret = {}
				for i=0,31 do
					add(ret, tostring(i))
				end
				return ret
			end
		
			return {}
		end,
		get_attr = function(path)
			-- to do: check for existence of top-level folder / file
			if not _is_well_formed_bbs_path(path) then 
				-- e.g. lua command from terminal tried as util command first
				return nil 
			end
--[[
			-- experimental: probe for file existence?
			local l = ls(prot_driver["bbs"].get_listing(path:dirname()))
			local found = false
			for i=1,#l do
				if (fullpath(l[i]) == fullpath(path)) found = true
			end
--			if (not found) return nil
]]
			local ext = path:ext()
			if (ext == "p64") return "folder", 0 -- cart subfolder is ignored
			if (not ext)      return "folder", 0 -- bbs://new
			if (ext == "txt") return "file", 0   -- news.txt
			return nil -- file doesn't exist
		end
	}

	----------------------------------------------------------------------------------------------------------------------------------
	-- path remapping
	--
	-- rule: local functions (_mkdir) take raw paths ("/appdata/bbs/bbs_id/foo") 
	--       global functions (mkdir) take userland paths ("/appdata/foo")
	----------------------------------------------------------------------------------------------------------------------------------

	local function path_is_inside(path, container_path)
		local len = #container_path -- the shorter string
		if (container_path == "*") return true
		return path:sub(1,len) == container_path and (#path == len or path[len + 1] == "/")
	end

	
	--[[
		_kernal_to_userland_path  (was "_un_sandbox_path")
		
		convert from proc->pwd to pwd():

			/appdata/bbs/bbs_id/foo         -->   /appdata/foo     (when sandboxed)
			podnet://1/appdata/bbs_id/foo   -->   podnet://1/foo   (when sandboxed ~ to do)
			bbs://new                        -->   bbs://new        (because not mounted by bbs:// driver)
			/ram/bbs/blah.p64.png            -->   bbs://blah.p64   (because mounted by bbs:// driver)

		** uses protocol driver to mount carts on demand
	]]

	local function _kernal_to_userland_path(path)
		if (type(path) ~= "string") return nil

		-- /ram/bbs/foo-0.p64.png/gfx/foo.gfx   -->   bbs://new/3/foo-0.p64/gfx/foo.gfx

		if (path:sub(1,9) == "/ram/bbs/") then -- optimisation; most of the time this is not true
			local sub_path = ""
			local ram_cart_path = path
			local ram_cart_path_pos = string.find(path,".p64.png")
			if (ram_cart_path_pos) then
				ram_cart_path = path:sub(1, ram_cart_path_pos+7)  --  /ram/bbs/foo.p64.png
				sub_path = path:sub(ram_cart_path_pos+8)      --  /main.lua
				--printh("sub_path: "..tostring(sub_path))
				--printh("_kernal_to_userland_path // path, ram_cart_path_pos, ram_cart_path, sub_path: "..pod{path, ram_cart_path_pos, ram_cart_path, sub_path})
				if (ram_to_prot_path[ram_cart_path]) then
					return ram_to_prot_path[ram_cart_path]..sub_path
				end
			end
		end

		-- no local mapping for a protocol path -> return as-is
		if (path:prot()) return path

		-- is local filesystem path
		if (not _sandbox) return path
		
		--[[
			-- /appdata mapping only when bbs_id is set
			-- commented; handled by backwards rewrite rules below
			if (path:sub(1,9) == "/appdata/bbs/" and _env().bbs_id)
			then  
				local bbs_id_base = split(_env().bbs_id, "-", false)[1] -- don't include the version
				local cart_dir = "/appdata/bbs/"..bbs_id_base..path:sub(9)
				local cart_dir_len0 = #cart_dir
				local cart_dir_len1 = #cart_dir + 1
				if path:sub(1, cart_dir_len0) == cart_dir and (#path == cart_dir_len0 or path[cart_dir_len1] == "/") then
					return "/appdata"..path:sub(cart_dir_len1)
				end
			end
		]]

		-- un-rewrite :: /appdata/bbs/bbs_id/foo/a.txt -> /appdata/foo/a.txt
		-- target is:    /appdata/bbs/bbs_id
		-- location is:  /appdata

		if (fileview) then
			for i=1,#fileview do
				if fileview[i].target and path_is_inside(path, fileview[i].target) then
					-- printh("reversed rule: "..path.."  -->  "..fileview[i].location..path:sub(#fileview[i].target + 1))
					return fileview[i].location..path:sub(#fileview[i].target + 1)
				end
			end
		end

		-- no rule applies; return as-is
		return path
	end


	--[[
		_userland_to_kernal_path
		
		convert from pwd() to proc->pwd:

			/appdata/foo     -->   /appdata/bbs/bbs_id/foo         (when sandboxed)
			podnet://1/foo   -->   podnet://1/appdata/bbs_id/foo   (when sandboxed ~ to do)
			bbs://new        -->   bbs://new                        (because not mounted by bbs:// driver)
			bbs://blah.p64   -->   /ram/bbs/blah.p64                (because mounted by bbs:// driver)

		** uses protocol driver to mount carts to /ram/mountp/[prot_name]/ on demand

	]]

	local function _userland_to_kernal_path(path_p, mode_p)

		if (type(path_p) ~= "string") return nil
		if (path_p == "") return nil -- don't accept fetch("") etc -- is dangerous

		mode_p = mode_p or "R"

		local path

		if (path_p:prot() or path_p[1] == "/") then
			-- absolute path: use as-is (but normalised)
			path = _normalise_userland_path(path_p)
		else
			-- relative path: prepend (userland) pwd() first and normalise first 
			-- e.g. bbs://new/foo.p64/gfx/.. -> /ram/bbs://new/foo.p64/gfx
			local userland_pwd = _kernal_to_userland_path(_pwd())
			if (userland_pwd[#userland_pwd] == "/") then
				path = userland_pwd..path_p -- at start e.g. "bbs://", don't want extra /
			else
				path = userland_pwd.."/"..path_p
			end
			if (path) path = _normalise_userland_path(path)
			--printh(pod{path_p, path})
		end


		--> path is now normalised and absolute, but not resolved

	
		-- resolved path has protocol when explicitly starts with protocol or is relative to _pwd() that has a protocol
		local prot = path:prot() or (path[1] ~= "/" and _pwd():prot())

--[[
		if (_pwd() ~= "/system/wm") then-- noisey!
			printh("_userland_to_kernal_path path,_pwd():"..pod{path,_pwd()}.." -->  prot:"..tostring(prot))
		end
]]

		if prot then

			if (not prot_driver[prot]) return nil -- undefined protocol

			-- relative protocol path: add to pwd

			local path1 = path -- to do: just stick with path

			-- find cart mount (might need to download & mount)
			local sub_path = ""
			local cart_path = path1
			local cart_path_pos = string.find(path1,".p64")
			if (cart_path_pos) then
				cart_path = path1:sub(1, cart_path_pos+3)  --  bbs://foo.p64
				sub_path = path1:sub(cart_path_pos+4)      --  /main.lua
				--printh("path1, cart_path_pos, cart_path, sub_path: "..pod{path1, cart_path_pos, cart_path, sub_path})
			end

			if not prot_to_ram_path[cart_path] and prot_driver[prot] then
				local fn = prot_driver[prot].store_path_in_ram(cart_path)
				if (fn) then
					--printh("@@ setting  prot_to_ram_path["..cart_path.."] = "..fn)
					prot_to_ram_path[cart_path] = fn
					ram_to_prot_path[fn] = cart_path
				else
					-- many legitimate paths can't be stored; e.g. bbs://new isn't stored in this way
					-- printh("[_userland_to_kernal_path]: ** could not store_path_in_ram: "..cart_path)
				end
			end

			if prot_to_ram_path[cart_path] then
				-- printh("returning bbs path: "..(prot_to_ram_path[cart_path].." + "..sub_path).."   // _env().prog_name:".._env().prog_name)
				-- printh("_userland_to_kernal_path prot: ["..tostring(prot).."] "..path.." -> "..prot_to_ram_path[cart_path]..sub_path)
				return prot_to_ram_path[cart_path]..sub_path -- resolve to local / ram
			else
				-- printh("_userland_to_kernal_path prot: ["..tostring(prot).."] "..path.." -> "..path1)
				return path1 -- could not resolve; return as-is (and let the protocol driver deal with it)
			end
		end

		-------------------------------------------------------------------------------------------------------------

		-- no protocol

		path = _fullpath(path) -- raw fullpath; handles relative paths + pwd
		if (type(path) ~= "string") return nil -- couldn't resolve, or nil to start with

		-------------------------------------------------------------------------------------------------------------
		-- apply access rules

		-- no protocol: return path as-is when not sandboxed
		-- (implicit rule: * RW)
		if (not _sandbox) return path


		-- otherwise can only access certain locations
		-- to do: could pregenerate lists according to matching mode, but perf shouldn't be an issue here

		if (fileview) then -- safety; should always exist
			for i=1,#fileview do
				local rule = fileview[i]
				if (rule.mode == "RW" or (not mode_p ~= "W" and rule.mode == "R") or (mode_p == "X" and rule.mode == "X")) then
					if path_is_inside(path, rule.location) then
						if (rule.target) then
							-- allow but rewrite
							--printh("allowing: "..path.."   -->   "..rule.target..path:sub(#rule.location+1))

							-- create target on demand; most bbs carts don't every write anything, and don't want folderjunk 
							--printh("creating bbs appdata folder; path: "..path)
							_mkdir(rule.target)

							return rule.target..path:sub(#rule.location+1) -- "/appdata/bbs/bbs_id".."/foo.txt"
						else
							--printh("allowing: "..path)
							return path -- allow
						end
					end
				end
			end
		end

--[[		
		-- deleteme  --  the following has been replaced by fileview rules above

		if (mode_p ~= "W") then

			-- read: /system, shared ram, and mounted bbs carts

			if (path_is_inside(path, "/system")) return path
			if (path_is_inside(path, "/appdata/system")) return path
			if (path_is_inside(path, _env().prog_name:dirname())) return path
			if (path_is_inside(path, "/ram/shared")) return path

			-- can read desktop (!) // later: can disable this
			if (path_is_inside(path, "/desktop")) return path     -- ref: desktop_pet

			-- bbs cart can read processes by default (!)
			if (path == "/ram/system/processes.pod") return path  -- ref: okpal, task_monitor

		end

		-- allow R/W access to /ram/cart by default!
		-- a little more dangerous, but very common for tools to deal only with cart contents
		--> should perhaps have a way to easily unload /ram/cart apart from rebooting? reboot is pretty clear and fast though
		if (path_is_inside(path, "/ram/cart")) return path    -- ref: okpal, vedit

		-- read/write mounted bbs:// cart while sandboxed
		if (_env().bbs_id and path_is_inside(path, "/ram/bbs/".._env().bbs_id..".p64.png")) return path

		-- read/write /appdata/shared and /appdata (remapped)
		if (path_is_inside(path, "/appdata/shared")) return path

		-- /appdata (but not /appdata/shared, which doesn't get mapped)
		if (path_is_inside(path, "/appdata") and _env().bbs_id) then
			local bbs_id_base = split(_env().bbs_id, "-", false)[1] -- don't include the version
			--printh("bbs_id_base: "..bbs_id_base);
			_mkdir("/appdata/bbs/"..bbs_id_base) -- make sure it exists
			return "/appdata/bbs/"..bbs_id_base..path:sub(9) -- includes '/' separating bbs_id and path
		end
]]


		-- anything else not allowed
		-- to do: where are /ram/bbs/foo.p64.png files being accessed from? (harmless but weird)
		-- printh("no access from sandbox: "..path)

		return nil
	end


	-- sandboxed versions of some files
	local function _fetch_partial(path)

		if (path == "/ram/system/processes.pod") then

			local p = _get_process_list()
			local out = {}
			for i=1,#p do
				-- sandboxed cart can see: system processes, instances of self, direct children
				if (p[i].id <= 3 or 
					p[i].prog:sub(1,8) == "/system/" or
					p[i].prog == env().argv[0] or p[i].parent_id == _pid()) then
					add(out, p[i])
				else
					add(out, {
						id = 0,
						name = "[hidden]",
						prog = "[hidden]",
						cpu = 0,
						memory = 0,
						priority = 0,
						pwd = ""
					})
				end
			end
			
			return out
		end

		return nil
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

	function fetch_metadata(filename_p)
		if (type(filename_p) ~= "string") return nil
		local filename = _userland_to_kernal_path(filename_p)

		if (not filename) then
			-- try directly from .info.pod (perhaps /desktop is not allowed in sandbox, but /desktop/.info.pod is)
			filename = _userland_to_kernal_path(filename_p.."/.info.pod", "X")
			if (filename) then
				local res  = _fetch_metadata_from_file(filename)
				if (not _sandbox) return res -- not sandboxed; return 
				-- otherwise: censor! only return positions, no file names (used by e.g. bbs://desktop_pet.p64)
				local res2 = {file_item={}}
				if (res.file_item) then
					local index = 0
					for k,v in pairs(res.file_item) do
						res2.file_item["file_"..index] = { x = v.x, y = v.y }
						index += 1
					end
				end
				return res2
			end
			return nil
		end

		--printh("fetch_metadata kernal_path: "..filename)
		return _fetch_metadata(filename)
	end



	-- fetch and store can be passed locations instead of filenames

	function fetch(location, do_yield, ...)
		if (type(location) != "string") return nil, nil, nil, "location is not a string"

		local filename, hash_part = table.unpack(_split(location, "#", false))
		local prot = location:prot()

		if (prot == "anywhen") then

			-- anywhen: used for testing rollback (please don't use this for anything important yet!)
			-- fetch("anywhen://foo.txt@2024-04-05_13:02:27"
			-- to do: allow fetch("foo.txt@2024-04-05_13:02:27") -- shorthand for anywhen://..

			if (_sandbox) return nil, nil, "can not access anywhen while sandboxed"
			local ret, meta = _fetch_anywhen(filename:sub(10)) -- include second '/' to give absolute path 
			return ret, meta

		elseif (prot == "https" or prot == "http") then
			--[[
				remote fetches are logically the same as local ones -- they block the thread
				but.. can be put into a coroutine and polled
			]]

			-- _printh("[fetch] calling _fetch_remote: "..filename)
			local job_id, err = _fetch_remote(filename, ...)
			-- _printh("[fetch] job id: "..job_id)

			if (err) return nil, nil, err

			local tt = time()

			while time() < tt + 10 do -- to do: configurable timeout.

				-- _printh("[fetch] about to fetch result for job id "..job_id)

				local result, meta, err = _fetch_remote_result(job_id)

				-- _printh("[fetch] result: "..type(result))

				if (result or err) then
					-- _printh("[fetch remote] err: "..pod(err))
					return result, meta, err
				end

				flip(0x1)
--				yield() -- allow pollable pattern from program.  to do: review cpu hogging

			end
			return nil, nil, "timeout"
		else
			-- local file (update: or generic protocol)
			kpath = _userland_to_kernal_path(filename)

			if (not kpath) then
				-- try again with partial view of file (processes.pod)
				kpath = _userland_to_kernal_path(filename, "X")
				if (kpath) return _fetch_partial(kpath)
			end

			if (not kpath) return nil, nil, "could not access path"
			local ret, meta = _fetch_local(kpath, do_yield, ...)
			_fix_metadata_dates(meta)
			return ret, meta -- no error
		end
	end

	
	--[[
		mkdir()
		returns string on error
	]]
	function mkdir(p)
		p = _userland_to_kernal_path(p, "W")
		if (not p) return "could not access path"

		if (p:prot()) return -- protocols don't support mkdir / writes yet

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
			return "can not write "..location
		end

		location = _userland_to_kernal_path(location, "W")
		if (not location) return "could not store to path"

		-- special case: can write raw .p64 / .p64.rom / .p64.png binary data out to host file without mounting it
		local ext = location:ext()

		if (type(obj) == "string" and ext and ext:is_cart()) then
			_signal(40)
				_rm(location:path()) -- unmount existing cartridge // to do: be more efficient
			_signal(41)
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


		-- 0.1.1e: store "prog" when is bbs:// -- the program that was used to create the file can be used to open it again
		if (_env().argv[0]:prot() == "bbs") then
			meta.prog = _env().argv[0]
		end

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
		_send_message(2, {
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
		return _store_metadata(_userland_to_kernal_path(filename, "W"), meta)
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
		local f1 = _userland_to_kernal_path(f0, "W")
		if (f1:prot()) return -- rm not supported by protocols yet	
		_signal(40)
			local ret = _rm(f1, 0, 0) -- atomic operation
		_signal(41)
		return ret
	end


	--[[	
		internal; f0, f1 are raw paths 

		if dest (f1) exists, is deleted!  (cp util / filenav copy operations can do safety)
	]]
	function _cp(f0, f1, moving, depth, bbs_id)

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
			return "could not access source location"
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
			-- 0.1.1e: special case for /  --  is technically also "can not copy inside self", but might as well be more specific
			if (f0 == "/" or f1 == "/") then
				return "can not copy /"
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

			-- when copying / moving from bbs:// -> local, carry over bbs_id and sandbox. copy over existing values! (in particular, dev bbs_id)
			if (bbs_id) then
				-- printh("@@ carrying over bbs_id as metadata"..bbs_id)
				meta.bbs_id = bbs_id
				meta.sandbox = "bbs"
			end

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
	function mv(src_p, dest_p)
		local src  = _userland_to_kernal_path(src_p, "W") 
		local dest = _userland_to_kernal_path(dest_p, "W")
		if (not src or not dest) return
		if (dest:prot()) return -- protocols don't support writing yet 

		-- skip mv if src and dest are the same
		if (_fullpath(src) == _fullpath(dest)) return

		-- special case: when copying from bbs://, retain .bbs_id .sandbox as metadata
		local bbs_id = (src_p:prot() == "bbs" and src_p:ext() == "p64") and src_p:basename():sub(1,-5) or nil

		_signal(40) -- 0.1.1e compound op lock (prevent flushing cart halfway through moving)
			local res = _cp(src, dest, true, nil, bbs_id) -- atomic operation
		_signal(41)
		if (res) return res -- copy failed

		-- copy completed -- safe to delete src
		_signal(40)
			_rm(src)
		_signal(41)
	end

	function cp(src_p, dest_p)
		local src  = _userland_to_kernal_path(src_p)
		local dest = _userland_to_kernal_path(dest_p, "W")
		if (not src or not dest) return 
		if (dest:prot()) return -- protocols don't support writing yet 

		-- special case: when copying from bbs://, retain .bbs_id .sandbox as metadata
		local bbs_id = (src_p:prot() == "bbs" and src_p:ext() == "p64") and src_p:basename():sub(1,-5) or nil

		_signal(40) -- 0.1.1e: lock flushing for compound operation; don't want to e.g. store a cart on host that is halfway through being copied
			local ret0, ret1 = _cp(src, dest, nil, nil, bbs_id) -- atomic operation
		_signal(41) -- unlock 
		return ret0, ret1
	end

	-- 

	--[[
		ls
		note: ls("not_in_sandbox") returns nil, even if there subdirectories accessible to the sandbox
		--> ls("/") does not list ("/appdata")
	]]
	function ls(p)
		p = p or _pwd()

		kernal_path = _userland_to_kernal_path(p)
		if (not kernal_path) return nil -- not allowed to list if couldn't sandbox / resolve

		-- protocol listing
		local prot = kernal_path:prot()
		if (prot) return prot_driver[prot].get_listing(kernal_path) or {}

		-- local listing
		return _ls(kernal_path)
	end

	function cd(p)
		if (type(p) ~= "string") return nil
		kernal_path = _userland_to_kernal_path(p)

		if (not kernal_path) return nil -- means local path doesn't exist

		-- protocol path
		local prot = kernal_path:prot()
		if (prot) return _cd(kernal_path, true) -- to do: use protocol get_attr first to check it is a folder

		-- local
		return _cd(kernal_path)
	end

	function pwd()
		return _kernal_to_userland_path(_pwd())
	end

	function fullpath(p)

		local kernal_path = _userland_to_kernal_path(p)

		if (not kernal_path) return nil

		-- resolve to protocol location -> no further indirection
		if (kernal_path:prot()) return kernal_path

		-- otherwise now have a path on local filesystem or /ram; can convert back after applying _fullpath
		return _kernal_to_userland_path(_fullpath(kernal_path))
	end



	function mount(a, b)
		if (_sandbox) return nil -- can't mount anything when sandboxed (or read mount descriptions) 
		if (a:prot() or b:prot()) return nil -- can't mount protocols [yet]
		return _mount(a, b)
	end

	function fstat(p)

		local kernal_path = _userland_to_kernal_path(p)

		if (not kernal_path) return nil
		
		-- protocol path attributes
		local prot = kernal_path:prot()
		if (prot) then -- mean protocol exists because otherwise _userland_to_kernal_path returns nil
			-- printh("reading protocol path attributes: "..kernal_path)
			local kind, size = prot_driver[prot].get_attr(kernal_path)
			return kind, size
		end
		
		-- otherwise now have a path on local filesystem (including /ram), can use _fstat
		
		if (_sandbox) then	
			local kind, size = _fstat(kernal_path)
			return kind, size -- don't expose mount description when sandboxed
		end

		return _fstat(kernal_path) -- includes mount description
	end

	-- system apps (filenav) can request access to particular files
	on_event("extend_fileview", function(msg)
		-- printh("requesting file access via extend_fileview: "..pod(msg))
		if (msg._flags and (msg._flags & 0x1) > 0) then  --  requesting process is a trusted system app (filenav)
			add(fileview, {
				location = msg.filename,
				mode = "RW"
			})
		end
	end)

	-- grant access to dropped files

	on_event("drop_items", function(msg)
		if (msg._flags and (msg._flags & 0x1) > 0) then  --  requesting process is a trusted system app (window manager)
			for i=1,#msg.items do
				-- printh("granting file access via dropped item: "..msg.items[i].fullpath)
				add(fileview, {
					location = msg.items[i].fullpath,
					mode = "RW"
				}, 1) -- insert at start so that mapping don't interfere. e.g. drop from /appdata/anotherapp
			end
		end
	end)




end
