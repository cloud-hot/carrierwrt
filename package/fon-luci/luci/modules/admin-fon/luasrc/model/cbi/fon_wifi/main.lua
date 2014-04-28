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

local mode = require("luci.model.uci").cursor():get("fon", "advanced", "bgmode")
local wanmode = require("luci.model.uci").cursor():get("fon", "wan", "mode")
local device = require("luci.fon.spot").get_device()

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

o = Map("fon",
	translate("wifi_adv_title", "Advanced Wireless Settings"),
    translate("wifi_adv_desc", "The values in this page will permit you configure very specific WiFi paramters of La Fonera. All of them are optional."))

s = o:section(NamedSection, "advanced", "advanced")
o.events = {"ConfigFON", "ConfigWifi", "Offline"}

-- The wifi client channel also determines the channel for the access
-- point signals, so don't offer channel selection in wifi mode.
if wanmode ~= "wifi" and wanmode ~= "wifi-bridge" then
	channels = s:option(ListValue, "channel", translate("wifi_channel", "Channel"))
	channels:value("auto", translate("wifi_automatic", "Automatic"))
	-- This adds channels 1-11, which are available everywhere.
	-- Below, channels 12 and 13 are added for countries where they
	-- are allowed.
	for i = 1,11 do
		channels:value(i, i)
	end
end

b = s:option(ListValue, "bgmode", translate("wifi_mode", "b/g Mode"))
if device == "fonera20" then
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
	r = s:option(ListValue, "ht", translate("wifi_HT", "11N Mode"))
	r.default = "40"
	r:value("20", translate("wifi_HT20", "HT20"))
	r:value("40", translate("wifi_HT2040", "HT20/HT40"))
	-- HT40 mode is only available in n modes
	r:depends("bgmode", "6")
	r:depends("bgmode", "7")
	r:depends("bgmode", "9")
end

-- 2.0g does not support channel 12 and 13 due to limitations in the
-- HAL.
if device == "fonera20n" and channels then
	local c3166 = loadfile((os.getenv("LUCI_SYSROOT") or "") .. "/etc/3166en.db.lua")()
	c = s:option(ListValue, "country", translate("wifi_country", "Country"))
	c:value("", "Unset")

	-- Find out the country selected. Using formvalue makes sure that it's
	-- not possible to change the country to something not supporting
	-- channel 12/13 and set the channel to 12 or 13 at the same time.
	selected_country = c:formvalue(s.section) or c:cfgvalue(s.section)
	for i, info in ipairs(c3166) do
		cc, cname, regdom = unpack(info)
		c:value(cc, cname)

		-- If the currently selected country is in regdomain 1, allow
		-- channel 12 and 13. We can't add dependencies for this, since
		-- cbi does not support dependencies for individual values, only
		-- for options.
		if selected_country == cc and regdom == 1 then
			channels:value(12, 12)
			channels:value(13, 13)
		end
	end
end


p = Template('fon_wifi/wifi_scan_ui')

return m, n, o, p
