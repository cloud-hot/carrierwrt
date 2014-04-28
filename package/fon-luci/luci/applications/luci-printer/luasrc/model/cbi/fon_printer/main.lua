require("luci.tools.webadmin")

m = Map("p910nd",
	translate("printer_title", "Printer Settings"),
	translate("printer_desc", "Most USB printers will work with the La Fonera.")
	.. "<br/><br/><a href=\"https://fon.zendesk.com/entries/21936838-printer-server-configuration\">"
	.. "&gt;&gt; " .. translate("more_info", "More information") .. "</a>"
)
m.pageaction = false

local state = luci.model.uci.cursor_state()
state:load("p910nd")
local attached = state:get("p910nd", "lp0", "attached") or "0"
local mfg = state:get("p910nd", "lp0", "mfg") or "0"
local mdl = state:get("p910nd", "lp0", "mdl") or "0"
if attached == "1" and mfg and mdl then
	x = Template("fon_printer/list")
	x.mfg = mfg
	x.mdl = mdl
	m:append(x)
else
	m:append(Template("fon_printer/none"))
end
return m
