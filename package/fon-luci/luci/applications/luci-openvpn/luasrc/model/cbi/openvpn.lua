-- Copyright 2009 John Crispin <john@phrozen.org>

require("luci.tools.webadmin")

local uci = require("luci.model.uci").cursor()
local m = Map("openvpn",
	translate("openvpn_title", "OpenVPN"),
	translate("openvpn_desc", "Here you can configure your vpn server. VPN allows you to remotely connect to your home network from anywhere in the world.")
	.. "<br/><br/><a href=\"https://fon.zendesk.com/entries/21925706-openvpn-configuration-and-safe-surf-feature\">"
	.. "&gt;&gt; " .. translate("more_info", "More information") .. "</a>")
m:append(Template("openvpn_status"))
s = m:section(NamedSection, "openvpn", "openvpn")

if require("luci.model.uci").cursor_state():get("openvpn", "openvpn", "key") == "1" then
	m.pageaction = false
	return m
end
local key = require("luci.fs").stat("/etc/openvpn/keys/dh1024.pem")
if (key == nil and uci:get("openvpn", "openvpn", "enable") == "1") then
	m.pageaction = false
	return m
end
m.events = {"RestartOpenVpn"}
local x = s:option(ListValue, "enable", translate("server", "Server"))
x:value("0", translate("disable"))
x:value("1", translate("enable"))
x.default = uci:get("openvpn", "openvpn", "enable")

if uci:get("openvpn", "openvpn", "enable") == "0" or key == nil then
	return m
end

local n = Map("openvpn",
	translate("openvpn_client_title", "Clients"),
        translate("openvpn_client_desc", "Here you can manage your clients"))
s = n:section(TypedSection, "client", "", "")
s.anonymous = true
s.template = "cbi/tblsection"

-- Make a list of connected clients and their IP addresses
local clients = {}
local f = io.open("/tmp/openvpn.clients", "r")
if f then
	for line in f:lines() do
		local first, last, name, ip = line:find("^CLIENT_LIST,([^,]*),[^,]*,([^,]*),.*")
		if first then
			clients[name] = ip
		end
	end
end

name = s:option(DummyValue, "name", translate("name", "Name"))
-- Show the online/offline status and currently assigned IP
status = s:option(DummyValue, "status", translate("fon_status", "Status"))
function status.value(self, section)
	local ip = clients[section]
	if ip then
		return "Online - " .. ip
	else
		return "Offline"
	end
end
-- Allow selecting a static IP. We offer the second half of the /24 for
-- static assignment, keeping the first half for dynamic assignment.
ip = s:option(ListValue, "ip", "IP")
ip:value("", "Automatic")
for i = 128, 253  do
	ip:value("10.8.0." .. tostring(i))
end

function s.parse(self, novld)
	-- Make sure each address is only used only once. We could have
	-- created an ip.validate function, but when that returns nil to
	-- indicate an invalid value, the old value is shown again,
	-- making the feedback to the user confusing. By directly
	-- setting ip.error, we get the "invalid" feedback, without
	-- throwing away the formvalue.
	local in_use = {}
	ip.error = ip.error or {}
	for i, section in ipairs(self:cfgsections()) do
		ip_val = ip:formvalue(section)
		if ip_val and #ip_val > 0 then
			other_section = in_use[ip_val]
			-- If this address is in use by another section,
			-- mark both as invalid
			if other_section then
				ip.error[section] = "duplicate"
				ip.error[other_section] = "duplicate"
				ip.map.save = false
			end
			in_use[ip_val] = section
		end
	end

	-- Let TypedSection.parse do the regular handling
	TypedSection.parse(self, novld)
end

download = s:option(Button, "configuration", translate("config", "Configuration"))
-- Use a custom template so we can use different texts on the button and
-- the column header and hide the button when the keys have not been
-- generated yet.
download.button_title = translate("download", "Download")
download.template = "openvpn_download"
-- Handle the button by redirecting to the config download url.
function download.write(self, section)
	local url = require("luci.dispatcher").build_url("fon_admin", "openvpn", "ovpn_config.zip") .. "?client=" .. section
	require("luci.http").redirect(url)
end

remove = s:option(Button, "remove", translate("client", "Client"))
-- Use a custom template so we can use different texts on the button and
-- the column header and add an are you sure? prompt.
remove.button_title = translate("remove", "Remove")
remove.template = "openvpn_remove"
function remove.write(self, section)
	-- Check that the section exists
	if not uci:get("openvpn", section, "name") then
		os.execute("logger potential injection attempt")
		return
	end
	-- Revoke the certificate, so the client really can't login
	-- anymore (and we can regenerate a client with the same name
	-- later on).
	os.execute("/usr/sbin/revoke-full "..section)
        uci:delete("openvpn", section)
	uci:commit("openvpn")
	os.execute("rm -rf /etc/openvpn/keys/"..section..".*")
end

-- Show some extra buttons
n:append(Template("openvpn_buttons"))


return m, n
