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
return m
