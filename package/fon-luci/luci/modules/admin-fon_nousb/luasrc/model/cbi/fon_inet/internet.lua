require("luci.tools.webadmin")

local uci = require("luci.model.uci").cursor()
local mode = uci:get("fon", "wan", "mode")

if mode == "umts" then
	local x = Template("fon_inet/umts")
	x.pageaction = false
	return x
end

m = Map("fon",
	"",
	translate("inet_desc", "Here you can configure the way your Fonera connects to the Internet. Currently there are 4 protocols available: DHCP, static IP configuration, PPPoE and PPTP. For most people DHCP should work; though, if it doesn't for you, check with your Internet provider (ISP) what protocol you must use or look at the installation reference manual or the troubleshooting manual from FON."))

m.cancelaction = true

s = m:section(NamedSection, "wan", "network")

m.events = {"ConfigFON", "ConfigWan"}

mode = s:option(ListValue, "mode", translate("wan_mode", "Mode"))
mode.override_values = true
mode:value("dhcp", translate("wan_dhcp", "DHCP"))
mode:value("static", translate("wan_static", "Static IP"))
mode:value("pppoe", translate("wan_pppoe", "PPPoE"))
--mode:value("pptp", "PPTP")
if require("luci.fon.spot").get_device() == "fonera20" then
	if uci:get("registered", "fonreg", "dev") == "1" then
		mode:value("wifi", translate("wan_wifi", "Wifi"))
	end
end
user = s:option(Value, "username", translate("wan_user", "Username"))
user:depends("mode", "pppoe")
user:depends("mode", "pptp")
user.rmempty = true

pass = s:option(Value, "password", translate("wan_passwd", "Password"))
pass:depends("mode", "pppoe")
pass:depends("mode", "pptp")
pass.rmempty = true

mtu = s:option(Value, "mtu", translate("wan_mtu", "MTU"))
mtu:depends("mode", "pppoe")
mtu.default = "1492"

mtu = s:option(Value, "mtu2", translate("wan_mtu", "MTU"))
mtu:depends("mode", "pptp")
mtu.default = "1492"

ps = s:option(Value, "pptp_server", "PPTP Server IP")
ps:depends("mode", "pptp")

ssid = s:option(Value, "ssid", translate("wan_ssid", "SSID"))
ssid.rmempty = true
ssid:depends("mode", "wifi")

encr = s:option(ListValue, "auth", translate("encryption", "Authentication"))
encr.rmempty = true
encr.override_values = true
encr:value("open", translate("wifi_open", "OPEN"))
encr:value("wep", translate("wifi_wep", "WEP"))
encr:value("wpa", translate("wifi_wpa", "WPA"))
encr:value("wpa2", translate("wifi_wpa2", "WPA2"))
encr:value("mixed", translate("wifi_mixed", "WPA/PA2-Mixed"))
encr:depends("mode", "wifi")

key = s:option(Value, "key1", translate("wifi_wepkey", "WEP Key"))
key:depends("auth", "wep")
key.rmempty = true

pass = s:option(Value, "psk", translate("wifi_wpa_phrase", "WPA Passphrase"))
pass:depends("auth", "wpa")
pass:depends("auth", "wpa2")
pass:depends("auth", "mixed")
pass.rmempty = true

wmode = s:option(ListValue, "wmode", translate("wan_wifi_type", "Type"))
wmode.rmempty = true
wmode.override_values = true
wmode:value("dhcp", translate("wan_dhcp", "DHCP"))
wmode:value("static", translate("wan_static", "Static IP"))
wmode:depends("mode", "wifi")

ip = s:option(Value, "ipaddr", translate("ip", "IP"))
ip.rmempty = true
ip:depends("mode", "static")
ip:depends("wmode", "static")

netmask = s:option(Value, "netmask", translate("wan_netmask", "Netmask"))
netmask.rmempty = true
netmask:depends("mode", "static")
netmask:depends("wmode", "static")

gw = s:option(Value, "gateway", translate("wan_gateway", "Gateway"))
gw.rmempty = true
gw:depends("mode", "static")
gw:depends("wmode", "static")

ds = s:option(Value, "dns_static", translate("wan_dns", "DNS"))
ds.rmempty = true
ds.default = "0"
ds:depends("mode", "dhcp")
ds:value("0", translate("automatic", "Automatic"))

dns = s:option(Value, "dns", translate("wan_dns", "DNS"))
dns.rmempty = true
dns:depends("mode", "static")
dns:depends("wmode", "static")

return m
