module("luci.fon.net.wan", package.seeall)

-- check if an ip is on 172.0
function islocalip()
	local uci = luci.model.uci.cursor_state()
	local wan = uci:get("network", "wan", "device")
	if wan then
		local netdata = luci.sys.net.getifconfig()
		wan_ip = netdata[wan]["inet addr"]
		if not(wan_ip) then
			return nil
		end
		return string.sub(wan_ip, 1, 8) == "192.168."
	end
end

function getnameserver()
	local file = io.open("/etc/resolv.conf", "r")
	local ret = {}
	if file then
		local util = require "luci.util"
		local data = file:read()
		while data do
			local vals = util.split(data, " ")
			if vals[1] == "nameserver" then
				table.insert(ret, vals[2])
			end
			data = file:read()
		end
		file:close()
		return ret
	end
	return nil
end

function up()
	os.execute("ifup wan")
end

function down()
	os.execute("ifdown wan")
end
