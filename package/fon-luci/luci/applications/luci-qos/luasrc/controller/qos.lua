--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: qos.lua 5118 2009-07-23 03:32:30Z jow $
]]--
module("luci.controller.qos", package.seeall)

function index(env)
	local page = entry({"fon_admin", "qos"}, cbi("qos/qosmini", {on_success_to={"fon_admin"}}), luci.i18n.translate("qos_title", "QoS"))
	page.page_icon = "icons/qos.png"
	page.order = 290
	page.icon = "icons/qos.png"
	page.i18n = "qos"
	page.dependent = true
end
