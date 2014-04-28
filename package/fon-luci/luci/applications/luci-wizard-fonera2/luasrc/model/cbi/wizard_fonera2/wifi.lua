require("luci.tools.webadmin")

m = Map("fon",
	translate("wiz_f2_wifi_title", "Configure your Wifi"),
	"")

m.events = {"ConfigFON", "ConfigWifi", "HotspotChanged"}

s = m:section(NamedSection, "public", "public")
s:option(Value, "essid", translate("wiz_f2_public", "Public Signal (FON_)"))

s = m:section(NamedSection, "private", "private")
s:option(Value, "essid", translate("wiz_f2_private", "Private Signal"))

local enc = require("luci.model.uci").cursor_state():get("fon", "private", "encryption")
if enc == "wpa" or enc == "wpa2" then
	pass = s:option(Value, "password", translate("wiz_f2_wifi_key", "Wifi Passphrase"))
	pass.default = require("luci.model.uci").cursor():get("fon", "private", "default_psk")
	pass.override_dependencies = true
elseif enc == wep then
	key = s:option(Value, "key", translate("wiz_f2_wifi_key", "Wifi Passphrase"))
	pass.override_dependencies = true
end
return Template("wizard_fonera2/head"), Template("themes/fon/head_darkorange"), m, n
