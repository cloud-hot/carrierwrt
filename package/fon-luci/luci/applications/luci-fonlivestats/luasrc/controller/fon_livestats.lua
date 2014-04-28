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

module("luci.controller.fon_livestats", package.seeall)

function index()
	require("luci.i18n")
	luci.i18n.loadc("fon_livestats")

	entry( {"wifistat"}, template("fon_livestats/wireless"), luci.i18n.translate("livestats_stat_wireless", "Realtime Wireless Status"), 90 ).i18n = "fon_livestats"
	entry( {"trafstat"}, template("fon_livestats/traffic"),  luci.i18n.translate("livestats_stat_traffic", "Realtime Network Traffic"),  91 ).i18n = "fon_livestats"
	entry( {"loadavg"},  template("fon_livestats/loadavg"),  luci.i18n.translate("livestats_stat_loadavg", "Realtime System Load"),  92 ).i18n = "fon_livestats"
	
	-- Maybe secure this later?
	entry( {"fon_rpc", "livestats"}, call("rpc") ).sysauth = false
end


function rpc()
	local sys = require "luci.sys"
	local http = require "luci.http"
	local ltn12   = require "luci.ltn12"
	local jsonrpc = require "luci.jsonrpc_fon"
	
	local livestats = {}
	livestats.loadavg = sys.loadavg
	livestats.traffic = sys.net.deviceinfo
	livestats.wireless = sys.wifi.getiwconfig
	
	http.prepare_content("application/json")
	ltn12.pump.all(jsonrpc.handle(livestats, http.source()), http.write)
end
