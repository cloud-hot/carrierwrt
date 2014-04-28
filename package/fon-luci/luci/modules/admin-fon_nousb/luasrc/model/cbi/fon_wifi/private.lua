require("luci.tools.webadmin")

m = Map("fon", "",
	translate("private_desc", "This is the name of the signal for your personal use."))
m.cancelaction = true
s = m:section(NamedSection, "private", "private")
s:option(Value, "essid", translate("public_essid", "Name (SSID)"))
m.events = {"ConfigFON", "ConfigWifi"}
encr = s:option(ListValue, "encryption", translate("encryption", "Authentication"))
encr.override_values = true
encr:value("open", translate("wifi_open", "OPEN"))
encr:value("wep", translate("wifi_wep", "WEP"))
encr:value("wpa", translate("wifi_wpa", "WPA"))
encr:value("wpa2", translate("wifi_wpa2", "WPA2"))
encr:value("mixed", translate("wifi_mixed", "WPA/WPA2-Mixed"))

key = s:option(Value, "key", translate("wifi_wepkey", "WEP Key"))
key:depends("encryption", "wep")
key.rmempty = true

algo = s:option(ListValue, "wpa_crypto",  translate("wifi_cipher", "Cipher"))
algo:depends("encryption", "wpa")
algo:depends("encryption", "wpa2")
algo:depends("encryption", "mixed")
algo:value("tkip+aes", translate("wifi_cipher_mixed", "Mixed"))
algo:value("aes", translate("wifi_cipher_aes", "AES"))
algo:value("tkip", translate("wifi_cipher_tkip", "TKIP"))
algo.rmempty = true
algo.default = "aes"

pass = s:option(Value, "password", translate("wifi_wpa_phrase", "WPA Passphrase"))
pass:depends("encryption", "wpa")
pass:depends("encryption", "wpa2")
pass:depends("encryption", "mixed")
pass.default = require("luci.model.uci").cursor():get("fon", "private", "default_psk")
pass.rmempty = true

return m
