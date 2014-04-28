-- (c) john@phrozen.org gplv2

require("luci.sys")
o = Map("upnpd",
	translate("upnp_title", "UPNP Settings"),
	translate("upnp_desc", "UPnP allows PCs connected to the Fonera to request port forwardings"))

s = o:section(NamedSection, "config", "upnpd")
o.events = {"ConfigUPNP"}

upnp = s:option(ListValue, "enable", translate("upnp_enable", "Enable UPnP"))
upnp.override_values = true
upnp:value("0", translate("disable", "Disable"))
upnp:value("1", translate("enable", "Enable"))

return o
