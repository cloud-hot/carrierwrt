--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: qosmini.lua 5118 2009-07-23 03:32:30Z jow $
]]--

local wa = require "luci.tools.webadmin"
local fs = require "nixio.fs"

m = Map("qos",
	translate("qos_title", "QoS"),
	translate("qos_desc", "QoS Description"))
m.events = {"RestartQoS"}

s = m:section(NamedSection, "wan", "interface")

local enable = s:option(ListValue, "enabled", translate("status", "Enable"))
enable.override_values = true
enable:value("0", translate("disable", "Disabled"))
enable:value("1", translate("enable", "Enabled"))

local download = s:option(ListValue, "download", translate("qos_interface_download"))
for i = 128, 1023, 128 do
	download:value(i, i.." KB/s")
end
for i = 1, 10 do
	download:value(i * 1024, i.." MB/s")
end
download:value(25 * 1024, "25 MB/s")
download:value(50 * 1024, "50 MB/s")
download:value(100 * 1024, "100 MB/s")
download:depends("enabled", "1")

local upload = s:option(ListValue, "upload", translate("qos_interface_upload"))
for i = 128, 1023, 128 do
	upload:value(i, i.." KB/s")
end
for i = 1, 10 do
	upload:value(i * 1024, i.." MB/s")
end
upload:value(25 * 1024, "25 MB/s")
upload:value(50 * 1024, "50 MB/s")
upload:value(100 * 1024, "100 MB/s")
upload:depends("enabled", "1")

return m
