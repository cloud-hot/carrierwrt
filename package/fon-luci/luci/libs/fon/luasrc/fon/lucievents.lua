--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local os = require "os"
local sys = require "luci.sys"
local cursor = require "luci.model.uci".cursor_state()
local tonumber, ipairs = tonumber, ipairs

module "luci.fon.lucievents"

-- Create new event
function fire(type, event, expires)
	event = event or {}
	event.type = type
	event.expires = expires
	
	if not event.id then
		event.id = sys.uniqueid(16)
	end
	
	cursor:section("lucievents", "event", nil, event)
	cursor:save("lucievents")
end

-- Fetch pending events
function fetch()
	local events = {}
	local time = os.time()
	local delete = {}

	cursor:foreach("lucievents", "event", function(s)
		if not tonumber(s.expires) or tonumber(s.expires) > time then
			events[#events+1] = s
		else
			delete[#delete+1] = s[".name"]
		end
	end)
	
	if #delete > 0 then
		for _, del in ipairs(delete) do
			cursor:delete("lucievents", del)
		end
		cursor:save("lucievents")
	end

	return events
end

-- Acknowledge event with given id
function acknowledge(id)
	cursor:delete_all("lucievents", "event", {id=id})
	cursor:save("lucievents")
end
