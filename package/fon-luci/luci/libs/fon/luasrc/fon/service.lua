-- (c) john@phrozen.org gplv2

module("luci.fon.service", package.seeall)

function add(name, path, boot, order, process)
	if name and path then
		local uci = require("luci.model.uci").cursor()
		uci:section("services", "service", name, {path=path,boot=boot,order=order,process=process})
		uci:commit("services")
	end
end

function del(name)
	if name then
		local uci = require("luci.model.uci").cursor()
		uci:delete("services",  name)
		uci:commit("services")
	end
end

function boot()
	local uci = require("luci.model.uci").cursor()
	local util = require("luci.util")
	local early = {}
	local ordered = {}
	local disordered = {}

	function _boot(s)
		if s.boot and s.order then
			if s.order == "early" then
				early[#early + 1] = s.boot
			else
				ordered[s.order..s[".name"]] = s.boot
			end
		elseif s.boot then
			disordered[#disordered + 1] = s.boot
		end
	end

	uci:foreach("services", "service", _boot)

	local event = require("luci.fon.event")

	-- early, get started in background
	for i,v in ipairs(early) do
		event.runnow_nowait(v)
	end

	-- ordered, has .order ~= nil, get started in given order
	for i,v in util.kspairs(ordered) do
		event.runnow(v)
	end

	-- start all remaining jobs in background
	for i,v in pairs(disordered) do
		event.runnow_nowait(v)
	end
end

local util = require("luci.util")

Service = util.class()

function Service.__init__(self, name)
	self.uci = require("luci.model.uci").cursor()
	self.uci_state = require("luci.model.uci").cursor_state()
	self.name = name
	self.fwall = self.uci:get("services", name, "fwall")
	self.path = self.uci:get("services", name, "path")
	self.pid = self.uci_state:get("services", name, "pid")
	self.pidnocheck = self.uci_state:get("services", name, "pid")
	self.process = self.uci:get("services", name, "process")
	self.mdns = self.uci:get("services", name, "mdns")
	local sys = require("luci.fon.sys")
	local alive = sys.pidalive(self.pid)
	if not(alive) and self.pidnocheck ~= "1" then
		self.pid = nil
	end
end

function Service.status(self)
	if not(self.path) then
		return nil
	end
	if self.process or (self.pid and tonumber(self.pid) > 0) then
		return true
	end
	return false
end

function announce_mdns(service)
	os.execute("ln -s /etc/avahi/services/"..service.." /tmp/mdns/")
	os.execute("/usr/sbin/avahi-daemon -r")
end

function deannounce_mdns(service)
	os.execute("rm /tmp/mdns/"..service)
	os.execute("/usr/sbin/avahi-daemon -r")
end

function Service.start(self, ...)
	if not(self.path) then
		return nil
	end
	if not(self.pid) and not(self.process) then
		local posix = require("posix")
		local pid = posix.fork()
		if pid ~= 0 then
			self.pid = pid
			self.uci_state:set("services", self.name, "pid", pid)
			self.uci_state:save("services")
		else
			local f = require("fon")
			f.detachconsole()
			posix.exec(self.path, ...)
		end
		if self.mdns ~= nil then
			announce_mdns(self.mdns)
		end
		if self.fwall == "1" then
			local event = require("luci.fon.event")
			event.runnow("FWallDaemon")
		end
		return true
	end
	if self.process then
		os.execute(self.path.." &")
		return true
	end
	return false
end

function Service.stop(self)
	if not(self.path) then
		return nil
	end
	if self.pid and tonumber(self.pid) > 0 and not(self.process) then
		local posix = require("posix")
		posix.kill(self.pid, 9)
		self.pid = nil
		self.uci_state:revert("services", self.name, "pid")
		self.uci_state:save("services")
		if self.fwall == "1" then
			local event = require("luci.fon.event")
			event.runnow("FWallDaemon")
		end
		if self.mdns ~= nil then
			deannounce_mdns(self.mdns)
		end
		return true
	end
	if self.process then
		os.execute("killall "..self.process)
	end
	return false
end

function Service.restart(self, ...)
	self.stop(self)
	self.start(self, ...)
end

function Service.getpid(self)
	return self.pid
end
