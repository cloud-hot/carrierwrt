-- Copyright 2009 John Crispin <john@phrozen.org>

require("luci.tools.webadmin")

local n = SimpleForm("client",
	translate("openvpn_new_title", "Add a new VPN Clients"),
	translate("openvpn_new_desc", "Please specify the name of this connection."))
local x = n:field(Value, "client", translate("name", "Name"))
local y = n:field(Value, "passphrase", translate("openvpn_passphrase", "Passhrase"),
                  translate("openvpn_passphrase_desc", "This passphrase will be used to encrypt the key file for the client. It will need to be entered on every connection. Leave empty for no passphrase."))
function n.handle(self, state, data)
	if state == FORM_VALID  and data.client and #data.client > 0 then
		local uci = require("luci.model.uci").cursor()
		local sname = data.client:gsub("[^a-zA-Z0-9_]", "_")
		uci:load("openvpn")
		uci:section("openvpn", "client", sname, {name=data.client})
		uci:commit("openvpn")
		cmd = "/usr/sbin/pkitool \""..sname.."\""

		if data.passphrase and #data.passphrase > 0 then
			local keyfile = "/etc/openvpn/keys/" .. sname .. ".key"
			-- Escape "$`\ with a backslash, to prevent
			-- them being interpreted by the shell below.
			local pass = data.passphrase:gsub("([\"$`\\\\])", "\\%1")
			-- Encrypt the keyfile with AES and a
			-- passphrase. We call openssl directly, since
			-- pkitool doesn't support non-interactive
			-- passphrase passing.
			cmd = cmd .. ";openssl rsa -aes256 -in \""..keyfile.."\" -out \""..keyfile.."\" -passout \"pass:"..pass.."\""
		end
		-- Run the command(s) in the background
		os.execute("(" .. cmd .. ")&")
	end
	return true
end

return n
