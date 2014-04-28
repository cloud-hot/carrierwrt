-- Copyright 2012 Matthijs Kooijman <matthijs@stdin.nl>

require("luci.tools.webadmin")

function do_power_on(mac)
	os.execute("logger -- Sending WOL packet to %q" % {mac})
	os.execute("etherwake -i br-lan %q 2>&1 | logger -t etherwake" % {mac})
end

local uci = require("luci.model.uci").cursor()
local m = Map("luci_wol",
	translate("wol_title", "Wake-on-LAN"),
	translate("wol_desc", "On this page you can send \"magic packets\" (also known as \"Wake-on-LAN\" packets) to devices connected to your Fonera's LAN port. If these devices are properly configured to support Wake-on-LAN, they will power in in response to this magic packet.") ..
	"<br/><br/>" .. translate("wol_howto", "Add the address of a device below and press the resulting \Power on\" button to send a magic packet."))

-- A table of registered hosts
s = m:section(TypedSection, "mac", "", "")
s.anonymous = true
s.addremove = true
s.template = "cbi/tblsection"

name = s:option(Value, "name", translate("name", "Name"))
mac = s:option(Value, "mac", translate("mac", "MAC"))

-- Power on button
power_on = s:option(Button, "power_on", translate("wol_power_on", "Power on"))

-- Called when the button is pressed
function power_on.write(self, section)
	do_power_on(self.map:get(section, 'mac'))
end

local n = Map("luci_ethers",
	"",
	translate("wol_dhcp_desc", "These addresses were configured in the network settings page."))

-- A table of registered hosts
s = n:section(TypedSection, "static_lease", "Hosts", "")
s.anonymous = true
s.template = "cbi/tblsection"

name = s:option(DummyValue, "hostname", translate("name", "Name"))
mac = s:option(DummyValue, "macaddr", translate("mac", "MAC"))

-- Power on button
power_on = s:option(Button, "power_on", translate("wol_power_on", "Power on"))

-- Called when the button is pressed
function power_on.write(self, section)
	do_power_on(self.map:get(section, 'macaddr'))
end

return m, n
