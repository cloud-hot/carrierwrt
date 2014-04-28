--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--
module("luci.controller.fon_admin.fon_admin", package.seeall)

function index()
	require("luci.i18n")

	local page   = node("fon_admin")
	page.i18n = "admin"
	page.title = luci.i18n.translate("settings", "Settings")
	page.order = 20
	page.sysauth = "root"
	page.sysauth_authenticator = "htmlauth"
	page.ucidata = true
	page.target = alias("fon_dashboard")

	entry({"fon_logout"}, call("action_logout"), luci.i18n.translate("logout", "Logout"))
	entry({"fon_banner"}, template("fon/banner"), luci.i18n.translate("fw_ver", "Firmware Version"))

	local page  = node("fon_admin", "fon_pass")
	page.target = cbi("fon_pass/main", {on_success_to={"fon_dashboard"}})
	page.title  = luci.i18n.translate("password", "Password")
	page.order  = 29
	page.icon	= "icons/pass.png"
	page.page_icon	= "icons/pass.png"

	local page  = node("fon_admin", "fon_lang")
	page.target = cbi("fon_lang/main", {on_success_to={"fon_dashboard"}})
	page.title  = luci.i18n.translate("language", "Language")
	page.order  = 25
	page.icon	= "icons/lang.png"
	page.page_icon	= "icons/lang.png"

	local page  = node("fon_admin", "fon_wifi")
	page.target = cbi("fon_wifi/main", {on_success_to={"fon_dashboard"}})
	page.title  = luci.i18n.translate("wireless", "Wireless")
	page.order  = 10
	page.icon   = "icons/wifi.png"
	page.page_icon   = "icons/wifi.png"

	local page  = node("fon_admin", "fon_wifi", "public")
	page.target = cbi("fon_wifi/public")
	page.title  = luci.i18n.translate("public", "Public")

	local page  = node("fon_admin", "fon_wifi", "private")
	page.target = cbi("fon_wifi/private")
	page.title  = luci.i18n.translate("private", "Private")

	local page  = node("fon_admin", "fon_inet")
	page.target = cbi("fon_inet/main", {on_success_to={"fon_dashboard"}})
	page.title  = luci.i18n.translate("internet", "Internet")
	page.order  = 11
	page.icon	= "icons/inet.png"
	page.page_icon	= "icons/inet.png"

	local page  = node("fon_admin", "fon_inet", "internet")
	page.target = cbi("fon_inet/internet")
	page.title  = luci.i18n.translate("internet", "Internet")

	local page  = node("fon_admin", "fon_inet", "local")
	page.target = cbi("fon_inet/local")
	page.title  = luci.i18n.translate("local", "Local")

	local page  = node("fon_admin", "fon_net")
	page.target = cbi("fon_net/main", {on_success_to={"fon_dashboard"}})
	page.title  = luci.i18n.translate("network", "Network")
	page.order  = 12
	page.icon   = "icons/network.png"
	page.page_icon   = "icons/network.png"

	local page  = node("fon_admin", "fon_net", "net")
	page.target = cbi("fon_net/net")
	page.order  = 30

	local page  = node("fon_admin", "fon_net", "status")
	page.target = template("fon_net/status")

	local page  = node("upgrading")
	page.target = template("fon/upgrading")

	local page  = node("fon_admin", "fon_system")
	page.target = call("action_upgrade")
	page.title  = luci.i18n.translate("system", "System")
	page.order  = 23
	page.icon   = "icons/firmware.png"
	page.page_icon   = "icons/firmware.png"

	local page  = node("fon_admin", "fon_system", "LaFonera_Settings.bin")
	page.target = call("action_backup")
	page.title  = luci.i18n.translate("system_settings", "Settings")

	local page  = node("fon_admin", "fon_system", "reboot")
	page.target = call("action_backup")
	page.title  = luci.i18n.translate("system_settings", "Settings")

	local page  = node("fon_admin", "fon_system", "fon_advanced")
	page.target = cbi("fon_inet/advanced", {on_success_to={"fon_admin", "fon_system"}})
	page.title  = luci.i18n.translate("advanced", "Advanced")
	page.page_icon   = "icons/firmware.png"
