#!/usr/bin/lua

if not arg[1] or not arg[2] then
	io.stderr:write("usage: make gen3gdb IN=serviceproviders.xml OUT=3gdb.lua\n")
	os.exit(1)
end

if not pcall (require, "lxp.lom") then
	io.stderr:write("you need to install luaexpat (liblua5.1-expat0 on Debian)\n")
	os.exit(1)
end

local fs = require "luci.fs"
local util = require "luci.util"
local lom = require "lxp.lom"

raw = lom.parse(fs.readfile(arg[1]))
local registry = {}

	for _, v in ipairs(raw) do
		if type(v) == "table" then
			registry[v.attr.code] = {}
			local bl = registry[v.attr.code] 
			for _, v2 in ipairs(v) do
				if type(v2) == "table" then
					bl[#bl+1] = v2
				end
			end
		end
	end

for k, v in pairs(registry) do for k2,v2 in ipairs(v) do
	local provider = {}
	for k3, v3 in pairs(v2) do
		if type(v3) == "table" and v3.tag then
			if #v3 == 1 and type(v3[1]) == "string" then
				provider[v3.tag] = v3[1]
			else
				provider[v3.tag] = {}
				local dataset = provider[v3.tag]
				for k4, v4 in pairs(v3) do
					if type(v4) == "table" then
						dataset[#dataset+1] = v4[1]
					end
				end
			end
		end
	end
	v[k2] = provider
end end

io.output(arg[2])
io.write("return ")
io.write(luci.util.serialize_data(registry))
