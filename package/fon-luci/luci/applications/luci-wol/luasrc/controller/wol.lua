module("luci.controller.wol", package.seeall)

function index()
	require("luci.i18n")
	local i18n = luci.i18n.translate
	luci.i18n.loadc("wol")

	local page  = node("fon_devices", "wol")
	page.title = luci.i18n.translate("wol_title", "Wake-on-LAN")
	page.order = 190
	page.icon_path = "/luci-static/resources/icons/plugins"
	page.icon = "wol.png"
	page.page_icon = "wol.png"
	page.i18n = "wol"
	page.target = cbi("wol")
end
