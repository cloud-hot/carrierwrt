module("luci.controller.ddns", package.seeall)

function index()
	require("luci.i18n")
	luci.i18n.loadc("ddns")

	local page = entry({"fon_admin", "fon_ddns"}, cbi("ddns", {on_success_to = {"fon_dashboard"}}), luci.i18n.translate("ddns", "DDNS"), 22)
	page.i18n = "ddns"
	page.icon_path = "/luci-static/resources/icons"
	page.icon = "ddns.png"
	page.page_icon = "ddns.png"
end
