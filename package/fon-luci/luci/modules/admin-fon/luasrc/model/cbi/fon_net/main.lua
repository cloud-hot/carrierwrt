require("luci.sys")
require("luci.tools.webadmin")

m = Map("fon",
	translate("net_title", "Private Wireless IP Settings"),
	translate("net_desc", "Here you can choose the ip of you lan and private wifi."))
s = m:section(NamedSection, "lan", "lan")
m.events = {"ConfigFON", "ConfigLan", "ConfigWifi", "SetupHosts", "RestartDnsmasq", "ReconfOpenVPN"}
s:option(Value, "ipaddr", translate("ip", "IP"))
s:option(Value, "netmask", translate("netmask", "Netmask"))
dhcp = s:option(ListValue, "dhcp", translate("dhcp_server", "DHCP Server"))
dhcp.override_values = true
dhcp:value("0", translate("disable", "disable"))
dhcp:value("1", translate("enable", "enable"))


if require("luci.model.uci").cursor():get("fon", "lan", "dhcp") == "0" then
	return m
end

m2 = Map("luci_ethers", translate("dhcp_leases", "DHCP Server"),
	translate("dhcp_leases_desc", "Here you can define static leases for your PC's in the LAN. This makes sure you always get the same IP."))

local leasefn, leasefp, leases
luci.model.uci.cursor():foreach("dhcp", "dnsmasq",
	function(section)
		leasefn = section.leasefile
	end
	)
local leasefp = leasefn and luci.fs.access(leasefn) and io.lines(leasefn)
if leasefp then
	leases = {}
	for lease in leasefp do
		table.insert(leases, luci.util.split(lease, " "))
	end
end

if leases then
	v = m2:section(Table, leases, translate("dhcp_leases_active", "active leases"))
	ip = v:option(DummyValue, 3, translate("ip", "ip"))

	mac  = v:option(DummyValue, 2, translate("mac", "mac"))

	ltime = v:option(DummyValue, 1, translate("dhcp_timeremain", "remaining"))
	function ltime.cfgvalue(self, ...)
		local value = DummyValue.cfgvalue(self, ...)
		return luci.tools.webadmin.date_format(
			os.difftime(tonumber(value), os.time())
		)
	end
end

	s = m2:section(TypedSection, "static_lease", translate("luci_ethers", "Leases"))
	m2.events = {"RestartDnsmasq"}
	s.addremove = true
	s.anonymous = true
	s.template = "cbi/tblsection"

	mac = s:option(Value, "macaddr", translate("macaddress", "MAC"))
	ip = s:option(Value, "ipaddr", translate("ipaddress", "IP"))
	for i, dataset in ipairs(luci.sys.net.arptable()) do
		ip:value(dataset["IP address"])
		mac:value(dataset["HW address"],
		dataset["HW address"] .. " (" .. dataset["IP address"] .. ")")
	end
	hostname = s:option(Value, "hostname", translate("hostname", "hostname"))

return m, m2
