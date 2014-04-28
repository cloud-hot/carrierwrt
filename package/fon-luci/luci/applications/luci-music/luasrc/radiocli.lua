--[[
LuCI - Lua Development Framework

Copyright 2009 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local httpc = require "luci.httpclient"
local nixio = require "nixio", require "nixio.util"
local tonumber, unpack, type = tonumber, unpack, type

module "luci.radiocli"
local scheaders, scmeta, splicef = "scheaders", "scmeta", nixio.splice_flags()

local function sc_meta(metacb, length, socket, buffer)
	length = length * 16						-- Metadata comes in 16B blocks
	buffer = buffer or socket:readall(length)
	if #buffer < length then
		local data, code, msg = socket:readall(length - #buffer)
		if not data then
			return nil, code, msg
		end
		buffer = buffer .. data
	end
	local md, length = {}, buffer:find("\0", 1, true)	-- Detect NULL padding
	buffer = length and buffer:sub(1, length - 1) or buffer
	for key, val in buffer:gmatch("(Stream.-)='(.-)';") do
		md[key] = val
	end
	return metacb(scmeta, md)
end

function splice_to_file(uri, file, metacb)
	local htopts = metacb and {headers = {["icy-metadata"] = "1"}} or nil
	local code, response, buffer, sock = httpc.request_raw(uri, htopts)
	
	if not code then
		return nil, response, buffer
	elseif code ~= 200 then
		return nil, code, response.status
	end
	
	local metaint, stat, code, msg = tonumber(response.headers["icy-metaint"])
	if metacb then
		local ret = {metacb(scheaders, response.headers)}
		if not ret[1] then
			sock:close()
			return unpack(ret)
		end
	end

	if type(file) ~= "userdata" then
		file, code, msg = nixio.open(file, nixio.open_flags("wronly"))
		if not file then
			return nil, code, msg
		end
	end

	if not metaint then							-- Server won't send metadata
		file:writeall(buffer)
		repeat
			stat, code, msg = nixio.splice(sock, file, 65536, splicef)
		until not stat or stat == 0
	else										-- Server will send metadata
		local offset = 0
		local stat = true
		repeat
			local datarem = metaint - offset
			if buffer and #buffer > 0 then		-- Buffer not empty yet
				if #buffer <= datarem then		-- Buffer < payload block
					file:writeall(buffer)
					offset = offset + #buffer
					buffer = nil
				else							-- Buffer > payload block
					file:writeall(buffer:sub(1, datarem))
					local len = buffer:byte(datarem + 1)
					buffer = buffer:sub(datarem + 2)
					if len > 0 then
						stat, code, msg = sc_meta(metacb, len, sock, buffer)
						buffer = buffer:sub(len + 1)
					end
					offset = 0
				end
			else								-- Read from socket
				if datarem > 0 then				-- Still payload to read
					stat, code, msg = nixio.splice(sock, file, datarem, splicef)
					if stat then
						offset = offset + stat
					end
				else							-- Metadata block
					stat, code, msg = sock:read(1)
					if stat and stat:byte() > 0 then
						stat, code, msg = sc_meta(metacb, stat:byte(), sock)
					end
					offset = 0
				end
			end
		until not stat or stat == 0
	end
	return stat and true, code, msg
end