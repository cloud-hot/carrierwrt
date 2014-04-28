require("luci.tools.webadmin")

m = Map("fon", translate("fonspot_title", "Fonspot"),
	translate("fonspot_desc", "Here you can turn the fonspot on and off."))

s = m:section(NamedSection, "advanced", "advanced")

spot = s:option(ListValue, "sharewifi",  translate("fonspot_share", "Share Wifi"))
spot.default = "1"
spot:value("0", translate("disable", "Disbaled"))
spot:value("1", translate("enable", "Enabled"))

m.events = {"ConfigFON", "RestartChilli"}

return m
