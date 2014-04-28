local req, assert, ipairs, pairs, pcall, os = require, assert, ipairs, pairs, pcall, os
local tonumber, tostring = tonumber, tostring

module "luci.controller.openvpn_rpc"

function index()
	local util = require "luci.util"
	local http = require "luci.http"
	local sauth = require "luci.sauth"

	-- Alternative authenticator using HTTP-GET variable
	local function authenticator(validator, accs)
		local auth = http.formvalue("auth", true)
		if auth then
			local user = sauth.read(auth)
			if user and util.contains(accs, user) then
				return user, auth
			end
		end
		http.status(403, "Forbidden")
	end

	-- Register JSON-RPC API
	local page = entry({"fon_rpc", "openvpn"}, call("rpc"))
	page.sysauth = "root"
	page.sysauth_authenticator = authenticator
	entry({"fon_rpc", "openvpn", "auth"}, call("rpc_auth")).sysauth = false

	local page  = node("fon_rpc", "openvpn", "config")
	page.target = call("openvpn_config")

end

local require = req

function openvpn_config()
	local http = require "luci.http"
	local client = http.formvalue("client")
	if not require("luci.model.uci").cursor():get("openvpn", client, "name") then
		os.execute("logger potential injection attempt?!")
		return
	end
	http.prepare_content("application/zip")
	os.execute("/usr/bin/openvpn-client.sh "..client)
	local f = require("luci.util").exec("cat /tmp/"..client.."_ovpn.zip")
	http.write(f)
end

function rpc_auth()
	local os      = require "os"
	local jsonrpc = require "luci.jsonrpc_fon"
	local sauth   = require "luci.sauth"
	local http    = require "luci.http"
	local sys     = require "luci.sys"
	local ltn12   = require "luci.ltn12"
	local uci = require "luci.model.uci".cursor()

	local loginstat

	local server = {}
	server.plain = function(user, pass)
		local sid

		if user == "fonero" or user == "admin" then user = "root" end
		if sys.user.checkpasswd(user, pass) then
			sid = sys.uniqueid(16)
			sauth.write(sid, user)
		end

		return sid
	end

	http.prepare_content("application/json")
	ltn12.pump.all(jsonrpc.handle(server, http.source()), http.write)
end

function rpc()
	local os = require "os"
	local fs = require "luci.fs"
	local uci = require "luci.model.uci".cursor_state()
	local http = require "luci.http"
	local posix = require "posix"
	local ltn12 = require "luci.ltn12"
	local jsonrpc = require "luci.jsonrpc_fon"

	-- Object table to be published via RPC
	local export = {}

	function export.gencert(name)
		local uci = require("luci.model.uci").cursor()
		if uci:get("openvpn", name, "name") == name then
			return true
		end
		uci:load("openvpn")
		uci:section("openvpn", "client", name, {name=name})
		uci:commit("openvpn")
		os.execute("/usr/sbin/pkitool "..name)
		return true
	end

	-- Publish functions
	http.prepare_content("application/json")
	ltn12.pump.all(jsonrpc.handle(export, http.source()), http.write)
end
