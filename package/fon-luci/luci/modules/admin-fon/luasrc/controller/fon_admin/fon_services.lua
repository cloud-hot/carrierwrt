module("luci.controller.fon_admin.fon_services", package.seeall)

function index()
	require("luci.i18n")

	local page  = node("fon_services")
	page.title  = luci.i18n.translate("services", "Services")
	page.order  = 40
	page.index  = true
	page.icon   = "icons/services.png"
	page.sysauth = "root"
	page.sysauth_authenticator = "htmlauth"
	page.ucidata = true
	page.index = true
end
