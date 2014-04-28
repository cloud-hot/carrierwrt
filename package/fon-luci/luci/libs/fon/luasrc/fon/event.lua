-- (c) john@phrozen.org gplv2

module("luci.fon.event", package.seeall)

function new(e)
	os.execute("fs -l ".. (e or ""))
end

function runnow(e)
	os.execute("logger \"runnow --> /etc/fonstated/"..e.."\"")
	os.execute("/etc/fonstated/"..e)
end

function runnow_nowait(e)
	local posix = require("posix")
	local pid = posix.fork()
	if pid == 0 then
		local f = require("fon")
		f.detachconsole()
		posix.exec("/etc/fonstated/"..e)
		os.exit(1)
	end
end


