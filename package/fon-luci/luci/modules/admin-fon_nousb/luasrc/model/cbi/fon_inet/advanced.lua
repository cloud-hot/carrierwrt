require("luci.tools.webadmin")

local uci = require("luci.model.uci").cursor()

m = Map("fon",
	translate("adv_title", "Advanced Settings"),
	translate("adv_desc", "Some ISPs require the La Fonera to have a special MAC to work correctly. If you experience no problems with your Internet Connection, you should not modify this value"))

s = m:section(NamedSection, "wan", "network")

m.events = {"ConfigFON", "ConfigWan"}

macaddr = s:option(Value, "macaddr", translate("adv_mac", "WAN MAC address"));
macaddr.default = luci.sys.net.getmac("eth0");
macaddr.rmempty = true

return m
