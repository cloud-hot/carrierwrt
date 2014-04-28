require("luci.tools.webadmin")

local util = require "luci.util"
local pdb = loadfile((os.getenv("LUCI_SYSROOT") or "") .. "/etc/3gsp.db.lua")()
local c3166 = loadfile((os.getenv("LUCI_SYSROOT") or "") .. "/etc/3166en.db.lua")()
local uci1 = luci.model.uci.cursor()

-- Try to guess the user's country
if not uci1:get("umtsd", "umtsd", "_country") then
	local aclang = luci.http.getenv("HTTP_ACCEPT_LANGUAGE") or ""
	aclang = aclang:match("%s*(%w%w).*") or ""
	aclang = pdb[aclang] and aclang or "es"
	uci1:set("umtsd", "umtsd", "_country", aclang)
	uci1:save("umtsd")
	uci1:commit("umtsd")
end

local uci = luci.model.uci.cursor_state()
local attached = uci:get("umtsd", "umtsd", "attached")
local apn = uci:get("umtsd", "umtsd", "apn") or ""
local pin = uci:get("umtsd", "umtsd", "pin") or ""
local needpin = uci:get("umtsd", "umtsd", "needpin") or ""
local wrongpin = uci:get("umtsd", "umtsd", "wrongpin") or ""
local pinpuk = uci:get("umtsd", "umtsd", "pinpuk") or ""
local authfail = uci:get("umtsd", "umtsd", "authfail") or ""
local online = uci:get("umtsd", "umtsdstate", "online") or "0"
local state = uci:get("umtsd", "umtsdstate", "state") or "0"
local pinchanged
local pukchanged
local authchanged

local m = Map("umtsd",translate("umts_title", "UMTS Settings"))
function m.commit_handler(self, form)
	local u = luci.model.uci.cursor()
	if not(form) then
		return
	end
	if pinchanged then
		u:set("umtsd", "umtsd", "pinfail", "0")
		u:set("umtsd", "umtsd", "wrongpin", "0")
		u:set("umtsd", "umtsd", "needpin", "0")
		local count = tonumber(u:get("umtsd", "umtsd", "failcount") or "0")
		u:set("umtsd", "umtsd", "failcount", count + 1)
	end
	if pukchanged then
		u:set("umtsd", "umtsd", "pinpuk", "0")
	end
	u:commit("umtsd")
end
m.cancelaction = true

s = m:section(NamedSection, "umtsd")

	m.description = translate("umts_cred", "Please enter your UMTS/3G credentials")
	local country = s:option(ListValue, "_country", translate("country"))
	local provider = s:option(ListValue, "_provider", translate("umts_provider"))
	country:value("_custom", translate("umts_custom"))
	
	local providers = {}

	for i, info in ipairs(c3166) do
		local cc, cname, regdom = unpack(info)
		cc = string.lower(cc)

		local plist = pdb[cc]
		if plist then
			country:value(cc, cname)
			
			for k, p in util.kspairs(plist) do
				local pk = cc .. "_" .. k
				provider:value(pk, p.name, {_country=cc})
				providers[pk] = p
			end
		end
	end

	for k in pairs(pdb) do
		provider:depends({_country=k})
	end

	local apn = s:option(Value, "apn", translate("umts_apn", "APN"))
	apn:depends({_country="_custom"})
	
	function apn.formvalue(self, section)
		local uservalue = Value.formvalue(self, section)
		
		if not uservalue or #uservalue == 0 then
			local p = providers[provider:formvalue(section)]
			if p then
				uservalue = p and p.gsm and p.gsm[1]
			end
		end
		
		return uservalue or ""
	end

	local pin = s:option(Value, "pin", translate("umts_pin", "PIN"))
	pin.override_scheme = true
	pin.rmempty = true

	local user = s:option(Value, "user", translate("umts_user", "Username"))
	user:depends({_country="_custom"})
	
	function user.formvalue(self, section)
		local uservalue = Value.formvalue(self, section)
		
		if not uservalue or #uservalue == 0 then
			local p = providers[provider:formvalue(section)]
			if p then
				uservalue = p and p.username
			end
		end
		
		return uservalue or ""
	end
	
	local pass = s:option(Value, "pass", translate("umts_pass", "Password"))
	pass:depends({_country="_custom"})
	
	function pass.formvalue(self, section)
		local uservalue = Value.formvalue(self, section)
		
		if not uservalue or #uservalue == 0 then
			local p = providers[provider:formvalue(section)]
			if p then
				uservalue = p and p.password
			end
		end
		
		return uservalue or ""
	end
	
	local dns = s:option(Value, "dns", translate("wan_dns", "DNS"))
	dns:depends({_country="_custom"})
	
	function dns.formvalue(self, section)
		local uservalue = Value.formvalue(self, section)
		
		if not uservalue or #uservalue == 0 then
			local p = providers[provider:formvalue(section)]
			if p then
				uservalue = p and p.dns
			end
		end
		
		return uservalue or ""
	end
return Template("wizard_fonera2/head"), Template("themes/fon/head_darkorange"), Template("wizard_fonera2/map_head"), m
