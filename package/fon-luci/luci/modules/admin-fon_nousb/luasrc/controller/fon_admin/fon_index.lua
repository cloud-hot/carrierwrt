--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local os = os
local io = io
local req = require
local pairs = pairs
local string = string
local tonumber = tonumber
module("luci.controller.fon_admin.fon_index", package.seeall)

function index()
	local root = node()
	root.lock = true
	root.target = call("root")

	local page = node("fon_dashboard")
	page.target = call("dashboard")
	page.sysauth = "root"
	page.sysauth_authenticator = "htmlauth"

	entry({"fon_dashboard", "_status"}, template("fon/admin_fon_summary"))
	entry({"fon_dashboard", "_attached"}, template("fon/admin_fon_attached"))
	assign({"_maincontent"}, {})
	assign({"_dashcontent"}, {})

	local page  = node("fon_admin", "fon_plugins")
	page.target = call("action_plugin")
	page.title  = require "luci.i18n".translate("plugins", "Plugins")
	page.icon = "icons/plugins.png"
	page.page_icon = "icons/plugins.png"
	page.sysauth = "root"
	page.sysauth_authenticator = "htmlauth"
	page.order = 90

	local page  = node("fon_admin", "fon_plugins", "upgrade")
	page.target = call("action_upgrade")

	local page = node("fon_status")
	page.target = template("fon_status/main")
	page.title = require "luci.i18n".translate("fon_status", "Status")
	page.icon   = "icons/fonera_on.png"
	page.page_icon   = "icons/fonera_on.png"

	local page = node("splash")
	page.title = "Splash"
	page.target = template("fon/splash")

	entry( {"fon_rpc", "livestats"}, call("rpc") ).sysauth = false

	local page = node("nodisc")
	page.title = require "luci.i18n".translate("nodisc", "No disc")
	page.target = template("nodisc")
	page.sysauth = "root"
	page.sysauth_authenticator = "htmlauth"
end

local require = req

function dashboard()
	local util = require "luci.util"
	local uci = require "luci.model.uci".cursor()
	local tpl = require "luci.template"
	local dsp = require "luci.dispatcher"
	local cfg = require "luci.config"

	tpl.render("fon/master_dashboard")
	tpl.render("fon/admin_fon")
end

function root()
	local uci = require "luci.model.uci".cursor()
	local dsp = require "luci.dispatcher"
	local http = require "luci.http"

	local i = 0
	local pluginname = nil
	uci:foreach("plugfons", "plugin", function(s)
		if s.redirect == "1" then
			pluginname = s[".name"]
			i = i + 1
		end
	end)

	-- No plugins => /fon_status
	if i == 1 then
		http.redirect(dsp.build_url(pluginname))
	else
		http.redirect(dsp.build_url("fon_dashboard"))
	end
end

function action_upgrade()
	local feed = "http://download.fonosfera.org/plugins/"
	--feed = "http://192.168.10.183/"
	local tmpfile = "/tmp/update.img"
	local http = require "luci.http"
	local dsp = require "luci.dispatcher"
	local fw_version = require("luci.model.uci").cursor():get("system", "fon", "upgrade")
	if fw_version then
		os.execute("fs -l hotspot_wdt_stop")
		os.execute("killall -9 mjpg_streamer mountd chilli smbd pure-ftp fonsmcd ctcs ctorrent chilloutd ntpclient dropbear")
		local dl = os.execute("wget "..feed.."firmware_"..fw_version..".tar.gz -qO "..tmpfile)
		if dl ~= 1 then
			local verify = require("luci.fon.pkg.verify")
			local str, key, err = verify.fonidentify(tmpfile)
			if str == "reflash" then
				local dir, str = verify.fonverify(tmpfile, "/etc/fon/keyring/", false)
				if dir ~= nil then
					local uci = require("luci.model.uci").cursor_state()
					uci:set("fon", "state", "upgrade", dir)
					uci:save("fon")
					require("luci.fon.event").new("FlashDevice")
					return luci.http.redirect(luci.dispatcher.build_url("upgrading"))
				end
			end
		end
	end
	http.redirect(dsp.build_url("fon_devices", "fon_plugins"))
