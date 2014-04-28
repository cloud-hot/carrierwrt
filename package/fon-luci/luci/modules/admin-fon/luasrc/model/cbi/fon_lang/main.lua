--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: luci.lua 3519 2008-10-05 17:16:36Z jow $
]]--
require("luci.config")
m = Map("luci",
	translate("lang_title", "Language Settings"),
	translate("lang_desc", "Here you can choose your language settings"))

-- force reload of global luci config namespace to reflect the changes
function m.commit_handler(self)
	package.loaded["luci.config"] = nil
	require("luci.config")
end

c = m:section(NamedSection, "main", "core", "general")

l = c:option(ListValue, "lang", translate("lang_caption", "Language"))

local i18ndir = luci.i18n.i18ndir .. "default."
for k, v in pairs(luci.config.languages) do
	if k:sub(1, 1) ~= "." and luci.fs.isfile(i18ndir .. k:gsub("_", "-") .. ".lua") then
		l:value(k, v)
	end
	l:value("auto", translate("disc_auto", "Automatic"))
end

n = Map("fon",
	translate("timezone_title", "Timezone Settings"),
	translate("timezone_title", "Here you can select your timezone. A timezone change needs a reboot to take effect. The time is automatically synchronized when an internet connection is available."))

-- Offer changing the timezone. Note that this does not update the
-- system config timezone setting (which is processed by
-- /etc/init.d/boot) directly, but instead changes a setting in the fon
-- config which is applied to the system config by /lib/fon/config.sh.
-- This is because the system config expects a timezone descriptor
-- (e.g., CET-1CEST,M3.5.0,M10.5.0/3) while the interface should offer
-- timezone names (e.g Europe/Amsterdam) and because the timezone
-- descriptors are not unique (so if we're just storing the timezone
-- descriptor, we can't tell which timezone the user selected exactly).
--
-- This approach has the added advantage that timezone settings are not
-- applied until after a reboot, which guarantees the new timezone is
-- applied consistently (otherwise, running programs would not pick up
-- the new timezone, while new programs would).
c = n:section(NamedSection, "advanced")
l = c:option(ListValue, "timezone", translate("timezone", "Timezone"), translate("current_time_is", "The current time is: ") .. os.date("%Y.%m.%d %k:%M %Z"))

local util = require "luci.util"
local timezones = io.open((os.getenv("LUCI_SYSROOT") or "") .. "/etc/timezones.db", "r")
l.default = "UTC"
while true do
	local line = timezones:read("*line")
	if not line then break end
	if line ~= "" and line:sub(1,1) ~= "#" then
		split = line:split(" ", 2)
		l:value(split[1], split[1])
	end
end

return m,n
