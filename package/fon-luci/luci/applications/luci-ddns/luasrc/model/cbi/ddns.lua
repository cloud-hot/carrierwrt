-- Copyright 2008 John Crispin <john@phrozen.org>

services_file = "/usr/lib/ddns/services"

require("luci.tools.webadmin")
local m = Map("ddns",
	translate("ddns_title", "Dynamic DNS"),
	translate("ddns_desc", "Here you can configure your Dynamic DNS. You need to have an account from one of the providers. DDNS might not work if you are behind NAT."))

m.events = {"RestartDDNS"}

s = m:section(NamedSection, "ddns_scripts", "service")
s.anonymous = true

enabled = s:option(ListValue, "enabled", translate("status", "Enable"))
enabled.override_values = true
enabled:value("0", translate("disable", "Disabled"))
enabled:value("1", translate("enable", "Enabled"))

service = s:option(ListValue, "service_name", translate("ddns_srv", "Service"))
service.override_values = true
service:depends("enabled", "1")

for line in io.lines(services_file) do
	first, last, name = line:find('^[\t ]*"([^"]*)"')
	if first then
		service:value(name, name)
	end -- Skip other lines, like comments
end

domain = s:option(Value, "domain", translate("ddns_domain", "Domain name to update"))
domain:depends("enabled", "1")

ip_source = s:option(ListValue, "ip_source", translate("ddns_ip", "IP address to send"))
ip_source.override_values = true
ip_source:value("network", translate("ddns_ip_fonera", "Use Fonera internet IP"))
ip_source:value("none", translate("ddns_ip_none", "Let Dynamic DNS provider detect IP"))
ip_source:depends("enabled", "1")


usr = s:option(Value, "username", translate("username", "Username"))
usr:depends("enabled", "1")

pass = s:option(Value, "password", translate("password", "Password"))
pass.password = true
pass:depends("enabled", "1")

return m
