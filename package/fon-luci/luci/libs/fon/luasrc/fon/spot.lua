-- (c) 2008 john@phrozen.org GPLv2

module("luci.fon.spot", package.seeall)

function isonline()
	local uci = require("luci.model.uci").cursor_state()
	local spot = uci:get("fon", "state", "hotspot") or "0"
	if spot == "1" then
		return true
	end
	return false
end

function changed()
	local uci = require("luci.model.uci").cursor()
	local state = require("luci.fon").state

	if state.online() then
		local essid = uci:get("fon", "public", "essid")
		if get_device() == "fonera20" then
			os.execute("iwconfig \"ath0\" essid \"FON_"..essid.."\" >/dev/null 2>&1")
		else
			os.execute("iwpriv ra1 set SSID=\"FON_"..essid.."\"")
		end
		os.execute("killall -HUP chilli 1> /dev/null 2> /dev/null")
	end
end

function usercount()
	local uci = require("luci.model.uci").cursor_state()
	return (uci:get("fon", "state", "hotspotcount") or "0")
end

function start()
	local uci = require("luci.model.uci").cursor_state()
	local state = require("luci.fon").state

	if isonline() or not(state.online()) then
		return
	end

	uci:revert("fon", "state", "hotspot")
	uci:set("fon", "state", "hotspot", "1")
	uci:save("fon")

	os.execute("/etc/init.d/chillispot start")

	local led = require("luci.fon.led")
	led.setOnline()
end

function stop()
	local uci = require("luci.model.uci").cursor_state()

	if get_device() == "fonera20" then
		os.execute("ifconfig ath0 down")
		os.execute("iwconfig ath0 essid \"\"")
	else
		os.execute("ifconfig ra1 down")
	end

	if not(isonline()) or tonumber(usercount()) ~= 0 then
		return
	end

	uci:revert("fon", "state", "hotspot")
	uci:set("fon", "state", "hotspot", "0")
	uci:save("fon")

	os.execute("fs -l hotspot_wdt_stop")
	os.execute("/etc/init.d/chillispot stop")

	local led = require("luci.fon.led")
	led.setOffline()
end

function restart()
	local state = require("luci.fon").state
	if state.online() then
		os.execute("/etc/init.d/chillispot restart")
	end
end

function get_device()
	local str = require("luci.fs").readfile("/etc/fon_device")
	return str:sub(1, str:len() - 1)
end

