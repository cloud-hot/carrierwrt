module("luci.controller.fon_admin.fon_debug", package.seeall)

function index(env)
        require("luci.i18n")

	local page  = node("fon_devices", "fon_debug")
	page.target = cbi("fon_debug/main", {on_success_to={"fon_dashboard"}})
	page.title  = luci.i18n.translate("debug_info", "Debug info")
	page.order  = 210
	page.page_icon = "/icons/debug.png"
	page.icon = page.page_icon
end
