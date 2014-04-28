-- Copyright 2009 John Crispin <john@phrozen.org>

require("luci.tools.webadmin")

local m = Map("openvpn",
	translate("openvpn_security", "Security settings"),
	translate("openvpn_security_desc", "Clients connected to the VPN are able to access the Fonera WebUI. In addition you can grant them to access your local network, other VPN clients or the internet through their VPN connection.")
	.. " " .. translate("openvpn_safe_surf_desc", "Enabling \"Safe surf\" causes all internet traffic for VPN clients to be securely routed through your Fonera.")
	.. "<br/><br/><a href=\"https://fon.zendesk.com/entries/21925706-openvpn-configuration-and-safe-surf-feature\">"
	.. "&gt;&gt; " .. translate("more_info", "More information") .. "</a>"
)
m.events = {"ReconfOpenVPN"}

s = m:section(NamedSection, "openvpn", "openvpn")

local x = s:option(ListValue, "lan", translate("openvpn_lan", "Access to local network"))
x:value("0", translate("disable"))
x:value("1", translate("enable"))
x.default = require("luci.model.uci").cursor():get("openvpn", "openvpn", "lan") or "0"

local x = s:option(ListValue, "wan", translate("openvpn_safesurf", "Access to the internet (Safe Surf)"))
x:value("0", translate("disable"))
x:value("1", translate("enable"))
x.default = require("luci.model.uci").cursor():get("openvpn", "openvpn", "wan") or "0"

local x = s:option(ListValue, "client_to_client", translate("openvpn_ctc", "Access to other clients"))
x:value("0", translate("disable"))
x:value("1", translate("enable"))
x.default = require("luci.model.uci").cursor():get("openvpn", "openvpn", "client_to_client") or "0"

local n = Map("openvpn",
	translate("openvpn_connection", "Connection settings"),
	translate("openvpn_connection_desc", "These settings determine how clients connect to the OpenVPN server. If you change any of these settings, you should re-download any client configurations previously downloaded, otherwise those clients will not be able to connect!"))
n.events = {"ReconfOpenVPN"}

s = n:section(NamedSection, "openvpn", "openvpn")

local dns = require("luci.model.uci").cursor():get("ddns", "ddns_scripts", "domain")
if not(dns) or #dns < 1 then
	s:option(Value, "public", translate("public_ip", "Public IP/hostname"))
else
	public = s:option(DummyValue, "public", translate("public_ip", "Public IP/hostname"))
	public.value = "Using DDNS value: " .. dns
end

local x = s:option(ListValue, "proto", translate("openvpn_proto", "Protocol"))
x:value("udp", "UDP")
x:value("tcp-server", "TCP")
x.default = require("luci.model.uci").cursor():get("openvpn", "openvpn", "proto") or "udp"

local x = s:option(Value, "port", translate("openvpn_port", "TCP or UDP port"))
x.default = require("luci.model.uci").cursor():get("openvpn", "openvpn", "port") or "1194"

local x = s:option(ListValue, "tls_auth", translate("openvpn_tls_auth", "TLS handshake hardening (tls-auth)"))
x:value("", translate("disable", "Disabled"))
x:value("/etc/openvpn/keys/ta.key 0", translate("enable", "Enabled"))
x.default = require("luci.model.uci").cursor():get("openvpn", "openvpn", "tls_auth")

local o = Map("openvpn",
	translate("openvpn_other", "Other settings"), "")
o.events = {"ReconfOpenVPN"}

s = o:section(NamedSection, "openvpn", "openvpn")
local x = s:option(ListValue, "keepalive", translate("openvpn_keepalive", "Send periodic keepalives"))
x:value("0 0", translate("openvpn_keepalive_never", "Never"))
x:value("10 120", translate("openvpn_keepalive_normal", "Normal (every 10 seconds)"))
x:value("60 300", translate("openvpn_keepalive_reduced", "Reduced (every 60 seconds)"))
x:value("600 1200", translate("openvpn_keepalive_seldom", "Seldom (every 10 minutes)"))
x.default = require("luci.model.uci").cursor():get("openvpn", "openvpn", "keepalive") or "10 120"

local x = s:option(ListValue, "max_clients", translate("openvpn_max_clients", "Concurrent Connections"))
x:value(1, 1)
x:value(2, 2)
x:value(4, 4)
x:value(8, 8)
x:value(16, 16)
x:value(32, 32)
x:value(64, 64)
x.default = require("luci.model.uci").cursor():get("openvpn", "openvpn", "max_clients") or 2

return m,n,o
