require("luci.tools.webadmin")

local uci = require("luci.model.uci").cursor()
local mode = uci:get("fon", "wan", "mode")

m = Map("fon",
	"",
	translate("inet_desc", "Here you can configure the way your Fonera connects to the Internet. Currently there are 4 protocols available: DHCP, static IP configuration, PPPoE and PPTP. For most people DHCP should work; though, if it doesn't for you, check with your Internet provider (ISP) what protocol you must use or look at the installation reference manual or the troubleshooting manual from FON."))

m.cancelaction = true

s = m:section(NamedSection, "wan", "wan")

return Template("wizard_fonera2/head"), Template("themes/fon/head_darkorange"), m
