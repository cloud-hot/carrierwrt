m = Map("ushare", translate("ushare", "UPnP Media Server"),
	translate("ushare_desc", "The Mediaserver allows you to watch movies or play music files located on the Foneras harddisc, using a UPnP enabled device."))

m.events = { "RestartMedia" }

s = m:section(TypedSection, "ushare", translate("settings"))
s.addremove = false
s.anonymous = true

local enable = s:option(ListValue, "enabled", translate("status", "Enable"))
enable.override_values = true
enable:value("0", translate("disable", "Disabled"))
enable:value("1", translate("enable", "Enabled"))

local name = s:option(Value, "servername", translate("servername", "Servername"))
name:depends("enabled", "1")
name.default = "Fonera"
return m
