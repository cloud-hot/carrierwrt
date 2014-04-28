--[[
LuCI - Lua Configuration Interface

Copyright 2009 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local dsp = require "luci.dispatcher"
local http = require "luci.http"
local playradio

m = Map("audiod",
	translate("music_stations"),
	translate("music_stations_desc", "Here you can add URLs to pls files or directly point to a stream server"))

function m.commit_handler(submit)
	if submit and playradio then
		local music = {}
		for i, node in ipairs(dsp.context.requested.path) do
			if i == #dsp.context.requested.path then
				break
			end
			music[#music+1] = node
		end
		http.redirect(dsp.build_url(unpack(music)) .. "?radio=" .. playradio)
		m.render = function() end
	end
end

s = m:section(TypedSection, "radiostation")
s.addremove = true
s.anonymous = true
s.template = "cbi/tblsection"
s.defaults.type = "shoutcast"

s:option(Value, "_name",  translate("name"))
s:option(Value, "uri", "URI")
local play = s:option(Button, "_play", translate("music_start"))
play.inputstyle = "music-play"

function play.write(self, section)
	playradio = self.map:get(section, "uri")
end


return m
