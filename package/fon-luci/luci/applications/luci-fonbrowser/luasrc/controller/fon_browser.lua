--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

module("luci.controller.fon_browser", package.seeall)

function index()
	require("luci.i18n")
	luci.i18n.loadc("browser")

	-- Alias to /tmp/mounts
	local page = entry({"fon_devices", "fon_browser"}, alias("fon_devices", "_browser", "tmp", "mounts"))
	page.leaf = true
	page.i18n = "browser"
	page.title = luci.i18n.translate("filebrowser", "Filebrowser")
	page.order = 30
	page.icon_select = function()
		local cfg = {"mountd", "mountd", "count"}
		local uci = require("luci.model.uci").cursor_state()
		local val = uci:get(unpack(cfg)) or "0"
		if val and val > "0" then
			return "icons/browser_on.png"
		else
			return "icons/browser_off.png"
		end
	end
	page.fon_status = function()
		local ico = luci.config.main.mediaurlbase.."/icons/browser_%s.png"
		local cfg = {"mountd", "mountd", "count"}
		local uci = require "luci.model.uci".cursor_state()
		local val = uci:get(unpack(cfg))
		local icon = ico % ((not val or val == "0") and "off" or "on")
		return {icon=icon}
	end

	-- Virtual dispatching point holding the complete path
	entry({"fon_devices", "_browser"}, call("dispatcher")).leaf = true
end

function resolve_link(path)
	local fs = require "luci.fs"

	-- Detect loops
	local seen = {}
	local oldpath

	repeat
		if path:sub(1,1) ~= "/" then
			path = fs.dirname(oldpath) .. "/" .. path
		end

		local stat = fs.stat(path)
		if not stat then
			return false
		end

		if seen[stat.ino] then
			return false
		end
		seen[stat.ino] = true

		if stat.type ~= "link" then
			break
		end

		oldpath = path
		path = fs.readlink(path)
	until not path

	if not path then
		return false
	end

	local rpath = {}
	for x in path:gmatch("[^/]+") do
		rpath[#rpath+1] = x
	end

	return rpath
end

function resolve(rpath)
	local table = require "table"

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
	
	return rpath, sanitize("/" .. table.concat(rpath, "/"))
end
	
function sanitize(path)
	local uci = require "luci.model.uci".cursor()
	local fs = require "luci.fs"
	local sane = false
	
	-- Sanitize path
	for _, v in ipairs(uci:get("fon_browser", "browser", "path")) do
		sane = sane or (path == v)
		v = v .. "/"  
		sane = sane or (path:sub(1, #v) == v)
	end


	if sane then
		-- Lookup MIME
		local ext = fs.basename(path):match("%.([%w]+)$")
		local mime = (ext and uci:get("fon_browser", "mime", ext)) or "unknown"
		
		-- Lookup type
		local stat = fs.stat(path)
		return path, stat, mime
	end
end

function dispatcher(...)
	local util = require "luci.util"
	local dsp = require "luci.dispatcher"
	local reqpath = {...}
	local redir = false
	local rpath, path, stat, mime = resolve(reqpath)
	
	while not stat and #dsp.context.requestargs > 0 do
		redir = true
		dsp.context.requestargs[#dsp.context.requestargs] = nil
		dsp.context.request[#dsp.context.request] = nil
		reqpath[#reqpath+1] = ".."
		rpath, path, stat, mime = resolve(reqpath)
	end
	
	if redir and stat then
		local redir = util.clone(dsp.context.request)
		dsp.context = util.threadlocal()
		dsp.context.request = redir
		return dsp.dispatch(dsp.context.request)
	end
	
	if stat and stat.type == "link" then
		rpath = resolve_link(path)
		assert(rpath, "Invalid link!")
		rpath, path, stat, mime = resolve(rpath)
	end

	if stat and stat.type == "directory" then
		browser(rpath, path, stat)
	elseif stat and stat.type == "regular" then
		streamer(rpath, path, stat, mime)
	else
		require "luci.dispatcher".error404()
	end
end

function browser(rpath, path, stat)
	local fs = require "luci.fs"
	local table = require "table"
	local tpl = require "luci.template"
	local dsp = require "luci.dispatcher"
	local util = require "luci.util"
	local uci = require "luci.model.uci".cursor()
	local tools = require "luci.tools.webadmin"
	assert(stat and stat.type == "directory", "Invalid path!")

	local data = {}

	assert(fs.access(path, "x"), "Access Denied!")

	local mods = {}
	uci:foreach("fon_browser", "module", function(section)
		section.name = section[".name"]
		mods[#mods+1] = section
	end)

	table.sort(mods, function(a,b)
		return ((tonumber(a.priority) or 0) > (tonumber(b.priority) or 0))
	end)

	local base = dsp.context.requestpath
	local objects = {}
	
	for _, obj in ipairs(fs.dir(path)) do
		if obj ~= "." and obj ~= ".." then
			objects[obj] = fs.stat(path .. "/" .. obj)
		end
	end
	
	local function sort(a, b)
		if objects[a].type ~= objects[b].type then
			return objects[a].type < objects[b].type
		else
			return a < b
		end
	end

	for node, stat in util.spairs(objects, sort) do
		local fpath = path .. "/" .. node

		stat.modules = {}
		stat.name = node
		stat.fullpath = fpath
		stat.href = dsp.build_url(unpack(util.combine(base, {node})))

		if stat.type == "link" then
			local rpath = resolve_link(fpath)
			if rpath then
				_, _, rstat = resolve(rpath)
				if rstat then
					util.update(stat, rstat)
				end
			end
		end

		if stat.type == "directory" then
			stat.icon = "folder"
		end

		if stat.type == "regular" then
			local priority = nil
			local ext = node:match("%.([%w]+)$")
			ext = ext and ext:lower()
			local mime = (ext and uci:get("fon_browser", "mime", ext)) or "unknown"
			if mime:sub(1, 5) == "video" or mime:sub(1, 5) == "image" then
				stat.icon = mime:sub(1,5)
			else
				stat.icon = mime:gsub("/", "-")
			end
			stat.mod_time = os.date("%x", stat.mtime)
			stat.human_size = tools.byte_format(stat.size)

			-- Select modules
			for _, mod in ipairs(mods) do
				-- Filter for Mime
				if not mod.filter or util.contains(mod.filter, mime) then
					-- Add module templates to modules list
					stat.modules[#stat.modules+1] = mod
				end
			end
		end

		-- Skip special objects and objects without access rights
		if (node ~= "." and node ~= "..") and (
		 (stat.type == "directory" and fs.access(fpath, "x")) or
		 (stat.type == "regular"   and fs.access(fpath, "r"))
		) then
			data[#data+1] = stat
		end
	end

	tpl.render("fon_browser/browser", {dir=data, base=base, rpath=rpath})
end

function streamer(rpath, path, stat, mime)
	local nixio = require "nixio"
	local http = require "luci.http"
	local ltn12 = require "luci.ltn12"

	assert(stat and stat.type == "regular", "Invalid file!")
	http.prepare_content(mime or "application/octet-stream")
	http.header("Content-Length", stat.size)

	-- Pump blockwise
	http.splice(nixio.open(path))
end
