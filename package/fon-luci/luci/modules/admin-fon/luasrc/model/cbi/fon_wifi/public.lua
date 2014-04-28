require("luci.tools.webadmin")

m = Map("fon", "",
	translate("public_desc", "This is the name of the signal the rest of the foneros will connect to. It will be automatically prefixed with the 'FON_' string"))
m.cancelaction = true
s = m:section(NamedSection, "public", "public")
m.events = {"ConfigFON", "HotspotChanged"}
s:option(Value, "essid", translate("public_essid", "Signal name (SSID)FON_"))
return m
