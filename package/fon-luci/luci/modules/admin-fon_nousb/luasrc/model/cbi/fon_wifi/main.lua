require("luci.tools.webadmin")

m = Map("fon",
	translate("public_title", "Public Wireless Settings"),
	translate("public_desc", "This is the name of the signal the rest of the foneros will connect to. It will be automatically prefixed with the 'FON_' string"))

s = m:section(NamedSection, "public", "public")
m.events = {"ConfigFON", "HotspotChanged"}
s:option(Value, "essid", translate("public_essid", "Signal name (SSID)FON_"))

n = Map("fon",
	translate("private_title", "Private Wireless Settings"),
	translate("private_desc", "This is the name of the signal for your personal use."))

s = n:section(NamedSection, "private", "private")

s:option(Value, "essid", translate("private_essid", "Name (SSID)"))
n.events = {"ConfigFON", "ConfigWifi"}

encr = s:option(ListValue, "encryption", translate("encryption", "Authentication"))
encr.override_values = true
encr:value("open", translate("wifi_open", "OPEN"))
encr:value("wep", translate("wifi_wep", "WEP"))
encr:value("wpa", translate("wifi_wpa", "WPA"))
encr:value("wpa2", translate("wifi_wpa2", "WPA2"))
encr:value("mixed", translate("wifi_mixed", "WPA/WPA2-Mixed"))

key = s:option(Value, "key", translate("wifi_wep_key", "WEP Key"))
key:depends("encryption", "wep")
key.rmempty = true

algo = s:option(ListValue, "wpa_crypto",  translate("wifi_cypher", "Cipher"))
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
pass.rmempty = true
pass.default = require("luci.model.uci").cursor():get("fon", "private", "default_psk")

o = Map("fon",
	translate("wifi_adv_title", "Advanced Wireless Settings"),
    translate("wifi_adv_desc", "The values in this page will permit you configure very specific WiFi paramters of La Fonera. All of them are optional."))

s = o:section(NamedSection, "advanced", "advanced")
o.events = {"ConfigFON", "ConfigWifi", "Offline"}
c = s:option(ListValue, "channel", translate("wifi_channel", "Channel"))
c:value("auto", translate("wifi_automatic", "Automatic"))
for i = 1,11 do
	c:value(i, i)
end

b = s:option(ListValue, "bgmode", translate("wifi_mode", "b/g Mode"))
if require("luci.fon.spot").get_device() == "fonera20" then
	b:value("mixed", translate("wifi_mode_mixed","Mixed b/g"))
	b:value("b", translate("wifi_mode_b", "b only"))
	b:value("g", translate("wifi_mode_g", "g only"))
else
	b:value("0", translate("wifi_mode_mixed","Mixed b/g"))
	b:value("9", translate("wifi_mode_mixed_bgn","Mixed b/g/n"))
	b:value("7", translate("wifi_mode_mixed_gn","Mixed g/n"))
	b:value("1", translate("wifi_mode_b", "b only"))
	b:value("4", translate("wifi_mode_g", "g only"))
	b:value("6", translate("wifi_mode_n", "n only"))
end
return m, n, o
