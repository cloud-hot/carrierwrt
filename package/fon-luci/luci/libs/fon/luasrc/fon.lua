-- (c) john@phrozen.org gplv2

module("luci.fon", package.seeall)

function registered()
	return (require("luci.model.uci").cursor_state():get("registered", "fonreg", "registered") == "1") and true or false
end

state = {}

function state.online()
	local o = require("luci.model.uci").cursor_state():get("fon", "state", "online")
	if o == "1" then
		return true
	else
		return false
	end
end

function state.online_str()
	local o = state.online()
	local u = require("luci.model.uci").cursor():get("fon", "wan", "mode") == "umts"
	local ret = "off"
	if o and not(u) then
		ret = "on"
	end
	if o and u then
		ret = "umts"
	end
	return ret
end

function state.setOnline()
	local uci = require("luci.model.uci").cursor_state()
	local event = require("luci.fon.event")
	local led = require("luci.fon.led")
	-- do not run if we are already online
	if state.online() then
		return
	end

	os.execute("echo -n \"Online\" > /tmp/run/fonstate")
	uci:revert("fon", "state", "online")
	uci:set("fon", "state", "online", "1")
	uci:save("fon")
	event.runnow("HotspotStart")
	event.runnow("RestartNtpclient")
	led.setOnline()
	os.execute("/etc/init.d/thinclient start &")
end

function state.setOffline()
	local uci = require("luci.model.uci").cursor_state()
	local event = require("luci.fon.event")
    local led = require("luci.fon.led")

	-- do not run if we are already offline
	if not(state.online()) then
		return
	end

	os.execute("echo -n \"Offline\" > /tmp/run/fonstate")
	uci:revert("fon", "state", "online")
	uci:set("fon", "state", "online", "0")
	uci:save("fon")
	event.runnow("HotspotStop")
	event.runnow("RestartNtpclient")
	led.setOffline()
end
