#! /usr/bin/env lua

--[[
    
    hotspotd.lua - Lua part of the hotspot daemon

    Copyright (C) 2013 Bart Van Der Meerssche <bart@hotspot.net>

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


local dbg        = require 'dbg'
local uci        = require 'luci.model.uci'.cursor()
local nixio      = require "nixio"
nixio.fs         = require "nixio.fs"
local mosq       = require "mosquitto"
local ubus       = require "ubus"


-- parse and load /etc/config/hotspot
local hotspot            = uci:get_all('hotspot')

local arg = arg or {} -- needed when this code is not loaded via the interpreter

local DEBUG             = (arg[1] == '-d')
local LOGMASK           = hotspot.daemon.logmask or 'info'
nixio.setlogmask(LOGMASK)

local POLLIN          = nixio.poll_flags("in")
local POLLOUT         = nixio.poll_flags("out")

local POLL_TIMEOUT_MS = -1 -- no timeout -1

local TIMERFD_HEARTBEAT_SEC     = hotspot.daemon.mqtt_heartbeat -- 5s
local TIMERFD_HEARTBEAT_NS      = 0

local timer_heartbeat = {
        fd = nixio.timerfd(TIMERFD_HEARTBEAT_SEC, TIMERFD_HEARTBEAT_NS, TIMERFD_HEARTBEAT_SEC, TIMERFD_HEARTBEAT_NS),
        events = POLLIN,
        revents = 0
}

--local MOSQ_NODE_ID       = uci:get('easycwmp', 'device', 'serial_number')
uci:foreach('easycwmp', 'device', function(x) MOSQ_NODE_ID = x.serial_number end)
local MOSQ_ID            = "tr069-" .. MOSQ_NODE_ID
local MOSQ_CLEAN_SESSION = true
local MOSQ_HOST          = hotspot.daemon.mqtt_broker
local MOSQ_PORT          = hotspot.daemon.mqtt_port
local MOSQ_KEEPALIVE     = hotspot.daemon.mqtt_keepalive
local MOSQ_MAX_READ      = 10 -- packets
local MOSQ_MAX_WRITE     = 10 -- packets

mosq.init()
local mqtt = mosq.new(MOSQ_ID, MOSQ_CLEAN_SESSION)
local conn = ubus.connect()
if not conn then
	error("Failed to connect to ubusd")
end

--mqtt:set_callback(mosq.ON_CONNECT, function(...) print("CONNECT", ...) end)
--mqtt:set_callback(mosq.ON_DISCONNECT, function(...) print("DISCONNECT", ...) end)
--mqtt:set_callback(mosq.ON_PUBLISH, function(...) print("PUBLISH", ...) end)

mqtt:set_callback(mosq.ON_MESSAGE, function(mid, topic_in, message, qos, retain)
	local topic_expect = "/" .. MOSQ_NODE_ID .. "/tr069/task"
	if topic_in == topic_expect then
		print("received tr069 task: " .. message)
		conn:call("tr069", "inform", { event = "connection_request" })
	end
end)

--mqtt:set_callback(mosq.ON_SUBSCRIBE, function(...) print("SUBSCRIBE", ...) end)
--mqtt:set_callback(mosq.ON_UNSUBSCRIBE, function(...) print("UNSUBSCRIBE", ...) end)
--mqtt:set_callback(mosq.ON_LOG, function(...) print("LOG", ...) end)

while not mqtt:connect(MOSQ_HOST, MOSQ_PORT, MOSQ_KEEPALIVE) do
	print("trying to connect to broker ...")
end

mqtt:subscribe("/" .. MOSQ_NODE_ID .. "/tr069/task/#", 2)

local broker = {
	fd = nixio.fd_wrap(mqtt:socket()), 
	events = POLLIN + POLLOUT,
	revents = 0
}

local fds = { timer_heartbeat, broker }

while true do
	local poll = nixio.poll(fds, POLL_TIMEOUT_MS)

	if not poll then -- poll == -1
	elseif poll == 0 then
	elseif poll > 0 then
		if nixio.bit.check(broker.revents, POLLIN) then
			mqtt:read(MOSQ_MAX_READ)
		end

		if nixio.bit.check(broker.revents, POLLOUT) and mqtt:want_write() then
			mqtt:write(MOSQ_MAX_WRITE)
		end

		if nixio.bit.check(timer_heartbeat.revents, POLLIN) then
                        timer_heartbeat.fd:numexp() -- reset the numexp counter
			mqtt:publish("/" .. MOSQ_NODE_ID .. "/heartbeat", "ok", 1, false) -- heartbeat for link status
--			mqtt:misc()       -- if no heartbeat than send mqtt housekeeping
                end
	end

	while (not mqtt:socket()) and (not mqtt:reconnect()) do
		print("trying to reconnect to broker ...")
		nixio.nanosleep(1, 0)
	end

	if mqtt:want_write() then
		broker.events = nixio.bit.set(broker.events, POLLOUT)
	else
		broker.events = nixio.bit.unset(broker.events, POLLOUT)
	end
end
