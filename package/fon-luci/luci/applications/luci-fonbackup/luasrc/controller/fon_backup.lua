--[[
LuCI - Lua Configuration Interface

Copyright 2009 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local req, assert, ipairs, pairs, pcall = require, assert, ipairs, pairs, pcall
local tonumber, tostring = tonumber, tostring

--- Fonera FonBackup JSON-RPC API
-- @name /luci/fon_rpc/fonbackup
module "luci.controller.fon_backup"

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
	local page = entry({"fon_rpc", "fonbackup"}, call("rpc"))
	page.sysauth = "root"
	page.sysauth_authenticator = authenticator

	-- Plugin root node, add configuration pages or sth later
	node("fonbackup").sysauth = "root"

	-- Register Fileupload/download API
	entry({"fonbackup", "filetransfer"}, call("filetransfer")).sysauth_authenticator = authenticator
	entry({"fon_rpc", "fonbackup", "auth"}, call("rpc_auth")).sysauth = false

	require("luci.i18n")
	luci.i18n.loadc("backup")

	local page  = node("fon_admin", "fon_fileserver")
	page.target = cbi("fileserver", {on_success_to={"fon_admin"}})
	page.title  = luci.i18n.translate("fileserver_title", "Fileserver")
	page.order  = 110
	page.icon_path = "/luci-static/resources/icons"
	page.page_icon = "fileserver.png"
	page.icon = "fileserver.png"

	if (require("luci.model.uci").cursor_state():get("mountd", "mountd", "count") or "0") == "0" then
		local e = entry({"fon_admin", "fon_backup"}, template("nodisc"), luci.i18n.translate("backup_title"), 40)
		e.i18n = "dlmanager"
		e.icon_path	= "/luci-static/resources/icons"
		e.page_icon	= "backup.png"
		e.icon	= "backup.png"
		e.order = 42
		return
	end

	local page = entry({"fon_admin", "fon_backup"}, cbi("backup", {on_success_to = {"fon_dashboard"}}), luci.i18n.translate("backup_title", "Backup Record"), 40)
	page.i18n = "backup"
	page.icon_path = "/luci-static/resources/icons"
	page.page_icon = "backup.png"
	page.icon = "backup.png"
	page.sysauth = "root"
	page.sysauth_authenticator = "htmlauth"
	page.order = 42
end


local require = req

function redir_backup()
	return require("luci.http").redirect(require("luci.dispatcher").build_url("fon_backup"))
end

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

			local clip = http.getenv("REMOTE_ADDR")
			local bcnt = tonumber(uci:get("fonbackup", "fonbackup", "cnt")) or 0

			uci:set("fonbackup", "fonbackup", "lastclip", clip)
			uci:set("fonbackup", "fonbackup", "lastclts", os.time())
			uci:set("fonbackup", "fonbackup", "cnt", bcnt + 1)
			uci:save("fonbackup")
			uci:commit("fonbackup")
		end

		return sid
	end

	http.prepare_content("application/json")
	ltn12.pump.all(jsonrpc.handle(server, http.source()), http.write)
end

local function resolve(rpath, instrict)
	local fs = require "luci.fs"
	local uci = require "luci.model.uci".cursor()
	local util = require "luci.util"
	local table = require "table"
	rpath = rpath and util.split(rpath, "/") or {}

	-- Normalize path
	i = 1
	while i <= #rpath do
		local node = rpath[i]
		if node == "." or node == ".." then
			table.remove(rpath, i)
			if node == ".." then
				if rpath[i-1] then
					i = i - 1
					table.remove(rpath, i)
				end
			end
		else
			i = i + 1
		end
	end

	local base = uci:get("fonbackup", "fonbackup", "base")

	local full = base
	base = base .. "/"
	for k, part in ipairs(rpath) do
		full = full .. "/" .. part
		if k < #rpath or not instrict then
			assert(fs.stat(full, "type") ~= "link", "Invalid symlink")
		end
	end

	return full
end

local function getextdata(dir)
	local io = require "io"
	local fs = require "luci.fs"
	local uci = require "luci.model.uci".cursor()
	local base = uci:get("fonbackup", "fonbackup", "base")
	local dev = "/dev/" .. dir
	local charset
	
	-- Mount disc
	fs.stat(base .. "/" .. dir)
	local df = require "luanet".df()
	local avail = nil
	local stat, iter = pcall(io.lines, "/proc/mounts")
	if stat then
		for line in iter do
			 charset = line:match(dev .. " .*iocharset=([^%s]+)")
			 if charset then
				break
			 end
		end
	end
	for _, dfent in ipairs(df) do
		if dfent.device == dev then
			avail = dfent.avail
			break
		end
	end

	return charset or "utf-8", avail
end



function rpc()
	local os = require "os"
	local fs = require "luci.fs"
	local uci = require "luci.model.uci".cursor_state()
	local http = require "luci.http"
	local posix = require "posix"
	local ltn12 = require "luci.ltn12"
	local jsonrpc = require "luci.jsonrpc_fon"

	-- Object table to be published via RPC
	local export = {}

--- Get information about given file or directory.
---- @param path	Filesystem Path
---- @return		Table containing file or directory properties or nil on error: <ul>
-- <li>size = Filesize</li>
-- <li>atime = Last Accessed Timestamp</li>
-- <li>mtime = Last Modified Timestamp</li>
-- <li>ino = Inode</li>
-- <li>type = Object Type</li>
-- </ul>
	function export.stat(path, ...)
		return fs.stat(resolve(path, true), ...)
	end

--- Test for file access permission on given path.
-- @param path	Filesystem Path
-- @return		0 or true on success, nil otherwise
	function export.access(path, ...)
		return fs.access(resolve(path), ...)
	end

--- List all objects inside a directory.
-- @param path	Filesystem path
-- @return table contaiing directory entries, nil on error
	function export.dir(path)
		return fs.dir(resolve(path))
	end

--- Set the last modification time of given file path in Unix epoch format.
-- @param path	Filesystem Path
-- @param mtime	Last modification timestamp
-- @param atime	Last accessed timestamp
-- @return 0 or true on success
	function export.utime(path, ...)
		return posix.utime(resolve(path), ...)
	end

--- Create a link to a given file or directory.
-- @param target	Target
-- @param path		Filesystem Path
-- @param symlink	Symlink?
-- @return 0 or true on sucess
	function export.link(target, path, ...)
		return fs.link(target, resolve(path), ...)
	end

	--[[
	function export.ftpstatus()
		local pass_set = (uci:get("pureftpd", "pureftpd", "pass_set") == "1")
		local ftpd_run = (uci:get("pureftpd", "pureftpd", "enabled") == "1")
		return (ftpd_run and 1 or 0) + (pass_set and 2 or 0)
	end

	function export.enableftp(passwd)
		local uci2 = require "luci.model.uci".cursor()
		if passwd then
			os.execute("pure-pw passwd fonero '"..passwd:gsub("'", "").."'")
			uci2:set("pureftpd", "pureftpd", "pass_set", "1")
		end
		uci2:set("pureftpd", "pureftpd", "enabled", "1")
		uci2:save("pureftpd")
		uci2:commit("pureftpd")
		require "luci.fon.event".runnow_nowait("RestartFtp")
	end
	]]

	function export.startftp()
		local ftp = require "luci.fon.service".Service("ftp")
		return ftp:status() or ftp:start()
	end

	function export.revertftp()
		local uci2 = require "luci.model.uci".cursor()
		if uci2:get("pureftpd", "pureftpd", "enabled") ~= "1" then
			local ftp = require "luci.fon.service".Service("ftp")
			return ftp:stop()
		end
		return true
	end

--- Return a list of mounted discs.
-- @return table containing one or more tables containing: <ul>
-- <li>device = Device Name</li>
-- <li>vendor = Device Vendor</li>
-- <li>model = Device Model</li>
-- <li>parts = table containing one or more tables containing: <ul>
-- 	<li>device  = Device Name</li>
-- 	<li>iocharset = IO charset</li>
-- 	<li>available = Space available</li>
-- 	<li>size = Size</li>
-- </ul></ul>
	function export.mounted()
		local discs = {}
		uci:foreach("mountd", "mountd_disc", function(s)
			local disc = {device=s.disc, parts={}, vendor=s.vendor,
				model=s.model}
			local sector = tonumber(s.sector_size)
			discs[s[".name"]] = disc
			for k, v in pairs(s) do
				local part = tonumber(k:match("part([0-9]+)mounted"))
				if part then
					local size = tonumber(s["size"..part])
					size = (size and sector) and (size / (1024 / sector))
					local ioc, avail = getextdata(s.disc..part)
					disc.parts[tostring(part)] = {
						device = s.disc .. part,
						iocharset = ioc,
						available = avail,
						size = size
					}
				end
			end
		end)
		return discs
	end

--- Set permissions on given file or directory.
-- @param path	Filesystem Path
-- @param perm	String containing the permissions [r|-][w|-][x|-][r|-][w|-][x|-][r|-][w|-][x|-]
-- @return 0 or true on success
	function export.chmod(path, perm)
		return fs.chmod(resolve(path), perm)
	end

--- Remove a given file.
-- @param path	Filesystem Path
-- @return 0 or true on success
	function export.unlink(path)
		return fs.unlink(resolve(path, true))
	end

--- Create a new directory.
-- @param path	Filesystem Path
-- @return 0 or true on success
	function export.mkdir(path, ...)
		return fs.mkdir(resolve(path), ...)
	end

--- Remove a directory.
-- @param path	Filesystem Path
-- @return 0 or true on success
	function export.rmdir(path)
		return fs.rmdir(resolve(path))
	end

--- Rename a file or directory.
-- @param path1 Source Path
-- @param path2 Destination Path
-- @return 0 or true on success
	function export.rename(path1, path2)
		return fs.rename(resolve(path1), resolve(path2))
	end

--[[
	if (uci:get("fonbackup", "fonbackup", "enabled") ~= "1") then
		export = {}
	end
]]

	-- Publish functions
	http.prepare_content("application/json")
	ltn12.pump.all(jsonrpc.handle(export, http.source()), http.write)
end

function filetransfer()
	local io = require "io"
	local fs = require "luci.fs"
	local http = require "luci.http"
	local ltn12 = require "luci.ltn12"

	local mode = http.formvalue("mode", true)
	local file = resolve(http.formvalue("file", true))

	if mode == "download" then
		local stat = fs.access(file, "r") and fs.stat(file)
		local fp = io.open(file)
		if stat and fp then
			http.header("Content-Length", stat.size)
			http.prepare_content("application/octet-stream")
			ltn12.pump.all(ltn12.source.file(fp), http.write)
		else
			http.status(404, "Not Found")
			http.prepare_content("text/plain")
			http.write("Not found")
		end
	elseif mode == 'upload' then
		local fp = io.open(file, "w")
		if fp and ltn12.pump.all(http.source(), ltn12.sink.file(fp)) then
			http.prepare_content("text/plain")
			http.write("OK")
		else
			http.status(409, "Conflict")
			http.prepare_content("text/plain")
			http.write("Conflict")
		end
	end
end
