--[[
LuCI - Lua Development Framework 

Copyright 2009 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

m = Map("luci_dlmanager", translate("settings"))
s = m:section(NamedSection, "dlmanager", "dlmanager")

local base = s:option(ListValue, "base", translate("dlm_preferred_dev"))
for _, v in pairs(luci.fs.dir("/tmp/mounts") or {}) do
	if v ~= "." and v ~= ".." then
		base:value("/tmp/mounts/" .. v, v)
	end
end

local preferred_base = require("luci.model.uci").cursor():get("luci_dlmanager", "dlmanager", "base")
local actual_base = require("luci.model.uci").cursor():get("luci_dlmanager", "dlmanager", "actual_base")
if preferred_base and #preferred_base ~= 0 and preferred_base ~= actual_base then
	-- If our preferred download device is not available, manually
	-- add an entry to the dropdown (so the current value can still
	-- be displayed). While we're doing that, we can as well mark it
	-- as "unavailable"
	from, to, basename = preferred_base:find('.*/([^/]*)')
	base:value(preferred_base, basename .. " (" .. translate('dlm_na') .. ")")
	-- and show the actual used value as well.
	s:option(DummyValue, "actual_base", translate("dlm_actual_dev"))
end

s:option(DummyValue, "path", translate("dlm_targetpath"))
threads = s:option(ListValue, "threads", translate("dlm_concurrent"))
for i = 1, 5 do
	threads:value(i)
end

when = s:option(ListValue, "when", translate("dlm_process"))
when:value("always", translate("dlm_always"))
when:value("hours", translate("dlm_hours"))

h_from = s:option(ListValue, "hours_from", translate("dlm_from"))
h_from:depends({when="hours"})

h_until = s:option(ListValue, "hours_until", translate("dlm_until"))
h_until:depends({when="hours"})

for i=0, 23.5, 0.5 do
	h_from:value(i, "%02d:%02d" % {i - i%1, (i % 1) * 60})
	h_until:value(i, "%02d:%02d" % {i - i%1, (i % 1) * 60})
end

  

m.events = {"SetupDlmd"}

return m
