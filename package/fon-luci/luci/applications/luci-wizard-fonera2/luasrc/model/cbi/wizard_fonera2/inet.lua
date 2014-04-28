require("luci.tools.webadmin")

local uci = require("luci.model.uci").cursor()
local mode = uci:get("fon", "wan", "mode")

if mode == "umts" then
	local x = Template("fon_inet/umts")
	x.pageaction = false
	return x
end

local device = require("luci.fon.spot").get_device()

m = Map("fon", "",
	translate("wiz_inet_desc", "If the La Fonera is connected correctly to a modem/router it will be able to connect to the Internet in DHCP mode in most cases.<br><br>If plugged into a modem with only one Ethernet port the La Fonera might need to be set to PPPoE. Your Internet provider (ISP) will tell you what protocol and credential you have to use."))
m.cancelaction = true

s = m:section(NamedSection, "wan", "network")

m.events = {"ConfigFON", "ConfigWanDelay"}

mode = s:option(ListValue, "mode", translate("wan_mode", "Mode"))
mode.override_values = true
mode:value("dhcp", translate("wan_dhcp", "DHCP"))
mode:value("static", translate("wan_static", "Static IP"))
mode:value("pppoe", translate("wan_pppoe", "PPPoE"))
mode:value("bridge", translate("wan_bridge", "Bridge"))
--mode:value("pptp", "PPTP")
mode:value("wifi", translate("wan_wifi", "Wifi"))
if device == "fonera20n" then
	-- Only the 2.0n wifi driver contains a workaround (sort
	-- of NAT on MAC address level) to work without WDS
	mode:value("wifi-bridge", translate("wan_wifibridge", "Wifi bridge"))
end

wan_as_lan = s:option(ListValue, "wan_as_lan", translate("wan_port", "WAN ethernet port"))
wan_as_lan.override_values = true
wan_as_lan:value("0", translate("unused", "Unused"))
wan_as_lan:value("1", translate("extra_lan", "Use as extra LAN port"))
wan_as_lan:depends("mode", "wifi")

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
ssid:depends("mode", "wifi-bridge")

encr = s:option(ListValue, "auth", translate("encryption", "Authentication"))
encr.rmempty = true
encr.override_values = true
encr:value("open", translate("wifi_open", "OPEN"))
encr:value("wep", translate("wifi_wep", "WEP"))
encr:value("wpa", translate("wifi_wpa", "WPA"))
encr:value("wpa2", translate("wifi_wpa2", "WPA2"))
encr:depends("mode", "wifi")
encr:depends("mode", "wifi-bridge")

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
ip:depends("mode", "bridge")
ip:depends("mode", "wifi-bridge")

netmask = s:option(Value, "netmask", translate("wan_netmask", "Netmask"))
netmask.rmempty = true
netmask:depends("mode", "static")
netmask:depends("wmode", "static")
netmask:depends("mode", "bridge")
netmask:depends("mode", "wifi-bridge")

gw = s:option(Value, "gateway", translate("wan_gateway", "Gateway"))
gw.rmempty = true
gw:depends("mode", "static")
gw:depends("wmode", "static")
gw:depends("mode", "bridge")
gw:depends("mode", "wifi-bridge")

ds = s:option(Value, "dns_static", translate("wan_dns", "DNS"))
ds.rmempty = true
ds.default = "0"
ds:depends("mode", "dhcp")
ds:depends("mode", "pppoe")
ds:value("0", translate("automatic", "Automatic"))

dns = s:option(Value, "dns", translate("wan_dns", "DNS"))
dns.rmempty = true
dns:depends("mode", "static")
dns:depends("wmode", "static")
dns:depends("mode", "bridge")
dns:depends("mode", "wifi-bridge")

return Template("wizard_fonera2/head"), Template("themes/fon/head_darkorange"), Template("wizard_fonera2/map_head"), m
