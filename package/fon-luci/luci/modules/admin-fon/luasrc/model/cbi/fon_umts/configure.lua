require("luci.tools.webadmin")

local uci = luci.model.uci.cursor()
local util = require "luci.util"
local pdb = loadfile((os.getenv("LUCI_SYSROOT") or "") .. "/etc/3gsp.db.lua")()
local c3166 = loadfile((os.getenv("LUCI_SYSROOT") or "") .. "/etc/3166en.db.lua")()
local dev = uci:get("registered", "fonreg", "dev") == "1"

local m = Map("fon",
	translate("umts_title", "Provider / SIM settings"),
	translate("umts_cred", "Please select your provider"))
m.events = {"UMTS"}
s = m:section(NamedSection, "advanced")

local pin = s:option(Value, "umts_pin", translate("umts_pin", "PIN"))
pin.override_scheme = true
pin.rmempty = true
pin.password = true

local country = s:option(ListValue, "umts_country", translate("country"))
local provider = s:option(ListValue, "umts_provider", translate("umts_provider"))
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
			provider:value(pk, p.name, {umts_country=cc})
			providers[pk] = p
		end
	end
end

for k in pairs(pdb) do
	provider:depends({umts_country=k})
end

local apn = s:option(Value, "umts_apn", translate("umts_apn", "APN"))
apn:depends({umts_country="_custom"})

function apn.formvalue(self, section)
	local uservalue = Value.formvalue(self, section)

	if not uservalue or #uservalue == 0 then
		local p = providers[provider:formvalue(section)]
		if p then
			uservalue = p and p.apn
		end
	end

	return uservalue or ""
end

local user = s:option(Value, "umts_user", translate("umts_user", "Username"))
user:depends({umts_country="_custom"})

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

local pass = s:option(Value, "umts_pass", translate("umts_pass", "Password"))
pass:depends({umts_country="_custom"})

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

local n = Map("fon", translate("umts_adv_title", "Advanced Settings"))
s = n:section(NamedSection, "advanced")

usedns = s:option(Value, "umts_dns", translate("wan_dns", "DNS"))
usedns.rmempty = true
usedns.default = "1"
usedns:value("0", translate("umts_dns_provider", "provider default (get from list)"))
usedns:value("1", translate("umts_dns_automatic", "automatic (get from network)"))
usedns.events = {"UMTS"}

local mode = s:option(ListValue, "umts_mode", translate("umts_net", "Network"))
mode:value("auto", translate("umts_auto", "automatic"))
mode:value("prefer_gprs", translate("umts_prefer_gprs", "prefer GSM/GPRS"))
mode:value("force_gprs", translate("umts_force_gprs", "force GSM/GPRS"))
mode:value("prefer_umts", translate("umts_prefer_umts", "prefer UMTS"))
mode:value("force_umts", translate("umts_force_umts", "force UMTS"))
mode.default = "auto"
mode.events = {"UMTS"}

local spot = s:option(ListValue, "umts_fonspot", translate("umts_hotspot", "Activate Hotspot"),
	translate("umts_cost_warning", "This may produce extra cost"))
spot.override_values = true
spot.events = {"RestartChilli"}
spot:value("0", translate("disable", "disable"))
spot:value("1", translate("enable", "enable"))

auto = s:option(ListValue, "umts_auto", translate("umts_on_connect", "On device insertion"))
auto.default = "0"
auto:value("0", translate("umts_auto_nothing", "do nothing"))
auto:value("1", translate("umts_auto_connect", "connect automatically"))

if dev then
  verbosity = s:option(ListValue, "umts_verbosity", translate("umts_verbosity", "Log verbosity"))
  verbosity.default = "0"
  verbosity:value("0", translate("umts_verbosity_normal", "normal"))
  verbosity:value("1", translate("umts_verbosity_verbose", "verbose"))
  verbosity:value("2", translate("umts_verbosity_debug", "debug"))
end

return m, n
