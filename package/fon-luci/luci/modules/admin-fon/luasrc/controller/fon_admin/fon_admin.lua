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
	page.index = true

	entry({"fon_logout"}, call("action_logout"), luci.i18n.translate("logout", "Logout"))
	entry({"fon_banner"}, template("fon/banner"), luci.i18n.translate("fw_ver", "Firmware Version"))

	local page  = node("fon_admin", "fon_pass")
	page.target = cbi("fon_pass/main", {on_success_to={"fon_admin"}})
	page.title  = luci.i18n.translate("password", "Password")
	page.order  = 29
	page.icon	= "icons/pass.png"
	page.page_icon	= "icons/pass.png"

	local page  = node("fon_admin", "fon_lang")
	page.target = cbi("fon_lang/main", {on_success_to={"fon_admin"}})
	page.title  = luci.i18n.translate("language", "Language")
	page.order  = 25
	page.icon	= "icons/lang.png"
	page.page_icon	= "icons/lang.png"

	local page  = node("fon_admin", "fon_wifi")
	page.target = cbi("fon_wifi/main", {on_success_to={"fon_admin"}})
	page.title  = luci.i18n.translate("wireless", "Wireless")
	page.order  = 10
	page.icon   = "icons/wifi.png"
	page.page_icon   = "icons/wifi.png"

	local page  = node("fon_admin", "fon_wifi", "wifi_scan")
	page.target = call("wifi_scan", false)

	local page  = node("fon_admin", "fon_wifi", "public")
	page.target = cbi("fon_wifi/public")
	page.title  = luci.i18n.translate("public", "Public")

	local page  = node("fon_admin", "fon_wifi", "private")
	page.target = cbi("fon_wifi/private")
	page.title  = luci.i18n.translate("private", "Private")

	local page  = node("fon_admin", "fon_inet")
	page.target = cbi("fon_inet/main", {on_success_to={"fon_admin"}})
	page.title  = luci.i18n.translate("internet", "Internet")
	page.order  = 11
	page.icon	= "icons/inet.png"
	page.page_icon	= "icons/inet.png"

	local page  = node("fon_admin", "fon_inet", "internet")
	page.target = cbi("fon_inet/internet")
	page.title  = luci.i18n.translate("internet", "Internet")

	local page  = node("fon_admin", "fon_inet", "wifi_scan")
	page.target = call("wifi_scan", true)

	local page  = node("fon_admin", "fon_inet", "local")
	page.target = cbi("fon_inet/local")
	page.title  = luci.i18n.translate("local", "Local")

	local mode = require("luci.model.uci").cursor():get("fon", "wan", "mode")

	local page  = node("fon_admin", "fon_net")
	if mode == "bridge" or mode == "wifi-bridge" then
		page.target = template("fon_net/bridge")
	else
		page.target = cbi("fon_net/main", {on_success_to={"fon_admin"}})
	end
	page.title  = luci.i18n.translate("network", "Network")
	page.order  = 12
	page.icon   = "icons/network.png"
	page.page_icon   = "icons/network.png"

	local page  = node("fon_admin", "fon_net", "net")
	if mode == "bridge" or mode == "wifi-bridge" then
		page.target = template("fon_net/bridge")
	else
		page.target = cbi("fon_net/net")
	end
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

	local page = entry({"bugme"})
	local page = entry({"bugme", "end"}, call("bugme_end"))

	local page  = node("fon_admin", "fon_status")
	page.target = call("action_status")
	page.title  = luci.i18n.translate("fon_status", "Fonera Status")
	page.order  = 130
	page.icon   = "icons/fonera_on.png"
	page.page_icon   = "icons/fonera_on.png"

	local page  = node("fon_admin", "fonspot")
	page.target = cbi("fon_wifi/spot", {on_success_to={"fon_admin"}})
	page.title  = luci.i18n.translate("fon_fonspot", "Fonspot")
	page.order  = 24
	page.icon   = "icons/fonspot.png"
	page.page_icon   = "icons/fonspot.png"
end

function action_status()
	luci.http.redirect(luci.dispatcher.build_url("fon_status"))
end

function bugme_end()
	local done = luci.http.formvalue("done")
	if done and #done > 1 then
		local uci = require("luci.model.uci").cursor()
		uci:set("bugme", done, "done", "1")
		uci:commit("bugme")
	end
	luci.http.prepare_content("text/html")
	luci.template.render("fon/bugme_end")
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
	-- Call a script to create a configuration backup
	os.execute("/sbin/save-config.sh")
	local f = luci.fs.readfile("/tmp/sysupgrade.tgz")
	-- Prepend a very crude marker, so we can recognize a settings
	-- backup when restoring below.
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
			local uci = require("luci.model.uci").cursor()
			local allow_unsigned = false
			local dev = uci:get("registered", "fonreg", "dev")
			if dev == "1" then
				allow_unsigned = true
			end
			if str ~= "reflash" and str ~= "unsigned" then
				ret = luci.i18n.translate("failed_identify", "Failed to identify upload.")
			else
				local dir, str = verify.fonverify(tmpfile, "/etc/fon/keyring/", allow_unsigned)
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
			-- Put the settings file into /sysupgrade.tgz.
			-- The file will be unpacked by /etc/preinit
			-- after the reboot.
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

