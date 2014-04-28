--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local ipairs, type, unpack = ipairs, type, unpack

local dsp = require "luci.dispatcher"
local util = require "luci.util"
local table = require "table"
local lucievents = require "luci.fon.lucievents"

module "luci.tools.webevents"
local context = util.threadlocal()

function feeder(type, node)
	register("feed", type, node)
end

function handler(type, node)
	register("rpc", type, node.path)
end

-- Return a list of webevents and their registered event handler
function dispatch(class)
	local evlist = {}
	local hndls = context.handlers and context.handlers[class]

	if hndls then
		for _, ev in ipairs(lucievents.fetch()) do
			local hndl = hndls[ev.type]
			if hndl then
				local ent = {event=ev, handler={}}
				for _, handle in ipairs(hndl) do
					ent.handler[#ent.handler+1] = handle
				end
				evlist[#evlist+1] = ent
			end
		end
	end

	return evlist
end

-- Register event handler
function register(class, type, node)
	context.handlers = context.handlers or {}
	local chndl = context.handlers
	if not chndl[class] then
		chndl[class] = {}
	end
	chndl = chndl[class]

	chndl[type] = chndl[type] or {}
	chndl[type][#chndl[type]+1] = node
end

-- Unregister event handler
function unregister(class, type, node)
	local chndl = context.handlers
	chndl = chndl and chndl[class]
	if chndl and chndl[type] then
		if not node then
			chndl[type] = nil
		else
			local key = util.contains(chndl[type], node)
			if key then
				table.remove(chndl[type], key)
			end
		end
	end
end
