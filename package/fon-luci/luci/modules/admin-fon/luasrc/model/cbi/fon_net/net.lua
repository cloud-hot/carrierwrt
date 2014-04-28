require("luci.tools.webadmin")

m = Map("fon", "",
	translate("private_desc", "Here you can choose the ip of you lan and private wifi."))
m.cancelaction = true
s = m:section(NamedSection, "lan", "lan")
m.events = {"ConfigFON", "ConfigLan", "ConfigWifi", "SetupHosts", "RestartDnsmasq", "ReconfOpenVPN"}

s:option(Value, "ipaddr", "IP");
s:option(Value, "netmask", "Netmask");

return m
