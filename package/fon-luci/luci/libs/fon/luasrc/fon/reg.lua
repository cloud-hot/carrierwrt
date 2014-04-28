-- (c) john@phrozen.org gplv2

module("luci.fon.reg", package.seeall)

function setreg()
	luci.model.uci.cursor_state():get("registered", "fonreg", "registered", "1")
end

function gethash()
	local hash = luci.util.exec("cat /etc/chilli.conf | grep 'uamserver' | awk -F'/sec/' '{ print $2 }' | awk -F'/' '{ print $1 }'")
	return #hash > 8 and hash or nil
end

function getmac()
	luci.model.uci.cursor_state():get("registered", "fonreg", "registered", "1")
	if require("luci.fon.spot").get_device() == "fonera20n" then
		mac = luci.sys.net.getmac("eth0.1", "-")
	else
		mac = luci.sys.net.getmac("ath0", "-")
	end
	return mac and string.gsub(mac, ":", "-") or nil
end

function geturl()
	local fon = require("luci.fon")
	if fon.registered() then
		return
	end
	local mac = getmac() or ""
	local hash = gethash() or ""
	return (#hash > 1 and #mac > 1) and ("https://www.fon.com/main/standaloneLogin?h="..hash.."&m="..mac)
end
