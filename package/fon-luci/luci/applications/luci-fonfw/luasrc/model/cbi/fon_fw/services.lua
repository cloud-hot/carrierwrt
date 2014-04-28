-- (c) john@phrozen.org gplv2

require("luci.sys")
m = SimpleForm("firewall",
	translate("firewall_apps", "Applications"),
	translate("fwall_serv", "Here you can configure, which applications should be reachable over the internet"))

local uci = require("luci.model.uci").cursor()
uci:load("services")
local dev = uci:get("registered", "fonreg", "dev") or "0"
uci:foreach("services", "service", function(s)
	if s.fwall ~= nil and s.name ~= nil then
		if not(s[".name"] == "ssh" and dev == "0") then
			local x = m:field(ListValue, s[".name"], s.name)
			x:value("0", translate("disable", "Disable"))
			x:value("1", translate("enable", "Enable"))
			x.default = s.fwall
		end
	end
end)

uci:foreach("fmg", "images", function(s)
	if s.fwall ~= nil and s.name ~= nil then
		if not(s[".name"] == "ssh" and dev == "0") then
			local x = m:field(ListValue, s[".name"], s.name)
			x:value("0", translate("disable", "Disable"))
			x:value("1", translate("enable", "Enable"))
			x.default = s.fwall
		end
	end
end)

function m.handle(self, state, data)
	if state == FORM_VALID then
		local count = 0
		local uci = require("luci.model.uci").cursor()
		uci:load("services")
		uci:foreach("services", "service", function(s)
			if data[s[".name"]] then
				local uci2 = require("luci.model.uci").cursor()
				uci2:set("services", s[".name"], "fwall", data[s[".name"]])
				uci2:commit("services")
				count = count + 1
			end
		end)
		uci:load("fmg")
		uci:foreach("fmg", "images", function(s)
			if data[s[".name"]] then
				local uci2 = require("luci.model.uci").cursor()
				uci2:set("fmg", s[".name"], "fwall", data[s[".name"]])
				uci2:commit("fmg")
				count = count + 1
			end
		end)
		if count > 0 then
			local event = require("luci.fon.event")
			event.new("FWallDaemon")
		end
	end
	return true
end
return m
