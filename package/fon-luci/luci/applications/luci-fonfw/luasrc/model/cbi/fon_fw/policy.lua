-- (c) john@phrozen.org gplv2

require("luci.sys")

n = Map("fon",
	translate("firewall_title2", "Firewall Settings"),
	translate("firewall_desc2", "Here you can configure the access policies between your different networks."))
s = n:section(NamedSection, "firewall", "firewall")
n.events = {"ConfigFwall"}

hotspot_wan = s:option(ListValue, "hotspot_wan", translate("public_wan", "Public->WAN"))
hotspot_wan.override_values = true
hotspot_wan:value("0", translate("deny", "deny"))
hotspot_wan:value("1", translate("allow", "allow"))

lan_wan = s:option(ListValue, "lan_wan", translate("private_wan", "Private->WAN"))
lan_wan.override_values = true
lan_wan:value("0", translate("deny", "deny"))
lan_wan:value("1", translate("allow", "allow"))

hotspot_lan = s:option(ListValue, "hotspot_lan", translate("public_private", "Public->Private"))
hotspot_lan.override_values = true
hotspot_lan:value("0", translate("deny", "deny"))
hotspot_lan:value("1", translate("allow", "allow"))

icmp_wan = s:option(ListValue, "icmp_wan", translate("ping_icmp", "Ping on Wan"))
icmp_wan.override_values = true
icmp_wan:value("0", translate("deny", "deny"))
icmp_wan:value("1", translate("allow", "allow"))

return n
