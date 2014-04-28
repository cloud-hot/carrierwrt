-- Copyright 2008 John Crispin <john@phrozen.org>

require("luci.tools.webadmin")
local m = Map("pureftpd", "", "")
m.events = {"RestartFtp"}
s = m:section(NamedSection, "pureftpd", "pureftpd")
s.anonymous = true
s:append(Template("backup/ftp"))
mode = s:option(ListValue, "enabled", translate("status", "Enable"))
mode.override_values = true
mode:value("0", translate("disable", "Disabled"))
mode:value("1", translate("enable", "Enabled"))

anon = s:option(ListValue, "noanonymous", translate("anon", "Anonymous"))
anon.override_values = true
anon:value("1", translate("disable", "Disabled"))
anon:value("0", translate("enable", "Enabled"))
anon:depends("enabled", "1")

local m2 = Map("samba", "", "")
m2.events = {"RestartSamba"}
s = m2:section(NamedSection, "samba", "samba")
s.anonymous = true
s:append(Template("backup/samba"))
mode = s:option(ListValue, "enable", translate("status", "Enable"))
mode.override_values = true
mode:value("0", translate("disable", "Disabled"))
mode:value("1", translate("enable", "Enabled"))

anon = s:option(ListValue, "allow_unauth", translate("anon","Anonymous"))
anon:depends("enable","1")
anon.override_values = true
anon:value("0", translate("disable", "Disabled"))
anon:value("1", translate("enable", "Enabled"))
name = s:option(Value,"name", translate("samba_name","Name"))
name:depends("enable","1")
workgroup = s:option(Value,"workgroup", translate("samba_workgroup","Workgroup"))
workgroup:depends("enable","1")
return m, m2
