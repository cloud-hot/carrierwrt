-- (c) 2008 john@phrozen.org GPLv2

module("luci.fon.firewall", package.seeall)

function start()
	os.execute("/etc/init.d/firewall start")
end
