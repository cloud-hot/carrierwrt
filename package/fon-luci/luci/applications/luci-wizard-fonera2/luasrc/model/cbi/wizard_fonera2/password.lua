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
local SSH_WARNING = ""
if require("luci.model.uci").cursor():get("registered", "fonreg", "dev") == "1" then
	SSH_WARNING = "<h2 style=\"color: #ff0000\">" .. translate("wiz_sshwarning", "The La Fonera will only start SSH access when your password<br> is at least 8 letters long and contains at least 1 number") .. "</h2>"
end
f = SimpleForm("password",
	translate("wiz_passwd", "<h2>Please set your password</h2><p>Here you need to set what will become your password for:</p><ol><li>Fonera administration</li>	<li>Backup tool (and FTP server therefore)</li><li>Samba (smb://) network file sharing account</li></ol>")..SSH_WARNING)
	--translate("passwd_title", "Change Password"),
f.cancel = false
f.submit = translate("wiz_next", "Next")
f.title_custom = true
pw1 = f:field(Value, "pw1", translate("password", "Password"))
pw1.password = true

pw2 = f:field(Value, "pw2", translate("confirmation", "Confirmation"))
pw2.password = true

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
	if state == FORM_VALID and data.pw1 and data.pw1 == data.pw1 then
		local stat = luci.sys.user.setpasswd("root", data.pw1) == 0
		os.execute("pure-pw passwd fonero "..data.pw1)
		os.execute("smbpasswd fonero "..data.pw1)
		data.pw1 = nil
		data.pw2 = nil
	end
	return true
end

return Template("wizard_fonera2/head"), Template("themes/fon/head_darkorange"), f
