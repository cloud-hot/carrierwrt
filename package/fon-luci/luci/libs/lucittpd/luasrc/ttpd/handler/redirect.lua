--[[

HTTP server implementation for LuCI - file handler
(c) 2008 Steven Barth <steven@midlink.org>
(c) 2008 Freifunk Leipzig / Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

$Id$

]]--

local ipairs, type, tonumber = ipairs, type, tonumber
local io = require "io"
local os = require "os"
local fs = require "luci.fs"
local util = require "luci.util"
local ltn12 = require "luci.ltn12"
local mod = require "luci.ttpd.module"
local srv = require "luci.ttpd.server"
local string = require "string"

module "luci.ttpd.handler.redirect"

Simple = util.class(mod.Handler)
Response = mod.Response

function Simple.__init__(self)
	mod.Handler.__init__(self)
end

function Simple.handle_get(self, request, sourcein, sinkerr)
	local file = "/www/splash.htm"
	local stat = fs.stat(file)

	if stat then
		if stat.type == "regular" then
			local f, err = io.open(file)
			if f then
				local code = 200
				local headers = {
					["Content-Type"]   = "text/html",
					["Accept-Ranges"]  = "bytes",
				}

				s = stat.size
				headers["Content-Length"] = s

				-- Send Response
				return Response(code, headers),
					srv.IOResource(f, 0, s)
			else
				return self:failure( 403, err:gsub("^.+: ", "") )
			end
		else
			return self:failure(403, "Unable to transmit " .. stat.type .. " " .. file)
		end
	else
		return self:failure(404, "No such file: " .. file)
	end
end

function Simple.handle_head(self, ...)
	return (self:handle_get(...))
end
