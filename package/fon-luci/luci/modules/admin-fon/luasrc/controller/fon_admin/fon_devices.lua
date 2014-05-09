module("luci.controller.fon_admin.fon_devices", package.seeall)

function index()
	require("luci.i18n")

	local page  = node("fon_devices")
	page.title  = luci.i18n.translate("connected_devices", "Connected Devices")
	page.order  = 40
	page.index  = true
	page.icon   = "icons/sys.png"
	page.sysauth = "root"
	page.sysauth_authenticator = "htmlauth"
	page.index = true

	local page  = node("fon_devices", "fon_umts")
	page.target = cbi("fon_umts/main")
	page.sysauth = "root"
	page.order = 50
	page.sysauth_authenticator = "htmlauth"
	page.title  = luci.i18n.translate("umts_3g", "UMTS/3G")
	page.page_icon   = "icons/umts_on.png"
	page.fon_status = function()
		return {icon=(luci.config.main.mediaurlbase .. "/" .. page.icon_select())}
	end
	page.icon_select = function()
		local ico = "icons/umts_%s.png"
		local uci = require "luci.model.uci".cursor_state()
		local mode = uci:get("fon", "wan", "mode")
		if mode ~= "umts" then
			icon = ico % "off"
		else
			local state = uci:get("network", "wan", "udiald_state")
			if state == "error" then
				icon = ico % "warn"
			else
				icon = ico % "on"
			end
		end
		return icon
	end

	page.fon_reload = function()
		local uci = require "luci.model.uci".cursor_state()
		local state = uci:get("network", "wan", "udiald_state")
		local up = uci:get("network", "wan", "up")
		return {reload=((state or "") .. (up or ""))}
	end

	local page  = node("fon_devices", "fon_umts", "configure")
	page.target = cbi("fon_umts/configure", {on_success_to = {"fon_devices", "fon_umts"}})
	page.title  = luci.i18n.translate("credentials", "Configure")
	page.page_icon   = "icons/umts_on.png"

	local page  = node("fon_devices", "fon_umts", "device_config")
	page.target = cbi("fon_umts/device_config", {on_success_to = {"fon_devices", "fon_umts"}})
	page.title  = luci.i18n.translate("credentials", "Configure")
	page.page_icon   = "icons/umts_on.png"
	-- Indicates that any path components after device_config are
	-- arguments. TODO: This causes a broken link in the breadcrumbs
	-- (/fon_devices/fon_umts/device_config).
	page.leaf = true

	local page  = node("fon_devices", "fon_umts", "probe")
	page.target = call("umts_probe", false)

	local page  = node("fon_devices", "fon_admin")
	page.target = call("action_admin")
	page.title  = luci.i18n.translate("settings", "Settings")
	page.icon = "icons/settings.png"
	page.order = 29
end

function action_admin()
	local http = require "luci.http"
	local dsp = require "luci.dispatcher"
	http.redirect(dsp.build_url("fon_admin"))
end

function umts_probe()
	local device_id = luci.http.formvalue('device_id')
	local uci = require "luci.model.uci".cursor()
	local pin = uci:get("fon", "advanced", "umts_pin")
	local probe_output = luci.util.exec("udiald --probe --pin " .. pin .. " --device-id " ..  device_id .. " 2>&1")
	luci.http.prepare_content("text/html")
	luci.template.render("fon_umtsd/probe", {probe_output=probe_output})
end
