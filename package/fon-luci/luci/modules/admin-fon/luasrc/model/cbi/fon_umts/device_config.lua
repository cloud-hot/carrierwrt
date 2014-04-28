require("luci.tools.webadmin")
require("luci.json")

modes = {"auto", "force_gprs", "force_umts", "prefer_gprs", "prefer_umts"}


-- Run udiald and parse its JSON output (or return the raw output when
-- raw = true)
function get_udiald_output(args, raw)
	-- Run udiald
	local handle = io.popen("udiald " .. args, "r")

	if raw then
		res = handle:read("*all")
		handle:close()
	else
		-- Decode output as json
		local decoder = luci.json.Decoder()
		luci.ltn12.pump.all(luci.ltn12.source.file(handle), decoder:sink())

		res = decoder:get()
	end
	return res
end

local http = require("luci.http")
local device_id = arg[1]

if not device_id then
	luci.http.redirect(luci.dispatcher.build_url("fon_devices", "fon_umts", "configure"))
	return
end


-- Get some data from udiald
local devices = get_udiald_output("-q --list-devices --device-id " .. device_id)
local device = devices[device_id]
local profiles = get_udiald_output("-q --list-profiles")

local m = Map("network",
	translate("umts_device_config_title", "Device settings for " .. device.vendor:sub(3) .. ":" .. device.product:sub(3)),
	translate("umts_device_config_desc",
	"These settings are used to communicate with this device and all \
	others of the same make and model. If your device is supported, \
	it should not normally be necessary to change these settings."))

-- Create a new section with the custom profile (for when it doesn't
-- exist yet).
section_name = "custom" .. device.vendor:sub(3) .. device.product:sub(3)
s = m:section(NamedSection, section_name, "udiald_profile")
if not m:get(section_name, nil) then
	m:set(section_name, nil, s.sectiontype)
	m:set(section_name, 'desc', 'Custom configuration')
	m:set(section_name, 'vendor', device.vendor)
	m:set(section_name, 'product', device.product)

	-- Preload data from current profile
	if (device.profile) then
		m:set(section_name, 'control', device.profile.control)
		m:set(section_name, 'data', device.profile.data)
		m:set(section_name, 'dialcmd', device.profile.dialcmd)
		if not m:get(section_name, 'base') then
			m:set(section_name, 'base', device.profile.name)
		end
		for _, mode in ipairs(modes) do
			cmd = device.profile.modes[mode]
			if cmd and #cmd ~= 0 then
				m:set(section_name, 'mode_' .. mode, device.profile.modes[mode])
			end
		end
	end
end

-- Only save when submitting, not when displaying (possibly a bug in
-- cbi).
m.save = m:submitstate()

-- Workaround a problem that on_success_to isn't fired when create() is
-- called
m.proceed = false


-- Show a dropdown that allows users to use an existing profile as a
-- basis for custom settings.
base = s:option(ListValue, "base", "Based on")
sorted_profiles = luci.util.spairs(profiles, function(a, b) return profiles[a].description < profiles[b].description end)

for i, p in sorted_profiles do
	if (p.internal) then
		base:value(p.name, p.description)
	end
end

-- Add some javascript to load profile data from the list when a profile is
-- selected in the dropdown.
local t = Template("fon_umtsd/profile_list")
t.profiles_json = get_udiald_output("-q --list-profiles", true)
t.device = device
-- Allow the template to look up the HTML id of specific fields in this
-- section
t.field_id = function(name) return s.fields[name]:cbid(s.section) end
t.modes = modes
s:append(t)

-- The config actual fields

control = s:option(ListValue, "control", "Control port")
for i = 0, device.ttys - 1 do
	control:value(i)
end

data = s:option(ListValue, "data", "Data port")
for i = 0, device.ttys - 1 do
	data:value(i)
end

dialcmd = s:option(Value, "dialcmd", "Dial command")
dialcmd:value("ATD*99***1#")
dialcmd:value("ATD#777")
dialcmd:value("AT+GCDATA=\"PPP\",1")

for _, mode in ipairs(modes) do
	s:option(Value, "mode_" .. mode, mode:gsub("_", " ") .. " command")
end

return m
