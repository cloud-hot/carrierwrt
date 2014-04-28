module("luci.controller.ushare", package.seeall)

function index()
	require("luci.i18n")
	luci.i18n.loadc("ushare")
	local page = entry({"fon_admin", "ushare"}, cbi("ushare", {on_success_to={"fon_admin"}}), luci.i18n.translate("ushare", "Mediaserver"), 260)
	page.dependent = true
	page.page_icon = "icons/firewall.png"
	page.order = 295
	page.icon = "icons/firewall.png"
end
