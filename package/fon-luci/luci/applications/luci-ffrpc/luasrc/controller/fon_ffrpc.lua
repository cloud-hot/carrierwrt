local req, assert, ipairs, pairs, pcall = require, assert, ipairs, pairs, pcall
local tonumber, tostring = tonumber, tostring

--- Fonera Downloader JSON-RPC API
-- @name /luci/fon_rpc/ff
module "luci.controller.fon_ffrpc"

function index()
	local util = require "luci.util"
	local http = require "luci.http"
	local sauth = require "luci.sauth"

	-- Alternative authenticator using HTTP-GET variable
	local function authenticator(validator, accs)
		local auth = http.formvalue("auth", true)
		if auth then
			local user = sauth.read(auth)
			if user and util.contains(accs, user) then
				return user, auth
			end
		end
		http.status(403, "Forbidden")
	end

	-- Register JSON-RPC API
	local page = entry({"fon_rpc", "ff"}, call("rpc"))
	page.sysauth = "root"
	page.sysauth_authenticator = authenticator

	-- Register Fileupload/download API
	entry({"fon_rpc", "ff", "auth"}, call("rpc_auth")).sysauth = false
end

local require = req

function rpc_auth()
	local os      = require "os"
	local jsonrpc = require "luci.jsonrpc_fon"
	local sauth   = require "luci.sauth"
	local http    = require "luci.http"
	local sys     = require "luci.sys"
	local ltn12   = require "luci.ltn12"
	local uci = require "luci.model.uci".cursor()

	local loginstat

	local server = {}
	server.plain = function(user, pass)
		--assert(uci:get("fonbackup", "fonbackup", "enabled") == "1", "disabled.")
		local sid

		if user == "fonero" or user == "admin" then user = "root" end
		if sys.user.checkpasswd(user, pass) then
			sid = sys.uniqueid(16)
			sauth.write(sid, user)
		end

		return sid
	end

	http.prepare_content("application/json")
	ltn12.pump.all(jsonrpc.handle(server, http.source()), http.write)
end

function rpc()
	local fs = require "luci.fs"
	local cbi = require "luci.cbi"
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()
	local state = require "luci.model.uci".cursor_state()
	local http = require "luci.http"
	local ltn12 = require "luci.ltn12"
	local jsonrpc = require "luci.jsonrpc_fon"
--	local torrentd = require "torrent"
	local nixio = require "nixio"
	local event = require "luci.fon.event"

	-- Object table to be published via RPC
	local export = {}
	
	local function tr_id(id)
		local key = id:sub(1, 3)
		local name = id:sub(4)
		if key == "tr_" then
			return "torrent", name:match("(.*/)(.*)")
		else
			return "download", name
		end
	end

--- List all active downloads.
-- @return Table containing one or more tables containing: <ul>
-- <li>uri = Download URI</li>
-- <li>id = Unique ID</li>
-- <li>size = Target File Size </li>
-- <li>percent = Download Progress</li>
-- <li>file = Filename</li>
-- <li>status = ["pending", "suspended", "load", "done", "hashing", "error"]</li>
-- </ul>
	function export.dl_list()
		local ret = {}
		state:foreach("luci_dlmanager", "download", function(s)
			local perc = (tonumber(s.size)
				and (tonumber(s.stepsize) or 0) / (tonumber(s.size) or 0)
				or 0) * 100
				  
			ret[#ret+1] = {
				type = "download",
				id = "dl_" .. s[".name"],
				uri = s.uri,
				size = s.size,
				percent = ("%.2f%%"):format(perc),
				file = s.file and fs.basename(s.file),
				status = s.pid and s.status == "pending" and "load" or s.status
			}
		end)
		
		local tr_stat = {
			["0"] = "pending",
			["1"] = "suspended",
			["2"] = "load",
			["3"] = "done",
			["4"] = "hashing",
			["5"] = "error"
		}
		
		state:foreach("torrent", "torrent", function(s)
			ret[#ret+1] = {
				type = "torrent",
				id = "tr_" .. s.path .. "/" .. s.file,
				size = s.size,
				file = s.file,
				percent = s.percent,
				status = tr_stat[s.state] or s.state,
			}
		end)
		
		return ret	
	end
	
--- Pause a given download.
-- @param id Download Unique ID
-- @return void
	function export.dl_pause(id)
		local type, key1, key2 = tr_id(id)
		if type == "download" then
			return export.downloads_pause(key1)
		elseif type == "torrent" then
			return export.torrent_pause(key1, key2)
		end
	end
	
