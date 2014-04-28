-- (c) john@phrozen.org gplv2

module("luci.fon.host", package.seeall)

function generate()
	local f = io.open("/etc/hosts", "w")
	if not(f) then
		return
	end
	f:write("127.0.0.1 localhost localhost.\n")
	local lan = require("luci.fon.net.lan")
	function _generate(s)
		if s.host then
			f:write(lan.ip().." "..s.host.."\n")
		end
	end
	local uci = require("luci.model.uci").cursor()
	uci:foreach("fonhosts", "host", _generate)
	f:close()
end

function add(name, val)
	if not(name) or not(val) then
		return
	end
	generate()
end

function remove(name)
	if not(name) then
		return
	end
	generate()
end
