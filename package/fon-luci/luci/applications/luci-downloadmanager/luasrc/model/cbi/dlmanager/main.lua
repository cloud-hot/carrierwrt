--[[
LuCI - Lua Development Framework 

Copyright 2009 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local http = require "luci.http"
local fs = require "luci.fs"
local sys = require "luci.sys"
local nixio = require "nixio"
local math = require "math"
local util = require "luci.util"
local webadmin = require "luci.tools.webadmin"
local uci = require "luci.model.uci".cursor()
local state = require "luci.model.uci".cursor_state()


if http.formvalue("debug_start") then
	if nixio.fork() == 0 then
		print "resetting signal handlers"
		print(nixio.signal(nixio.const.SIGCHLD, "dfl"))
		print(nixio.signal(nixio.const.SIGTERM, "dfl"))
		dofile((os.getenv("LUCI_SYSROOT") or "") .. "/usr/bin/luci-dlmanagerd")
	end
end


m = Map("luci_dlmanager", translate("dlm_downloads"), translate("the_disclaimer", "You should not download copyrighted material unless you have permission from the copyright holder to do so."))
m.pageaction = false

s = m:section(TypedSection, "download")
s.template = "cbi/tblsection"
s.anonymous = true

function s.cfgsections(self)
	local osections = TypedSection.cfgsections(self)
	local sections = {}
	for i, s in pairs(osections) do
		if not self.map:get(s, "remove") then
			sections[#sections+1] = s
		end
	end
	table.sort(sections, function(a, b)
		return	(tonumber(self.map:get(a, "priority")) or 5)
			<	(tonumber(self.map:get(b, "priority")) or 5)
	end)
	return sections
end

status = s:option(DummyValue, "_status", translate("dlm_status"))
status._state = state
status.template = "dlmanager/status"


extstat = s:option(DummyValue, "_extstat", translate("dlm_progress"))
extstat.template = "dlmanager/progress"

function extstat.cfgvalue(self, section)
	if not self.map:get(section, "file") then
		return "-"
	end
	local localsize = tonumber(state:get("luci_dlmanager", section, "stepsize")) or "n/a"
	local remotesize = self.map:get(section, "size")
	local out = ""
	local perc = nil
	
	if localsize ~= "n/a" and tonumber(remotesize) then
		perc = (100 * localsize / tonumber(remotesize))
		out = out .. "%.1f%%" % perc
	elseif localsize ~= "n/a" then
		out = out .. webadmin.byte_format(localsize)
	else
		out = out .. localsize
	end
	
	local speed = state:get("luci_dlmanager", section, "stepspeed")
	if tonumber(speed) then
		out = out .. " / " .. webadmin.byte_format(tonumber(speed)) .. "/s"
	end 
	
	return out, perc
end


file = s:option(DummyValue, "file", translate("dlm_file"))
function file.cfgvalue(self, section)
	local uri = self.map:get(section, "uri")
	local name = self.map:get(section, "name")
	if state:get("luci_dlmanager", section, "status") == "error" then
		local code = state:get("luci_dlmanager", section, "errcode")
		local status = code
		if code == "-6" then
			status = translate("dlm_ectype")
		elseif code == "-5" then
			status = translate("dlm_ecrtarget")
		elseif code == "403" or code == "401" then
			status = translate("dlm_eaccess")
		elseif code == "404" then
			status = translate("dlm_enotfound")
		end
		return translatef("dlm_ereq", nil, uri or "", status)
	else
		local val = DummyValue.cfgvalue(self, section)
		return (val and luci.fs.basename(val)) or 
		name or (uri and luci.fs.basename(uri))
	end
end


size = s:option(DummyValue, "size", translate("size"))
function size.cfgvalue(...)
	local remotesize = tonumber(DummyValue.cfgvalue(...))
	return remotesize and webadmin.byte_format(remotesize) or translate("dlm_unknown")
end

actions = s:option(Value, "_actions", translate("dlm_commands"))
actions.template = "dlmanager/actions"
actions._state = state

function actions.write(self, section)
	local cbid = self:cbid(section)	
	local action = next(http.formvaluetable(cbid))
	local sf = action and action:sub(-2)
	action = (sf == ".x" or sf == ".y") and action:sub(1, #action-2) or action
	
	if action == "pause" then
		uci:set("luci_dlmanager", section, "status", "suspended")
	elseif action == "start" then
		uci:set("luci_dlmanager", section, "status", "pending")
	elseif action == "delete" then
		uci:set("luci_dlmanager", section, "remove", 1)
	else
		return
	end

	uci:save("luci_dlmanager")
	uci:commit("luci_dlmanager")
	
	if action == "pause" then
		local pid = state:get("luci_dlmanager", section, "pid")
		if pid then
			nixio.kill(pid, nixio.const.SIGTERM)
		end
	end
end

--

if http.formvalue("dlmanager.purge_complete") then
	uci:delete_all("luci_dlmanager", "download", {status = "done"})
	uci:save("luci_dlmanager")
	uci:commit("luci_dlmanager")
end

if http.formvalue("dlmanager.purge_stopped") then
	uci:delete_all("luci_dlmanager", "download", {status = "done"})
	uci:delete_all("luci_dlmanager", "download", {status = "aborted"})
	uci:delete_all("luci_dlmanager", "download", {status = "error"})
	uci:save("luci_dlmanager")
	uci:commit("luci_dlmanager")
end

if http.formvalue("dlmanager.restart_stopped") then
	uci:foreach("luci_dlmanager", "download", function(s)
		if s.status == "suspended" or s.status == "error" then
			uci:set("luci_dlmanager", s[".name"], "status", "pending")
		end
	end)
	uci:save("luci_dlmanager")
	uci:commit("luci_dlmanager")
end

if http.formvalue("dlmanager.stop_started") then
	local tokill = {}
	uci:foreach("luci_dlmanager", "download", function(s)
		if s.status == "pending" then
			uci:set("luci_dlmanager", s[".name"], "status", "suspended")
			tokill[#tokill+1] = state:get("luci_dlmanager", s[".name"], "pid")
		end
	end)
	uci:save("luci_dlmanager")
	uci:commit("luci_dlmanager")
	for k, pid in ipairs(tokill) do
		nixio.kill(tonumber(pid), nixio.const.SIGTERM)
	end
end


return m, Template("dlmanager/purge"), Template("dlmanager/menu")