--- (Re)start a given download.
-- @param id Download Unique ID
-- @return void
	function export.dl_start(id)
		local type, key1, key2 = tr_id(id)
		if type == "download" then
			return export.downloads_start(key1)
		elseif type == "torrent" then
			return export.torrent_start(key1, key2)
		end
	end
	
--- Delete a given download.
-- @param id Download Unique ID
-- @return void
	function export.dl_delete(id)
		local type, key1, key2 = tr_id(id)
		if type == "download" then
			return export.downloads_delete(key1)
		elseif type == "torrent" then
			return export.torrent_del(key1, key2)
		end
	end


	function export.downloads_list()
		local ret = {}
		state:foreach("luci_dlmanager", "download", function(s)
			ret[#ret+1] = s
		end)
		return ret
	end

--- Enqueue a new download.
-- @param uri URI
-- @param priority Priority [1, 2, 3, 4, 5]
-- @return table containing: <ul>
-- <li>status = [true, false],</li>
-- <li>id = Download ID (Prefix with dl_ to get the Unique ID)</li>
-- </ul>
	function export.downloads_add(uri, priority)
		priority = priority or 3
		local base = uci:get("luci_dlmanager", "dlmanager", "base")
		if not base or not fs.access(base) then
			return {status = false}
		end

		local sid = sys.uniqueid(16)
		uci:section("luci_dlmanager", "download", sid, {
			uri = uri,
			status = "pending",
			priority = priority
		})
		uci:save("luci_dlmanager")
		uci:commit("luci_dlmanager")
		event.new("SetupDlmd")

		return {status = true, id = sid}
	end
	
--- List all available filehoster cookies.
-- @return table containing one or more tables containing: <ul>
-- <li>domain = Cookie Domain</li>
-- <li>expires = Expiry Timestamp</li>
-- <li>.name = Cookie ID</li>
-- </ul>
	function export.downloads_listcookies()
		local tbl = {}
		uci:foreach("luci_dlmanager", "cookie", function(s)
			tbl[#tbl+1] = s
		end)
		return tbl
	end

--- Remove a given cookie.
-- @param id Cookie ID
-- @return boolean status
	function export.downloads_removecookie(id)
		local stat = uci:delete("luci_dlmanager", id)
		stat = stat and uci:save("luci_dlmanager")
		uci:commit("luci_dlmanager")
		return stat
	end

--- Authenticate with a filehoster to generate a new cookie.
-- @param provider Provider ["rapidshare", ...]
-- @param user Username
-- @param pass Password
-- @return boolean status
	function export.downloads_createcookie(provider, user, pass)
		local m = cbi.load("dlmanager/auth")[2]
		m:handle(cbi.FORM_VALID, {provider=provider, username=user, password=pass})
		return not m.children[1].children[2].error
	end
	
	function export.downloads_pause(section)
		uci:set("luci_dlmanager", section, "status", "suspended")
		uci:save("luci_dlmanager")
		uci:commit("luci_dlmanager")

		local pid = tonumber(state:get("luci_dlmanager", section, "pid"))
		if pid then
			nixio.kill(pid, nixio.const.SIGTERM)
		end
	end

	function export.downloads_start(section)
		uci:set("luci_dlmanager", section, "status", "pending")
		uci:save("luci_dlmanager")
		uci:commit("luci_dlmanager")
	end

	function export.downloads_delete(section)
		uci:set("luci_dlmanager", section, "remove", "1")
		uci:save("luci_dlmanager")
		uci:commit("luci_dlmanager")
	end

	function export.torrent_addurl(url, name)
		local torrent = require "luci.fon.torrent"
		local base = uci:get("luci_dlmanager", "dlmanager", "base")
		assert(base and fs.access(base))
		return torrent.newdownload(url, name, fs.basename(base))
	end
	
	function export.torrent_list()
		local ret = {}
		state:foreach("torrent", "torrent", function(s)
			ret[#ret+1] = s
		end)
		return ret
	end

--	export.torrent_pause = torrentd.pause -- pause(path, file)
--	export.torrent_start = torrentd.start -- start(path, file)
--	export.torrent_stop  = torrentd.stop  -- stop(path, file)
--	export.torrent_del   = torrentd.del   -- del(path, file)

	function export.get_discs()
		local discs = {}
		state:foreach("mountd", "mountd_disc", function(s)
			discs[#discs+1] = (s.vendor or "") .. " " .. (s.model or "")
		end)
		return #discs > 0 and discs or nil
	end

	-- Publish functions
	http.prepare_content("application/json")
	ltn12.pump.all(jsonrpc.handle(export, http.source()), http.write)
end
