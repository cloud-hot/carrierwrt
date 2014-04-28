--[[
LuCI - Lua Development Framework

Copyright 2009 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local uci = require "luci.model.uci".cursor()

local function update_cookies(cookies)
	if cookies then
		for k, v in pairs(cookies) do
			cookies[k] = nil
		end
	else
		cookies = {}
	end

	uci:foreach("luci_dlmanager", "cookie", function(s)
		s.domain = s.domain and s.domain:sub(1,1) == "." and
			s.domain:sub(2) or s.domain
		cookies[s[".name"]] = s
	end)

	return cookies
end

m = Form("luci_dlmanager", translate("dlm_hoster"))
m.cancel = false
m.submit = false

cookietable = m:section(Table, update_cookies())
cookietable.anonymous = true

domain = cookietable:option(DummyValue, "domain", translate("dlm_service"))
cookietable:option(DummyValue, "_user", translate("username"))

logout = cookietable:option(Button, "remove", translate("remove"))
function logout.write(self, section)
	uci:delete("luci_dlmanager", section)
	uci:save("luci_dlmanager")
	uci:commit("luci_dlmanager")
	cookietable.data[section] = nil
end


local http = require "luci.http.protocol"
local httpc = require "luci.httpclient"

m2 = Form("login", translate("dlm_login"))
provider = m2:field(ListValue, "provider", translate("dlm_provider"))

uci:foreach("luci_dlmanager", "dlprovider", function(s)
	provider:value(s[".name"], s.name)
end)

ufield = m2:field(Value, "username", translate("username"))
pfield = m2:field(Value, "password", translate("password"))
pfield.password = true

function m2.handle(self, state, data)
	if state ~= FORM_VALID or not data.provider then
		return
	end

	local dlp = uci:get_all("luci_dlmanager", data.provider)
	local uri = dlp.loginuri
	local body = dlp.postdata
	local upat = "%%username%%"
	local ppat = "%%password%%"
	local user = data.username and http.urlencode(data.username) or ""
	local pass = data.password and http.urlencode(data.password) or ""
	user = user:gsub("%%", "%%%%")
	pass = pass:gsub("%%", "%%%%")

	if not uri then
		return
	end

	uri = uri:gsub(upat, user):gsub(ppat, pass)
	if body then
		body = body:gsub(upat, user):gsub(ppat, pass)
	end

	local code = false
	local rcs = {}

	-- If the uri is from rapidshare.com, use the rapidshare API
	-- (e.g., fetch the cookie data from the response body instead
	-- of the HTTP headers). See http://rapidshare.com/dev.html and
	-- http://images.rapidshare.com/apidoc.txt. This code makes a
	-- few assumptions that are not documented (cookie name, cookie
	-- domain, etc), but match other implementations (e.g.,
	-- plowshare).
	if uri:match("^https?://[^/]*rapidshare.com/") then
		local apidat = httpc.request_to_buffer(uri, {body = body})
		if apidat then
			local c = apidat:match("cookie=([0-9A-F]+)")
			if c then
				code = 200
				rcs[1] = {key = "enc", value = c, flags = {domain = ".rapidshare.com", path = "/", expires = os.time() + 3600 * 24 * 360}}
			end
		end
	else
	    -- No rapidshare url, do a normal request and store the
	    -- returned cookies. Pass depth = 0 to prevent following any
	    -- redirects and to get the cookies from the first response.
	    local response
	    code, response = httpc.request_raw(uri, {body = body, depth = 0})
	    rcs = code and response.cookies
	end

	if not code or #rcs == 0 or #rcs[1].value < 1 then
		ufield.error = {true}
		pfield.error = {true}
	else
		local cdata = {key=rcs[1].key, value=rcs[1].value}
		for k, v in pairs(rcs[1].flags) do
			cdata[k] = cdata[k] or v
		end
		cdata._user = user

		uci:delete_all("luci_dlmanager", "cookie", {
			domain = cdata.domain,
			path = cdata.path,
			key = cdata.key
		})

		uci:section("luci_dlmanager", "cookie", nil, cdata)

		uci:save("luci_dlmanager")
		uci:commit("luci_dlmanager")

		uci:unload("luci_dlmanager")
		update_cookies(cookietable.data)
	end

	self.data = {}
end

return m, m2
