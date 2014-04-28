-- (c) john@phrozen.org gplv2

require("luci.sys")
m = Map("firewall",
	translate("firewall", "Firewall"),
	translate("firewall_description", "Here you can configure your firewall."))
m.events = {"ConfigFwall"}

s = m:section(TypedSection, "redirect", "")
s:depends("src", "wan")
s.defaults.src = "wan"

s.template  = "cbi/tblsection"
s.addremove = true
s.anonymous = true

proto = s:option(ListValue, "proto", translate("protocol", "Protocol"))
proto:value("tcp", "TCP")
proto:value("udp", "UDP")
proto:value("tcpudp", "TCP+UDP")

dport = s:option(Value, "src_dport", translate("src_port", "Source Port"))

to = s:option(Value, "dest_ip", translate("ip", "IP address"))

toport = s:option(Value, "dest_port", translate("target_port", "Target Port"))

return m
