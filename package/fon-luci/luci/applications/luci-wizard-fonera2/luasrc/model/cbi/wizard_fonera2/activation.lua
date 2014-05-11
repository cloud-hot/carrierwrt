--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

$Id: passwd.lua 2880 2008-08-17 23:47:38Z jow $
]]--
require("luci.tools.webadmin", package.seeall)
f = SimpleForm("register",
	translate("wiz_register", "<h2>Register your cloud-hotspot device!</h2><p>Your La Fonera 2.0 was successfully set up. If you want to take advantage of all the features of your La Fonera 2.0 please register it.</p>"))
	--translate("passwd_title", "Change Password"),
f.cancel = false
f.submit = translate("wiz_next", "Next")
f.title_custom = true
name = f:field(Value, "name", translate("name", "Name"))
name.password = false

subnet_id = f:field(Value, "subnet_id", translate("subnet_id", "Subnet_ID"))
subnet_id.password = false

function set_error()
	name.error = name.error or {}
	name.error[1] = true
	subnet_id.error = subnet_id.error or {}
	subnet_id.error[1] = true
end

function name.validate(self, value, section)
	return value
end

function subnet_id.validate(self, value, section)
	return value
end

function f.handle(self, state, data)
	if state == FORM_INVALID then
		set_error()
	end
	if state == FORM_VALID and data.name and data.subnet_id then
		local uci = require("luci.model.uci").cursor_state()
		uci:set("fon", "tr069", "summary", data.name)
		uci:set("fon", "tr069", "subnetid", data.subnet_id)
		uci:commit("fon")

		data.name = nil
		data.subnet_id = nil
	end
	return true
end

return Template("wizard_fonera2/head"), Template("themes/fon/head_darkorange"), f
