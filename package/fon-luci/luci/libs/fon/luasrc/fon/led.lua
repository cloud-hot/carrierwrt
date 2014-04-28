-- (c) john@phrozen.org gplv2
module("luci.fon.led", package.seeall)

local uci = require("luci.model.uci").cursor()
function set(name, val)
	local led = uci:get("system", name, "sysfs")
	if led then
		local f = io.open("/sys/class/leds/"..led.."/brightness", "w")
		if f then
			f:write(val or "1")
			f:close()
			return true
		end
	end
	return false
end

function trigger(name, val)
	local led = uci:get("system", name, "sysfs")
	if led then
		local f = io.open("/sys/class/leds/"..led.."/trigger", "w")
		if f then
			f:write(val or "1")
			f:close()
			return true
		end
	end
	return false
end

function clear(name)
	set(name, 0)
end

function setOnline()
	local spot = require("luci.fon.spot")
	if spot.get_device() == "fonera20" then
		set("powerg")
		clear("powero")
	else
		trigger("powerg", "none")
		set("powerg")
	end
end

function setOffline()
	local spot = require("luci.fon.spot")
	if spot.get_device() == "fonera20" then
		set("powero")
		clear("powerg")
	else
		trigger("powerg", "heartbeat")
	end
end
