require("luci.tools.webadmin")

local mode = require("luci.model.uci").cursor():get("fon", "advanced", "bgmode")
local device = require("luci.fon.spot").get_device()

m = Map("fon", "",
	translate("private_desc", "This is the name of the signal for your personal use."))
m.cancelaction = true
s = m:section(NamedSection, "private", "private")
s:option(Value, "essid", translate("private_essid", "Name (SSID)"))
m.events = {"ConfigFON", "ConfigWifi"}
encr = s:option(ListValue, "encryption", translate("encryption", "Authentication"))
encr.override_values = true
encr:value("open", translate("wifi_open", "OPEN"))
if mode ~= "6" then
	encr:value("wep", translate("wifi_wep", "WEP"))
end
encr:value("wpa", translate("wifi_wpa", "WPA"))
encr:value("wpa2", translate("wifi_wpa2", "WPA2"))
encr:value("mixed", translate("wifi_mixed", "WPA/WPA2-Mixed"))

key = s:option(Value, "key", translate("wifi_wepkey", "WEP Key"), "Hex 10, Hex 26")
key:depends("encryption", "wep")
key.rmempty = true

if mode ~= "6" then
	algo = s:option(ListValue, "wpa_crypto",  translate("wifi_cipher", "Cipher"))
	algo:depends("encryption", "wpa")
	algo:depends("encryption", "wpa2")
	algo:depends("encryption", "mixed")
	algo:value("aes", translate("wifi_cipher_aes", "AES"))
	algo:value("tkip+aes", translate("wifi_cipher_mixed", "Mixed"))
	algo:value("tkip", translate("wifi_cipher_tkip", "TKIP"))
	algo.rmempty = true
	algo.default = "aes"
end

pass = s:option(Value, "password", translate("wifi_wpa_phrase", "WPA Passphrase"))
pass:depends("encryption", "wpa")
pass:depends("encryption", "wpa2")
pass:depends("encryption", "mixed")
pass.default = require("luci.model.uci").cursor():get("fon", "private", "default_psk")
pass.rmempty = true

function pass.cfgvalue(self, section)
	local val = Value.cfgvalue(self, section)
	if not val then
		val = self.default or ""
		self:write(section, val)
	end
	return val
end

if device == "fonera20n" then
	wps = s:option(ListValue, "disable_wps", translate("wps", "Wi-Fi Protected Setup (WPS)"))
	wps.override_values = true
	wps:value("0", translate("enable", "enable"))
	wps:value("1", translate("disable", "disable"))
	wps:depends("encryption", "wpa")
	wps:depends("encryption", "wpa2")
	wps:depends("encryption", "mixed")
end

return m
