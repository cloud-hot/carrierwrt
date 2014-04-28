module("luci.controller.fon_admin.fon_printer", package.seeall)

function index(env)
    require("luci.i18n")

	local page  = node("fon_devices", "fon_printer")
	page.target = cbi("fon_printer/main", {on_success_to={"fon_dashboard"}})
	page.title  = luci.i18n.translate("printer", "Printer")
	page.order  = 110
	page.page_icon = "/icons/printer_on.png"
	page.fon_status = function()
		local ico = luci.config.main.mediaurlbase.."/icons/printer_%s.png"
		local cfg = {"p910nd", "lp0" , "attached"}
		local uci = require "luci.model.uci".cursor_state()
		local val = uci:get(unpack(cfg))

		local icon = ico % ((not val or val == "0") and "off" or "on")

		return {icon=icon}
	end

	page.fon_reload = function()
		local cfg = {"p910nd", "lp0" , "attached"}
		local uci = require "luci.model.uci".cursor_state()
		local val = uci:get(unpack(cfg))
		local reload = ((not val or val == "0") and "0" or "1")
		return {reload=reload}
	end

	page.icon_select = function()
		local u = luci.model.uci.cursor_state()
		local c = u:get("p910nd", "lp0", "attached")
		if c and c > "0" then
			return "icons/printer_on.png"
		else
			return "icons/printer_off.png"
		end
	end
end
