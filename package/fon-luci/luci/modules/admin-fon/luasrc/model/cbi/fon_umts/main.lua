require("luci.tools.webadmin")
require("luci.json")

local util = require "luci.util"
local pdb = loadfile((os.getenv("LUCI_SYSROOT") or "") .. "/etc/3gsp.db.lua")()
local c3166 = loadfile((os.getenv("LUCI_SYSROOT") or "") .. "/etc/3166en.db.lua")()
local uci1 = luci.model.uci.cursor()
local uci = luci.model.uci.cursor()
local uci_state = luci.model.uci.cursor_state()
local event = require "luci.sys.event"

function get_udiald_output(args)
	-- Run udiald
	local handle = io.popen("udiald " .. args, "r")

	-- Decode output as json
	local decoder = luci.json.Decoder()
	luci.ltn12.pump.all(luci.ltn12.source.file(handle), decoder:sink())

	return decoder:get()
end

local m = Map("fon",
	translate("umts_title", "UMTS Settings"))
m.events = {"UMTS"}

local devices = get_udiald_output("-q --list-devices")
local mode = uci:get("fon", "wan", "mode")
local selected_device = nil
if mode == "umts" then
	selected_device = uci:get("fon", "wan", "umts_device")
end

function m.commit_handler(self, form)
	-- Is the disconnect button pressed?
	if selected_device and self:formvalue("disconnect_" .. selected_device) then
		local old_mode = uci:get("fon", "wan", "old_mode") or "dhcp"
		uci:set("fon", "wan", "mode", old_mode)
		uci:delete("fon", "wan", "umts_device")
		uci:delete("fon", "wan", "old_mode")
		uci:commit("fon")
		uci_state:revert("network", "wan", "udiald_state")
		uci_state:save("network")
		event.fire("UMTS")
	end

	-- Is the reconnect button pressed?
	if selected_device and self:formvalue("reconnect_" .. selected_device) then
		uci_state:revert("network", "wan", "udiald_state")
		uci_state:save("network")
		event.fire("UMTS")
	end

	-- Is a connect button pressed?
	for _, device in pairs(devices) do
		if self:formvalue("connect_" .. device.id) then
			uci:set("fon", "wan", "old_mode", mode)
			uci:set("fon", "wan", "mode", "umts")
			uci:set("fon", "wan", "umts_device", device.id)
			uci:commit("fon")
			uci_state:revert("network", "wan", "udiald_state")
			uci_state:save("network")
			event.fire("UMTS")
		end
	end
end

if next(devices) == nil then
	m.pageaction = false
	m:append(Template("fon_umtsd/none"))
else
	local t = Template("fon_umtsd/device_list")
	t.devices = devices
	m:append(t)
end

m:append(Template("fon_umtsd/menu"))
m:append(Template("fon/page_reload"))

return m
