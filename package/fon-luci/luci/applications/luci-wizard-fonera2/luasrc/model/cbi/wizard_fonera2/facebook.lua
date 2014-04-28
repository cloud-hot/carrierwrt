-- Copyright 2008 John Crispin <john@phrozen.org>

require("luci.tools.webadmin")

local m = SimpleForm("facebook", translate("facebook_auth_title", "Facebook Authentication"))

function m.handle(self, state, data)
	if state == FORM_NODATA then
		-- Keine Daten / nicht abgeschickt
		local facebook = require("luci.fon.facebook")
		local api_key = facebook.get_api_key()
		local auth_token = facebook.get_auth_token() or ""

		local uci = require("luci.model.uci").cursor_state()
		uci:revert("facebook", "facebook", "auth_token", auth_token)
		uci:set("facebook", "facebook", "auth_token", auth_token)
		uci:save("facebook")

		self.description = translate("facebook_auth_desc", "Please follow the steps explained below to authenticate the La Fonera with Facebook"..
			"<ol>"..
			"<li>Click the Facebook button below</li>"..
			"<li>A popup will appear</li>"..
			"<li>Login and allow <b>\"fonload\"</b> to access your facebook account</li>"..
			"<li>Click Next</li>")..
			"<br /><br /><a href=\"http://www.facebook.com/login.php?api_key="..api_key.."&v=1.0&auth_token="..
			auth_token.."\" target=\"_blank\" ><img src=\"http://static.ak.facebook.com/images/devsite/facebook_login.gif\" /></a><br /><br />"
	else
		local facebook = require("luci.fon.facebook")
		local uci = require("luci.model.uci").cursor_state()
		local auth_token = uci:get("facebook", "facebook", "auth_token")
		local key, secret, expires, uid = facebook.get_session_token(auth_token)
		if key and secret and expires and uid then
			local uci = require("luci.model.uci").cursor()
			uci:set("facebook", "facebook", "session_key", key)
			uci:set("facebook", "facebook", "secret", secret)
			uci:set("facebook", "facebook", "expires", expires)
			uci:set("facebook", "facebook", "uid", uid)
			uci:commit("facebook")
			local srv = require("luci.fon.service")
			local service = srv.Service("facebook")
			service:start()
		end
	end
end

m.cancel = false
m.submit = translate("wiz_next", "Next")
return Template("wizard_fonera2/head"), Template("themes/fon/head_darkorange"), m