end

function action_logout()
	local dsp = require "luci.dispatcher"
	local sauth = require "luci.sauth"
	if dsp.context.authsession then
		sauth.kill(dsp.context.authsession)
	end

	luci.http.header("Set-Cookie", "sysauth=; path="..dsp.build_url())
	luci.http.redirect(dsp.build_url())
end

function action_backup()
	local http = require "luci.http"
	http.prepare_content("application/octet-stream")
	os.execute("tar cvzf /tmp/sysupgrade.tgz /etc/passwd /etc/group /etc/dropbear /etc/samba/smbpasswd /etc/samba/secrets.tdb /etc/config/firewall /etc/config/upnpd /etc/config/umtsd /etc/config/registered /etc/config/gdata /etc/config/facebook /etc/config/flickr /etc/config/mountd /etc/config/fon /etc/config/ddns /etc/config/wizard /etc/pureftpd.passwd /etc/pureftpd.pdb /etc/config/pureftpd /etc/config/samba")
	local f = luci.fs.readfile("/tmp/sysupgrade.tgz")
	http.write("UI"..f)
end

function action_upgrade()
	require("luci.model.uci")

	local ret  = nil
	local tmpfile = "/tmp/update.img"
	local keep_avail = true

	local file
	local first = true
	local type
	luci.http.setfilehandler(
		function(meta, chunk, eof)
			if not chunk then
				return
			end
			if first then
				os.remove(tmpfile)
				if chunk:sub(1,2) == "\031\139" then
					type = "tgz"
				elseif chunk:sub(1,2) == "FO" then
					type = "fon"
				elseif chunk:sub(1,2) == "UI" then
					type = "ui"
				else
					ret = luci.i18n.translate("invalid_image", "Invalid image")
				end
			end
			first = false
			if type then
				if not file then
					file = io.open(tmpfile, "w")
				end
				if chunk then
					file:write(chunk)
				end
				if eof then
					file:close()
				end
			end
		end
	)

	local fname   = luci.http.formvalue("image")
	if fname and type then
		ret = luci.i18n.translate("perform_update", "Performing firmware update.")
		if type == "tgz" or type == "fon" then
			local verify = require("luci.fon.pkg.verify")
			local str, key, err = verify.fonidentify(tmpfile)
			if str ~= "reflash" then
				ret = luci.i18n.translate("failed_identify", "Failed to identify upload.")
			else
				local dir, str = verify.fonverify(tmpfile, "/etc/fon/keyring/", false)
				if dir == nil then
					ret = luci.i18n.translate("failed_verify", "Failed to verify upload.")
				else
					local uci = require("luci.model.uci").cursor_state()
					uci:set("fon", "state", "upgrade", dir)
					uci:save("fon")
					require("luci.fon.event").new("FlashDevice")
					return luci.http.redirect(luci.dispatcher.build_url("upgrading"))
				end
			end
		else
			ret = luci.i18n.translate("no_handler", "No handler for this file")
		end
	end

	local fname   = luci.http.formvalue("settings")
	if fname and type then
		if type == "ui" then
			os.execute("dd if="..tmpfile.." of=/sysupgrade.tgz bs=1 skip=2; sync");
			luci.http.header("Set-Cookie", "sysauth=; path=/")
			luci.http.redirect(luci.dispatcher.build_url())
			local event = require("luci.fon.event")
			event.new("Reset")
			return
		end
	end

	local reboot = luci.http.formvalue("reboot")
	local factory = luci.http.formvalue("factory")
	if reboot or factory then
		luci.http.header("Set-Cookie", "sysauth=; path=/")
		luci.http.redirect(luci.dispatcher.build_url())
		local sys = require("luci.fon.sys")
		if factory then
			sys.factorydefault()
		else
			sys.reset()
		end
		return
	end
	luci.http.prepare_content("text/html")
	luci.template.render("fon_firmware/main", {ret=ret})
end
