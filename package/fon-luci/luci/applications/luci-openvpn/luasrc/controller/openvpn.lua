module("luci.controller.openvpn", package.seeall)

function index(env)
	require("luci.i18n")
	local uci = require("luci.model.uci").cursor()
	if uci:get("registered", "fonreg", "dev") ~= "1" then
		return
	end
	local i18n = luci.i18n.translate
    luci.i18n.loadc("openvpn")

	local page  = node("fon_admin", "openvpn")
	page.title  = luci.i18n.translate("openvpn_title", "OpenVPN")
	page.order  = 201
	page.icon_path	= "/luci-static/resources/icons/plugins"
	page.page_icon	= "openvpn.png"
	page.icon	= "openvpn.png"
	page.i18n = "openvpn"
	page.target = cbi("openvpn")

	local page  = node("fon_admin", "openvpn", "ovpn_config.zip")
	page.target = call("openvpn_config")

	local page  = node("fon_admin", "openvpn", "new")
	page.title  = luci.i18n.translate("openvpn_new_title", "Add new Client")
	page.icon_path  = "/luci-static/resources/icons/plugins"
    page.page_icon  = "openvpn.png"
	page.target = cbi("openvpn/new", {on_success_to={"fon_admin", "openvpn"}})

	local page  = node("fon_admin", "openvpn", "firewall")
	page.title  = luci.i18n.translate("settings", "Settings")
	page.icon_path  = "/luci-static/resources/icons/plugins"
    page.page_icon  = "openvpn.png"
	page.target = cbi("openvpn/firewall", {on_success_to={"fon_admin", "openvpn"}})

	local page  = node("fon_admin", "openvpn", "cert")
	page.title  = luci.i18n.translate("openvpn_cert", "Manage Certificates")
	page.icon_path  = "/luci-static/resources/icons/plugins"
    page.page_icon  = "openvpn.png"
	page.target = template("openvpn_cert", {on_success_to={"fon_admin", "openvpn"}})

	local page  = node("fon_admin", "openvpn", "LaFonera_OpenVPN.bin")
	page.target = call("action_backup")
end

function action_backup()
	local http = require "luci.http"
	http.prepare_content("application/octet-stream")
	os.execute("tar cvzf /tmp/sysupgrade.tgz /etc/config/openvpn /etc/openvpn/keys/")
	local f = luci.fs.readfile("/tmp/sysupgrade.tgz")
	http.write("UI"..f)
end

function openvpn_config()
	local http = require "luci.http"
	local client = http.formvalue("client")
	if not require("luci.model.uci").cursor():get("openvpn", client, "name") then
		os.execute("logger potential injection attempt?!")
		return
	end
	http.prepare_content("application/zip")
	os.execute("/usr/bin/openvpn-client.sh "..client)
	os.execute("logger ".. "/tmp/"..client.."_ovpn.zip")
	local f = luci.fs.readfile("/tmp/"..client.."_ovpn.zip")
	http.write(f)
end
