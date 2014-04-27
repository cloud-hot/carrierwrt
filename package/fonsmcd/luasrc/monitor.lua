#!/usr/bin/env lua

--[[
    
    monitor.lua - send a monitor status to the hotspot server

    Copyright (C) 2008-2009 jokamajo.org
                  2011 Bart Van Der Meerssche <bart.vandermeerssche@hotspot.net>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

]]--

if not arg[1] then
	print ('Please pass the reset argument as a boolean to the script.')
	os.exit(1)
end

local dbg        = require 'dbg'
local nixio      = require 'nixio'
nixio.fs         = require 'nixio.fs'
local uci        = require 'luci.model.uci'.cursor()
local luci       = require 'luci'
luci.sys         = require 'luci.sys'
luci.json        = require 'luci.json'
luci.util        = require 'luci.util'


-- parse and load /etc/config/hotspot
local hotspot          = uci:get_all('hotspot')

-- gzipped syslog tmp file
local SYSLOG_TMP      = '/tmp/syslog.gz'
local SYSLOG_GZIP     = 'logread | gzip > ' .. SYSLOG_TMP

-- collect relevant monitoring points
local function collect_mp()
	local monitor = {}

	monitor.reset = tonumber(arg[1])
	monitor.time = os.time()
	monitor.uptime  = math.floor(luci.sys.uptime())
	system, model, monitor.memtotal, monitor.memcached, monitor.membuffers, monitor.memfree = luci.sys.sysinfo()

	os.execute(SYSLOG_GZIP)
	io.input(SYSLOG_TMP)
	local syslog_gz = io.read("*all")

	monitor.syslog = nixio.bin.b64encode(syslog_gz)

	local defaultroute = luci.sys.net.defaultroute()
	if defaultroute then
		local device = defaultroute.device
		monitor.ip = luci.util.exec("ifconfig " .. device):match("inet addr:([%d\.]*) ")
		monitor.port = uci:get('uhttpd', 'restful', 'listen_http')[1]:match(":([%d]*)")
	end

	return monitor
end


-- open the connection to the syslog deamon, specifying our identity
nixio.openlog('heartbeat', 'pid')

local monitor = collect_mp()
local monitor_json = luci.json.encode(monitor)
