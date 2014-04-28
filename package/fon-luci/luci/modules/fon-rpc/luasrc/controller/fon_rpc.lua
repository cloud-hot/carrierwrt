--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local require = require
local assert = assert
local ipairs = ipairs
local unpack = unpack
local pairs = pairs
local print = print
local pcall = pcall
local table = table
local type = type

module "luci.controller.fon_rpc"

function index()
	--[[
	local function authenticator(validator, accs)
		local auth = luci.http.formvalue("auth", true)
		if auth then
			local user = luci.sauth.read(auth)
			if user and luci.util.contains(accs, user) then
				return user, auth
			end
		end
		luci.http.status(403, "Forbidden")
	end
	]]--
	
	local rpc = node("fon_rpc")
	rpc.sysauth = "root"
	--rpc.sysauth_authenticator = authenticator
	rpc.notemplate = true
	
	entry({"fon_rpc", "fon"}, call("fon")).sysauth = false
	
	--entry({"rpc", "auth"}, call("rpc_auth")).sysauth = false
end

--[[
function rpc_auth()
	local jsonrpc = require "luci.jsonrpc_fon"
	local sauth   = require "luci.sauth"
	local http    = require "luci.http"
	local sys     = require "luci.sys"
	local ltn12   = require "luci.ltn12"
	
	local loginstat
	
	local server = {}
	server.login = function(user, pass)
		local sid
		
		if sys.user.checkpasswd(user, pass) then
			sid = sys.uniqueid(16)
			http.header("Set-Cookie", "sysauth=" .. sid.."; path=/")
			sauth.write(sid, user)
		end
		
		return sid
	end
	
	http.prepare_content("application/json")
	ltn12.pump.all(jsonrpc.handle(server, http.source()), http.write)
end
]]

function fon()
	local uci = require "luci.model.uci"
	local dsp = require "luci.dispatcher"
	local util = require "luci.util"
	local http = require "luci.http"
	local ltn12   = require "luci.ltn12"
	local jsonrpc = require "luci.jsonrpc_fon"

	-- Object table to be published via RPC
	local fon = {}

	function fon.online_status()
		local o = uci.cursor_state():get("fon", "state", "online") == "1"
		local u = uci.cursor():get("fon", "wan", "mode") == "umts"
		local r = "off"
		if o and not(u) then
			r = "on"
		end
		if o and u then
			r = "umts"
		end
		return r
	end

	function fon.event_update()
		local events = require("luci.tools.webevents").dispatch("rpc")
		for _, event in ipairs(events) do
			for k, handler in ipairs(event.handler) do
				event.handler[k] = dsp.build_url(unpack(handler))
			end
		end
		return events
	end

	function fon.status_pull()
		return {status=fon.online_status(), events=fon.event_update()}
	end

	function fon.reload_pull(path, ...)
		assert(type(path) == "table", "Invalid request")

		local node = dsp.node(unpack(path))
		if node.fon_reload then
			return node.fon_reload(...)
		else
			return {reload="no handler"}
		end
	end

	function fon.event_acknowledge(id)
		return require("luci.fon.lucievents").acknowledge(id)
	end

	function fon.device_update(filter)
		assert(not filter or type(filter) == "table", "Invalid request")

		local devs = dsp.node("fon_devices").nodes
		local response = {}
		local keys = filter or util.keys(devs)

		for _, v in ipairs(keys) do
			if devs[v] and devs[v].fon_status then
				local stat, ret = pcall(devs[v].fon_status)
				response[v] = stat and ret or nil
			end
		end

		return response
	end

	-- Publish functions
	http.prepare_content("application/json")
	ltn12.pump.all(jsonrpc.handle(fon, http.source()), http.write)
end