function wifi_scan(connect_links)
	local http = require "luci.http"
	local device = require("luci.fon.spot").get_device()
	local have_mode

	if (device == "fonera20n") then
		results = wifi_scan_ralink()
		have_mode = true
	else
		results = wifi_scan_atheros()
		-- iwlist scan does not indicate mode (b/g/n)
		have_mode = false
	end
	sort_key = http.formvalue('sort_key')
	table.sort(results, function (a,b) return a[sort_key] < b[sort_key] end)
	luci.http.prepare_content("text/html")
	luci.template.render("fon_inet/wifi_scan_results", {results=results, have_mode=have_mode, connect_links=connect_links})
end

function wifi_scan_ralink()
	local results = {}

	local f = io.popen('/sbin/ap_client', 'r')
	local line = f:read()
	while line do
		local channel, essid, bssid, auth, enc, strength, mode, rssi =
			string.match(line, " (.-)  (.-)  (.-)  (.-)  (.-)  (.-)  (.-)  (.*)")

		local auth_display = nil
		if auth == "WPAPSK" then
			auth = "WPA"
		elseif auth == "WPA2PSK" then
			auth = "WPA2"
		elseif auth == "WPAPSKWPA2PSK" then
			auth = "WPA2"
			auth_display = "WPA/WPA2"
		elseif auth == "NONE" then
			auth = "OPEN"
		end

		-- ap_client uses - as separators in the bssid.
		bssid = bssid:gsub("-", ":")

		table.insert(results, {
			essid = essid,
			channel = tonumber(channel),
			bssid = bssid,
			auth_use = auth:lower(),
			auth_display = auth_display or auth,
			enc = enc,
			strength = tonumber(strength),
			mode = mode,
			rssi = tonumber(rssi)
		})

		line = f:read()
	end
	f:close()

	return results
end

function wifi_scan_atheros()
	local results = {}
	local mode = require("luci.model.uci").cursor():get("fon", "wan", "mode")
	-- If not in wifi(-bridge) mode, only bring up the ath2 device
	-- for a short time, since bringing it up suspends all AP
	-- signals.
	--
	if mode ~= "wifi" and mode ~= "wifi-bridge" then
		-- Set the hostroaming option to manual, to keep the
		-- client device from automatically associating during
		-- the brief time it is up.
		os.execute("iwpriv hostroaming 2");
		os.execute("ifconfig ath2 up");
		-- Trigger a scan, and wait a bit for results to come
		-- in. Without this, the below iwlist scan would trigger
		-- a scan and return only the probes coming in directly
		-- (usually only channel 1).
		os.execute("iwlist ath2 scan");
		-- Wait a bit. The maximum time on each channel should
		-- be 200ms, so with 13 channels, 3 seconds of sleep
		-- should be sufficient.
		os.execute("sleep 3");
	end

	local f = io.popen('iwlist ath2 scan', 'r')
	local line = f:read()
	local result = nil
	while line do
		local channel, essid, bssid, strength, mode, rssi
		bssid = string.match(line, "^%s*Cell %d+ %- Address: ([0-9A-F:]*)$")
		if bssid then
			result = {bssid = bssid}
			table.insert(results, result)
		end

		-- Note that iwlist might print the WEP key index (I
		-- think) after the ESSID, so the pattern is not
		-- terminated with $.
		essid = string.match(line, "^%s*ESSID:\"(.*)\"")
		if essid then
			result.essid = essid
		end

		channel = string.match(line, "^%s*Frequency:.* %(Channel (%d*)%)$")
		if channel then
			result.channel = tonumber(channel)
		end

		strength, rssi = string.match(line, "^%s*Quality=(%d+)/%d+  Signal level=([-%d]*) dBm .*$")
		if (strength and rssi) then
			result.strength = tonumber(strength)
			result.rssi = tonumber(rssi)
		end

		if (string.match(line, "^%s*Encryption key:off$")) then
			result.auth_use = "open"
			result.auth_display = "OPEN"
		elseif (string.match(line, "^%s*Encryption key:on$")) then
			-- Note that this might be overriden when we
			-- match a WPA and/or WPA2 IE later on.
			result.auth_use = "wep"
			result.auth_display = "WEP"
		elseif (string.match(line, "^%s*IE: WPA Version 1$")) then
			if result.auth_use == "wpa2" then
				result.auth_display = "WPA/WPA2"
			else
				result.auth_use = "wpa"
				result.auth_display = "WPA"
			end
		elseif (string.match(line, "^%s*IE: IEEE 802.11i/WPA2 Version 1$")) then
			if result.auth_use == "wpa" then
				result.auth_display = "WPA/WPA2"
			else
				result.auth_display = "WPA2"
			end
			result.auth_use = "wpa2"
		end

		line = f:read()
	end
	f:close()

	if mode ~= "wifi" and mode ~= "wifi-bridge" then
		os.execute("ifconfig ath2 down");
		os.execute("iwpriv hostroaming 1");
	end

	return results
end
