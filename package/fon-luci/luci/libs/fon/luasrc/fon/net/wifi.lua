module("luci.fon.net.wifi", package.seeall)

function wandown()
	os.execute("wlanconfig ath2 destroy")
end

function up()
	os.execute("wifi")
end

function down()
	os.execute("wifi down")
end
