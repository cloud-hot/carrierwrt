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
require("luci.tools.webadmin")

f = SimpleForm("password",
	translate("passwd_title", "Change Password"),
	translate("passwd_desc", "Here you can change your password"))

pw1 = f:field(Value, "pw1", translate("password", "Password"))
pw1.password = true
pw1.rmempty = false

pw2 = f:field(Value, "pw2", translate("confirmation", "Confirmation"))
pw2.password = true
pw2.rmempty = false

function set_error()
	pw1.error = pw1.error or {}
	pw1.error[1] = true
	pw2.error = pw2.error or {}
	pw2.error[1] = true
end

function pw1.validate(self, value, section)
	local valid = pw2:formvalue(section) == value and value
	if not(valid) then
		set_error()
	end
	return valid
end

function pw2.validate(self, value, section)
	local valid = pw1:formvalue(section) == value and value
	if not(valid) then
		set_error()
	end
	return valid
end

function f.handle(self, state, data)
	if state == FORM_INVALID then
		set_error()
	end
	if state == FORM_VALID then
		local stat = luci.sys.user.setpasswd("root", data.pw1) == 0
		os.execute("pure-pw passwd fonero "..data.pw1)
		os.execute("smbpasswd fonero "..data.pw1)
		data.pw1 = nil
		data.pw2 = nil
		local redir = luci.http.formvalue("redir")
		if redir then
			luci.http.redirect(redir)
		end
	end
	return true
end

return f
