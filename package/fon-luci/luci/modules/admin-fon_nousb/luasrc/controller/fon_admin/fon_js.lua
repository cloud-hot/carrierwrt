--[[
LuCI - Lua Configuration Interface

Copyright 2008 John Crispin <blogic@openwrt.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--
module("luci.controller.fon_admin.fon_js", package.seeall)

function index()
	local webevents = require "luci.tools.webevents"
	
	node("fon_js")
	entry({"fon_js", "main.js"}, template("fon_js/main"))
	local node = entry({"fon_js", "testevent"}, template("fon_js/testevent"))
	
	webevents.handler("testevent", node) 
end
