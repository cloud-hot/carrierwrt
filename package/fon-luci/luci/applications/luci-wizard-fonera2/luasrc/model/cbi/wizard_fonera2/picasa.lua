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

f = SimpleForm("password",
	translate("picasa_passwd_title", "Youtube username and password"),
	translate("picasa_passwd_desc", "Please fill in with your picasa username and password to let La Fonera upload your images."))
f.cancel = false
f.submit = translate("wiz_next", "Next")
user = f:field(Value, "user", translate("username", "Username"))

pw = f:field(Value, "pw", translate("password", "Password"))
pw.password = true

function set_error()
	pw.error = pw.error or {}
	pw.error[1] = true
	user.error = user.error or {}
	user.error[1] = true
end

function user.validate(self, value, section)
	return value
end

function pw.validate(self, value, section)
	local gdata = require "luci.fon.gdata"
	local auth = gdata.get_auth_token(user:formvalue(section), value, "lh2")
	if not(auth) then
		set_error()
	end
	return value
end

function f.handle(self, state, data)
	if state == FORM_VALID  and data.user and data.pw and #data.user > 0 and #data.pw > 0 then
		local gdata = require "luci.fon.gdata"
		gdata.adduser("picasa", data.user, data.pw)
	end
	return true
end

return Template("wizard_fonera2/head"), Template("themes/fon/head_darkorange"), Template("wizard_fonera2/map_head"), f