end

function action_plugin()
	local http = require "luci.http"
	local i18n = require "luci.i18n"
	local feed = "http://download.fonosfera.org/plugins/"
	--feed = "http://192.168.10.183/"
	local ret  = nil
	local tmpfile = "/tmp/update.img"
	local keep_avail = true
	local device = luci.fs.readfile("/etc/fon_device")
	device = string.sub(device, 1, #device -1)
	local online = require("luci.model.uci").cursor_state():get("fon", "state", "online") == "1"
	local dev = require("luci.model.uci").cursor_state():get("registered", "fonreg", "dev") == "1"
	local firmware = require("luci.model.uci").cursor():get("system", "fon", "firmware").."."..require("luci.model.uci").cursor():get("system", "fon", "revision")
	local pl_file = "Plugins_"..device.."_"..firmware..".lua"

	local file
	local first = true
	local type
	http.setfilehandler(
		function(meta, chunk, eof)
			if not chunk then
				return
			end
			if first then
				os.remove(tmpfile)
				os.remove(tmpfile)
				if chunk:sub(1,2) == "\031\139" then
					type = "tgz"
				elseif chunk:sub(1,2) == "FO" then
					type = "fon"
				else
					ret = i18n.translate("plugin_invalid", "Invalid plugin")
				end
			end
			first = false
			if type then
				if not file then
					file = io.open(tmpfile, "w")
				end
				if chunk then
					file:write(chunk)
				end
				if eof then
					file:close()
				end
			end
		end
	)

	local install = http.formvalue("install")
	local update = http.formvalue("update")
	local version = http.formvalue("version")
	local del = http.formvalue("del")
	local redir
	local dl = 1
	if (update or install) and online then
		local s = require("luci.sys").httpget(feed..pl_file)
		local plf = loadstring(s)
		local ple = {}
		setfenv(plf, ple)
		plf()
		for i = 1,#ple.plugins, 1 do
			if ple.plugins[i].name == (update or install) and ple.plugins[i].device == device and
					(not(ple.plugins[i].firmware) or (ple.plugins[i].firmware == firmware)) and
					(not(ple.plugins[i].devonly) or (ple.plugins[i].devonly and dev)) then
				local file = feed..ple.plugins[i].name.."_"..ple.plugins[i].version.."_"..ple.plugins[i].device.."_"..ple.plugins[i].signature..".tar.gz"
				if ple.plugins[i].firmware then
					file = feed..ple.plugins[i].name.."_"..ple.plugins[i].version.."_"..ple.plugins[i].device.."_"..ple.plugins[i].firmware.."_"..ple.plugins[i].signature..".tar.gz"
				end
				dl = os.execute("wget ".. file.." -qO "..tmpfile)
				redir = ple.plugins[i].redir
				if dl == 1 then
					update = nil
					install = nil
				else
					if ple.plugins[i].signature == "fon" then
						type = "fon"
					else
						if dev then
							type = "tgz"
						else
							type = nil
						end
					end
				end
			end
		end
	end
	if update then
		del = update
		install = update
	end
	if del then
		local pkg = require("luci.fon.pkg")
		local p = pkg.Plugin(del)
		p:load()
		p:delete()
	end
	local fname
	if install then
		fname = install
	else
		fname = http.formvalue("image")
	end

	if fname and type then
		ret = i18n.translate("plugin_install", "Installing plugin.")
		if type == "tgz" or type == "fon" then
			local verify = require("luci.fon.pkg.verify")
			local str, key, err = verify.fonidentify(tmpfile)
			local uci = require("luci.model.uci").cursor()
			local allow_unsigned = false
			local dev = uci:get("registered", "fonreg", "dev")
			if dev == "1" then
				allow_unsigned = true
			end
			if str ~= "hotfix" and str ~= "plugin" and str ~= "unsigned" then
				ret = "Failed to identify upload."
			else
				local dir, str = verify.fonverify(tmpfile, "/etc/fon/keyring/", allow_unsigned)
				if dir == nil then
					ret = i18n.translate("plugin_verify", "Failed to verify plugin.")
				else
					local res, str = verify.fonupgrade(dir)
					if res == 0 then
						ret = i18n.translate("plugin_installed", "Plugin successfully installed.")
						if redir then
							return http.redirect(redir)
						end
					elseif res == 256 then
						ret = i18n.translate("plugin_already", "Plugin is already installed")
					elseif res == 512 then
						ret = i18n.translate("plugin_no_space", "Not enough space to install plugin.")
					else
						ret = str
					end
				end
			end
		else
			ret = i18n.translate("plugin_format", "No handler for this file")
		end
	end

	local ple = {}

	http.prepare_content("text/html")
	local uci = require("luci.model.uci").cursor_state()
	local templates = {}
	if online then
		local s = require("luci.sys").httpget(feed..pl_file)
		local plf = loadstring(s)
		if plf then
			setfenv(plf, ple)
			plf()
		end
	end
	uci:load("plugfons");
	uci:foreach("plugfons", "plugin", function(section)
		templates[#templates + 1] = { template = "fon_plugin/plugin", params={section=section, priv={ret=ret}, id=#templates}}
	end)
	if online then
		if ple.plugins then
			for i = 1,#ple.plugins, 1 do
				for j = 1,#templates, 1 do
					if ple.plugins[i].name == templates[j].params.section[".name"] and ple.plugins[i].device == device and
						(not(ple.plugins[i].firmware) or (ple.plugins[i].firmware == firmware)) and
						(not(ple.plugins[i].devonly) or (ple.plugins[i].devonly and dev))
					then
						ple.plugins[i].found = 1
						if ple.plugins[i].version > templates[j].params.section.version then
							templates[j].params.section.fon_avail = 1
							templates[j].params.section.fon_version = ple.plugins[i].version
							templates[j].params.section.fon_provider = ple.plugins[i].signature
						end
					end
				end
			end
			for i = 1,#ple.plugins, 1 do
				if ple.plugins[i].found ~= 1 and (dev or ple.plugins[i].signature == "fon") and ple.plugins[i].device == device and
					(not(ple.plugins[i].firmware) or (ple.plugins[i].firmware == firmware)) and
					(not(ple.plugins[i].devonly) or (ple.plugins[i].devonly == "1" and dev))
				then
					 templates[#templates + 1] = { template = "fon_plugin/plugin",
						params={
							section={name=ple.plugins[i].desc,
								realname=ple.plugins[i].name,
								version=ple.plugins[i].version,
								provider=ple.plugins[i].signature,
								link=ple.plugins[i].link,
								size=ple.plugins[i].size or "0",
								install=1},
							id=#templates}
						}
				end
			end
		end
	end
	require("luci.http").prepare_content("text/html")
	local tpl = require("luci.template")
	-- dity dirty dirty, this should be an extra lib
	local fw_version
	local fw_name
	if ple.firmwares then
		for i,v in ipairs(ple.firmwares) do
			if v.latest == "1" and v.firmware > firmware and (dev or v.devonly ~= "1") then
				fw_version = v.firmware
				fw_name = v.name
				local uci = require("luci.model.uci").cursor()
				uci:set("system", "fon", "upgrade", fw_version)
				uci:commit("system")
			end
		end
	end

	tpl.render("fon_plugin/head", {priv={ret=ret,count=#templates,fw=fw_version,name=fw_name,online=online}})

	for i = 1, #templates, 1 do
		tpl.render(templates[i].template, templates[i].params)
	end
	tpl.render("fon_plugin/tail",{priv={ret=ret}})
end

function rpc()
	local sys = require "luci.sys"
	local http = require "luci.http"
	local ltn12   = require "luci.ltn12"
	local jsonrpc = require "luci.jsonrpc_fon"

	local livestats = {}
	livestats.traffic = sys.net.deviceinfo
	livestats.wireless = sys.wifi.getiwconfig
	http.prepare_content("application/json")
	ltn12.pump.all(jsonrpc.handle(livestats, http.source()), http.write)
end
