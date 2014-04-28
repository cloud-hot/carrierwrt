-- (c) john@phrozen.org gplv2

module("luci.fon.sys", package.seeall)

function pidalive(pid)
	if not(pid) then
		return nil
	end

	local fs = require("luci.fs")
	local stat = fs.stat("/proc/"..pid.."/")

	if stat and stat.type == "directory" then
		return true
	end
	return false
end

function shutdown()
	local wan = require("luci.fon.net.wan")
	local lan = require("luci.fon.net.lan")
	os.execute("echo /bin/true > /proc/sys/kernel/hotplug")
	wan.down()
	lan.down()
end

function reset()
	local sys = require("luci.sys")
	shutdown()
	sys.reboot()
end

function factorydefault()
	shutdown()
	os.execute("/bin/factory.sh")
	local sys = require("luci.sys")
	sys.reboot()
end
