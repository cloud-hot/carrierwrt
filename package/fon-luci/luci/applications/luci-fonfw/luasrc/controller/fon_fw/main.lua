module("luci.controller.fon_fw.main", package.seeall)

function index()
	require("luci.i18n")
	luci.i18n.loadc("firewall")

	local page = node("fon_admin", "fon_fw")
	page.target = template("fon_fw/main")
	page.i18n = "firewall"
	page.title = luci.i18n.translate("firewall", "Firewall")
	page.order = 21
	page.dependent = true
	page.page_icon = "icons/firewall.png"
	page.icon = "icons/firewall.png"
	page.subindex = 1
	page.noinline = 1

	local page = node("fon_admin", "fon_fw", "portfwd")
	page.target = cbi("fon_fw/portfwd", {on_success_to={"fon_admin", "fon_fw"}})
	page.title = luci.i18n.translate("firewall_portfwd", "Port Forwarding")
	page.page_icon = "icons/forwarding.png"
	page.order = 10
	page.icon = "icons/forwarding.png"

	local page = node("fon_admin", "fon_fw", "policy")
	page.target = cbi("fon_fw/policy", {on_success_to={"fon_admin", "fon_fw"}})
	page.title = luci.i18n.translate("firewall_policy", "Policy")
	page.page_icon = "icons/policy.png"
	page.order = 20
	page.icon = "icons/policy.png"

	local page = node("fon_admin", "fon_fw", "upnp")
	page.target = cbi("fon_fw/upnp", {on_success_to={"fon_admin", "fon_fw"}})
	page.title = luci.i18n.translate("firewall_upnp", "UPnP")
	page.order = 25
	page.icon = "icons/upnp.png"
	page.page_icon = "icons/upnp.png"

	local page = node("fon_admin", "fon_fw", "services")
	page.target = cbi("fon_fw/services", {on_success_to={"fon_admin", "fon_fw"}})
	page.title = luci.i18n.translate("firewall_apps", "Applications")
	page.order = 15
	page.icon = "icons/fw_serv.png"
	page.page_icon = "icons/fw_serv.png"
end
