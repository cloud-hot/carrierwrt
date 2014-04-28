--[[
LuCI - Lua Development Framework 

Copyright 2009 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local fs = require "luci.fs"
local sys = require "luci.sys"
local nixio = require "nixio"
local util = require "luci.util"
local uci = require "luci.model.uci".cursor()
local nixio = require "nixio"
local httpc = require "luci.httpclient"

m2 = Form("newdl", translate("dlm_add"), nil, {priority="3"})
uris = m2:field(TextValue, "uris", translate("dlm_uris"))
uris.rows = 10

m2:field(Value, "name", translate("dlm_name", "Name"))

prio = m2:field(ListValue, "priority", translate("dlm_priority"))
for i = 1, 5 do
	prio:value(i)
end


local function fetch_cookies()
	local cookies = {}

	uci:foreach("luci_dlmanager", "cookie", function(s)
		local cookie = {flags={}, key = s.key, value=s.value}
		for k, v in pairs(s) do
			if k:sub(1,1) ~= "." and k:sub(1,1) ~= "_" 
			and k ~= "key" and k ~= "value" then
				cookie.flags[k] = v
			end
		end
		cookies[#cookies+1] = cookie
	end)

	return cookies
end


function m2.handle(self, status, data)
	local render, state
	if data.uris and #data.uris > 0 then
		local base = uci:get("luci_dlmanager", "dlmanager", "actual_base")
		if not base or not fs.access(base) then
			self.errmessage = translate("dlm_etargetna")
			state = FORM_INVALID
			return render, state
		end
		
		local path = uci:get("luci_dlmanager", "dlmanager", "path") or ""
		base = base .. "/" .. path 
		if not fs.access(base) then
			fs.mkdir(base)
		end
		
		local oflags = nixio.open_flags("wronly", "creat")
		local htopts = {cookies = fetch_cookies()}
		local cnt = 0
		local toomany = {}

		for _, uri in ipairs(util.split(data.uris, "\r?\n", nil, true)) do
			uri = uri:trim()
			--[[
			if (cnt > 10 or #toomany > 0) and #uri > 0 then
				toomany[#toomany+1] = uri
				self.errmessage = translate("dlm_toomany")
				state = FORM_PROCEED
			elseif #uri > 0 then
				cnt = cnt + 1
				local code, resp, msg = httpc.request_raw(uri, htopts)
				if not code then
					resp = {status = msg}
				elseif code == 403 or code == 401 then
					resp.status = translate("dlm_eaccess")
				elseif code == 404 then
					resp.status = translate("dlm_enotfound")
				end
				local c = resp and resp.headers and resp.headers["Content-Type"]
				if code == 200 and c and c:find("text/html") then
					code = -1
					resp.status = translate("dlm_ectype")
				end
				if code == 302 then
					toomany[#toomany+1] = uri
					self.errmessage = translate("dlm_toomany")
					state = FORM_PROCEED
				else
					if code ~= 200 then
						self.errmessage = translatef("dlm_ereq", nil, uri or "", resp.status)
						state = FORM_INVALID
						return render, state
					end
					local file = fs.basename(resp.uri)
					local fd = nixio.open(base .. "/" .. file, oflags)
					if not fd then
						self.errmessage = translate("dlm_ecrtarget")
						state = FORM_INVALID
						return render, state
					end
					fd:close()
			]]
					if uri:match("^https?://[^/]+/.+") then
						uci:section("luci_dlmanager", "download", sys.uniqueid(16), {
							uri = uri,
							--file = base .. "/" .. file,
							status = "pending",
							priority = data.priority,
							name = data.name,
							--size = tonumber(resp.headers["Content-Length"])
						})
					end
			--[[	end
			end]]
		end
		uci:save("luci_dlmanager")
		uci:commit("luci_dlmanager")

		if #toomany > 0 then
			data.uris = table.concat(toomany, "\r\n")
		end

		require "luci.fon.event".new("SetupDlmd")
	end

	return render, state
end

return m2

