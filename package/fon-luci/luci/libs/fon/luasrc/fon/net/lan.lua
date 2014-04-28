module("luci.fon.net.lan", package.seeall)

function up()
	os.execute("ifup lan")
end

function down()
	os.execute("ifdown lan")
end

function ip()
	local uci = require("luci.model.uci").cursor()
	return uci:get("fon", "lan", "ipaddr") or "192.168.10.1"
end
