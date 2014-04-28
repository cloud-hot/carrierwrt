--[[
LuCI - Lua Development Framework

Copyright 2009 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local req = require
module "luci.controller.dlmanager"

function index(env)
	local i18n = require "luci.i18n"
	local tr = i18n.translate
	i18n.loadc("dlmanager")

	if env.mounted == "0" then
		local e = entry({"dlmanager"}, template("nodisc"), luci.i18n.translate("dlm_title"))
		e.i18n = "dlmanager"
		e.icon_path	= "/luci-static/resources/"
		e.page_icon	= "dlmanager.png"
		return
	end
	local p = entry({"dlmanager"}, cbi("dlmanager/main"), tr("dlm_title"))
	p.css = {"dlmanager/cascade.css"}
	p.i18n = "dlmanager"
	p.sysauth = "root"
	p.sysauth_authenticator = "htmlauth"
	p.icon_path  = "/luci-static/resources/"
	p.page_icon = "dlmanager.png"

	e = entry({"dlmanager", "add"}, cbi("dlmanager/add", {on_success_to={"dlmanager"}}), tr("dlm_add"))
	e.icon_path  = "/luci-static/resources/"
	e.page_icon = "dlmanager.png"

	e = entry({"dlmanager", "auth"}, cbi("dlmanager/auth"), tr("dlm_hoster"))
	e.icon_path  = "/luci-static/resources/"
	e.page_icon = "dlmanager.png"

	e = entry({"dlmanager", "settings"}, cbi("dlmanager/settings", {on_success_to={"dlmanager"}}), tr("settings"))
	e.icon_path  = "/luci-static/resources/"
	e.page_icon = "dlmanager.png"

	entry({"dlmanager", "_status"}, call("xhr_stat"))
end

local require = req
function xhr_stat()
	local cbi = require "luci.cbi"
	local map = cbi.load("dlmanager/main")[1]
	map:render()
end
