-- Copyright 2008 John Crispin <john@phrozen.org>
require("luci.tools.webadmin")

local m = SimpleForm("facebook", translate("facebook_auth_title", "Facebook Authentication"))

function m.handle(self, state, data)
	if state == FORM_NODATA then
		-- Keine Daten / nicht abgeschickt
		local facebook = require("luci.fon.facebook")
		local uci = require("luci.model.uci").cursor_state()
		local session_key = uci:get("facebook", "facebook", "session_key")
		if session_key then
			return
		end
		local auth_token =uci:get("facebook", "facebook", "auth_token")
		local key, secret, expires, uid = facebook.get_session_token(auth_token)
		self.description = ""

		if key and secret and expires and uid then
			local uci = require("luci.model.uci").cursor()
			uci:set("facebook", "facebook", "session_key", key)
			uci:set("facebook", "facebook", "secret", secret)
			uci:set("facebook", "facebook", "expires", expires)
			uci:set("facebook", "facebook", "uid", uid)
			uci:commit("facebook")
			if expires ~= 0 then
				self.description = self.description ..translate("facebook_auth_perm", "This Authentication is only valid for 24 hours. To make it permanent, click the following link")..
				"<br /><br /><a href=\"http://www.facebook.com/authorize.php?api_key="..require("luci.model.uci").cursor():get("facebook", "facebook", "api_key")..
				"&v=1.0&ext_perm=offline_access\" target=\"_blank\" ><img src=\"http://static.ak.facebook.com/images/devsite/facebook_login.gif\" /></a><br /><br />"
			else
				require("luci.http").redirect(require("luci.dispatcher").build_url("facebook"))
				return
			end
		else
			self.description = translate("facebook_auth_fail", "La Fonera was unable to authenticate with Facebook. Please try again.")
		end
	else
		-- Abgeschickt
	end
end

m.cancel = false
m.submit = translate("wiz_next", "Next")
return  m
