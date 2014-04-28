--[[
Copyright 2008 John Crispin <john@phrozen.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--
module("luci.controller.torrent", package.seeall)
function index(env)
	function setup_base(e)
		e.i18n = "torrent"
		e.icon_path	= "/luci-static/resources/icons/plugins"
		e.page_icon	= "torrent.png"
		e.sysauth = "root"
		e.sysauth_authenticator = "htmlauth"
		e.fon_reload = function()
			reload = os.time()
			return {reload=reload}
		end
	end

	require("luci.i18n")
	luci.i18n.loadc("torrent")
	if env.mounted == "0" then
		local e = entry({"torrent"}, template("nodisc"), luci.i18n.translate("torrent_title", "Torrent Transmission"))
		e.i18n = "torrent"
		e.icon_path	= "/luci-static/resources/icons/plugins"
		e.page_icon	= "torrent.png"
		return
	end

	if not(env.online) then
		local e = entry({"torrent"}, template("noinet"), luci.i18n.translate("torrent_title", "Torrent Transmission"))
		e.i18n = "torrent"
		e.icon_path	= "/luci-static/resources/icons/plugins"
		e.page_icon	= "torrent.png"
		return
	end

	local e = entry({"torrent", "shutdown"}, call("torrent_shutdown"), "")
	local e = entry({"torrent", "startup"}, call("torrent_startup"), "")
	local e = entry({"torrent", "download"}, call("torrent_download"), "")
	local e = entry({"torrent", "start"}, call("torrent_start"), "")
	local e = entry({"torrent", "del"}, call("torrent_del"), "")
	local e = entry({"torrent", "pause"}, call("torrent_pause"), "")
	local e = entry({"torrent", "add"}, call("torrent_add"), "")

	local fmg = (env.uci_state:get("fmg", "torrent", "state") or "0")
	if fmg == "2" then
		local e = entry({"torrent"}, template("torrent/shutdown"), luci.i18n.translate("torrent_title", "Torrent Transmission"))
		setup_base(e)
		return
	end

	if fmg ~= "1" then
		local e = entry({"torrent"}, template("torrent/notrunning"), luci.i18n.translate("torrent_title", "Torrent Transmission"))
		setup_base(e)
		return
	end
	local e = entry({"torrent", "queue"}, template("torrent/queue"), luci.i18n.translate("torrent_title", "Torrent Transmission"))
	local e = entry({"torrent"}, template("torrent/main"), luci.i18n.translate("torrent_title", "Torrent Transmission"))
	setup_base(e)
end

function torrent_startup()
	local http = require("luci.http")
	local disc = http.formvalue("disc")
	local fmg = require("luci.fmg")
	fmg.start("torrent", disc.."/")
	os.execute("sleep 2")
	return require("luci.http").redirect(require("luci.dispatcher").build_url("torrent"))
end

function torrent_download()
	local http = require("luci.http")
	local disc = http.formvalue("disc")
	local fmg = require("luci.fmg")
	fmg.install("torrent", disc)
	return require("luci.http").redirect(require("luci.dispatcher").build_url("torrent"))
end

function torrent_shutdown()
	local fmg = require("luci.fmg")
	fmg.stop("torrent")
	os.execute("sleep 1")
	return require("luci.http").redirect(require("luci.dispatcher").build_url("torrent"))
end

function torrent_cmd(cmd)
	local http = require("luci.http")
	local id = http.formvalue("id")
	local t = require("luci.transmission")
	t.issue_cmd(cmd, id)
	return require("luci.http").redirect(require("luci.dispatcher").build_url("torrent"))
end

function torrent_add()
	local http = require("luci.http")
	local link = http.formvalue("torrent_link")
	local up = http.formvalue("torrent_up")
	local down = http.formvalue("torrent_down")
	local t = require("luci.transmission")
	if link then
		t.add_torrent(link)
	end
	if up then
		t.speed_limit("up", (up ~= "0") and up or nil)
	end
	if down then
		t.speed_limit("down", (down ~= "0") and down or nil)
	end
	return require("luci.http").redirect(require("luci.dispatcher").build_url("torrent"))
end

function torrent_start()
	return torrent_cmd("start")
end

function torrent_pause()
	return torrent_cmd("stop")
end

function torrent_del()
	return torrent_cmd("remove")
end


