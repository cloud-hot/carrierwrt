--[[
LuCI - Lua Configuration Interface

Copyright 2009 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local req, ipairs, unpack = require, ipairs, unpack

-- Controller name
module "luci.controller.music"

-- The index function contains entries to be attached to the dispatching tree
function index()
	require("luci.i18n")
	luci.i18n.loadc("music")

	local page  = node("fon_devices", "fon_music")
	page.target = call("audioplayer")
	page.title  = luci.i18n.translate("music_title")
	page.order  = 110
	page.i18n = "music" -- Autoload i18n-file "music"
	page.css = {"music.css"} -- Custom CSS
	page.icon = "music.png"
	page.page_icon = "music.png"
	page.icon_path = "/luci-static/resources/"

	-- If the user requests /luci/music, call the function "audioplayer"
	local page = entry({"music"}, call("audioplayer"), luci.i18n.translate("music_title"))
	page.i18n = "music" -- Autoload i18n-file "music"
	page.css = {"music.css"} -- Custom CSS
	page.page_icon = "music.png"
	page.icon_path = "/luci-static/resources/"
	-- Auxiliary page that will be used to refresh with XHR
	entry({"music", "_player"}, call("playerxhr"))

	-- Radio station bookmarking editor
	local page = entry({"music", "radio"}, cbi("music-radio", {on_success_to={"music"}}), luci.i18n.translate("music_stations"))
	page.css = {"music.css"} -- Custom CSS
	page.page_icon = "music.png"
	page.icon_path = "/luci-static/resources/"

	-- Radio station bookmarking list
	entry({"music", "_radio"}, call("radiobookmark"))
end


local require = req

-- Temporary M3U list
local tmpm3u = "/tmp/myplaylist.m3u"

-- Radio bookmark list
function radiobookmark()
	local tpl = require "luci.template"
	local cursor = require "luci.model.uci".cursor()
	local radios = {}
	cursor:foreach("audiod", "radiostation", function(s)
		radios[#radios+1] = s
	end)
	tpl.render("music/radio-edit", {radios=radios})
end

-- Shoutcast client
local function shoutcast(url)
	local os = require "os"
	local fs = require "luci.fs"
	local i18n = require "luci.i18n"
	local nixio = require "nixio"
	local posix = require "posix"
	local radiocli = require "luci.radiocli"
	local scpipe = "/tmp/shoutcast.mp3"
	local state = require "luci.model.uci".cursor_state()
	local controller = nixio.getpid()
	local meta = {}
	local csocket = nixio.connect("127.0.0.1", 15052)

	-- Stop audiod
	csocket:writeall("STOP\n")

	-- Make sure that any still listening radiocli process will receive SIGPIPE
	local pipefd = nixio.open(scpipe, nixio.open_flags("rdonly", "nonblock"))
	if pipefd then
		pipefd:close()
	end

	-- Create a FIFO
	fs.unlink(scpipe)
	posix.mkfifo(scpipe)

	-- Metadata callback
	local function sc_metacb(type, data)
		if type == "scheaders" then
			local ct = data["Content-Type"] or data["content-type"]
			if ct ~= "audio/mpeg" then
				return nil, -2, i18n.translate("music_invalidstr")
			end
			local stat, code, msg = nixio.fork()		-- Fork shoutcast client
			if not stat then
				return nil, code, msg
			elseif stat == 0 then
				meta.album = data["icy-name"] or ""
				nixio.signal(13, "ign")					-- Ignore SIGPIPE
				return true
			else
				return false
			end
		elseif type == "scmeta" then
			meta.title = data.StreamTitle
			local sbeg, send = meta.title:find(" - ", 1, true)
			if sbeg then
				meta.artist = meta.title:sub(1, sbeg - 1)
				meta.title = meta.title:sub(send + 1)
			end
			state:tset("audiod", "audiod", meta)
			state:save("audiod")
			return true
		end
	end

	-- Create streaming client
	local stat, code, msg = radiocli.splice_to_file(url, scpipe, sc_metacb)

	-- If everything worked well, we will have to control flows here
	if controller ~= nixio.getpid() then
		-- This is the shoutcast client, exit it.
		fs.unlink(scpipe)
		os.exit(0)
	end

	if stat == false then
		stat = true

		-- Write temp playlist
		fs.writefile(tmpm3u, scpipe)
		if nixio.fork() == 0 then
			-- Wait a few seconds before starting the audiodaemon
			nixio.nanosleep(3)
			-- Set the mode to normal (instead of repeat),
			-- to prevent audiod from looping over the same
			-- radio station over and over again, if the
			-- stream breaks up.
			csocket:writeall("LIST|" .. tmpm3u .. "|\nMODE|NORMAL|\nSTART\n")
			os.exit(0)
		end
	end

	csocket:close()
	return stat, code, msg
end

-- General Radio playing
local function radio(uri)
	local table = require "table"
	local httpc = require "luci.httpclient"
	local ltn12 = require "luci.ltn12"
	local i18n = require "luci.i18n"

	-- Load URI
	local stat, response, buffer, sock = httpc.request_raw(uri)
	if not stat then
		return nil, response, buffer
	elseif stat ~= 200 then
		return nil, stat, response.status
	end

	-- This seems to be a shoutcast URI, play the stream
	local ct = response.headers["Content-Type"] or response.headers["content-type"]
	if ct == "audio/mpeg" then
		sock:close()
		return shoutcast(uri)
	end

	local src
	-- Decode stream if necessary
	if response.headers["Transfer-Encoding"] == "chunked" then
		src = httpc.chunksource(sock, buffer)
	else
		src = ltn12.source.cat(ltn12.source.string(buffer), sock:blocksource())
	end

	-- Read the content into a buffer, but not much
	local outtbl, read, chunk = {}, 0
	repeat
		chunk = src()
		if chunk then
			outtbl[#outtbl+1] = chunk
			read = read + #chunk
		end
	until not chunk or read > 1024
	sock:close()

	local playlist = table.concat(outtbl)
	local stat, code, err = nil, -1, i18n.translate("music_invalidpl")

	-- Now grep for URIs and test them with the radiocli
	for uri in playlist:gmatch("http://[^%c <\"']+") do
		stat, code, err = shoutcast(uri)
		if stat then
			return true
		end
	end

	return nil, code, err
end

-- Main player function
local function player(template)
	-- Filesystem functions
	local fs = require "luci.fs"
	-- Template functions
	local tpl = require "luci.template"

	if fs.stat("/sys/class/sound/card0/") == nil then
		 tpl.render("music/none")
		 return
	end

	local err

	-- Table functions
	local table = require "table"
	-- HTTP functions
	local http = require "luci.http"
	-- Open UCI state cursor
	local state = require "luci.model.uci".cursor_state()
	-- Control Socket
	require "nixio.util"
	local csocket = require "nixio".connect("127.0.0.1", 15052)

	-- If we can't connect to audiod, it's probably not running.
	-- Tell the user instead of throwing a traceback at them.
	if not csocket then
		 tpl.render("music/notrunning")
		 return
	end

	-- M3U-Play request?
	local m3u = http.formvalue("m3u")
	if m3u then
		fs.unlink(tmpm3u)
		csocket:writeall("STOP\nLIST|"..m3u:gsub("[|\n]", "").."|\nMODE|REPEAT|\nSTART\n")
	end

	-- MP3-Play request?
	local mp3 = http.formvalue("mp3")
	if mp3 then
		fs.writefile(tmpm3u, mp3)
		csocket:writeall("STOP\nLIST|"..tmpm3u.."|\nMODE|REPEAT|\nSTART\n")
	end

	-- Play folder request?
	local dir = http.formvalue("dir")
	if dir then
		local files = fs.glob(dir .. "/*.mp3")
		if files then
			fs.writefile(tmpm3u, table.concat(files, "\n"))
			csocket:writeall("STOP\nLIST|"..tmpm3u.."|\nMODE|REPEAT|\nSTART\n")
		end
	end

	-- Another action requested?
	local action = http.formvalue("action")
	if action then
		local value = http.formvalue("value")
		if value then
			csocket:writeall(action:match("([%w]+)"):upper() .. "|" .. value:gsub("[|\n]", "") .. "|\n")
		else
			csocket:writeall(action:match("([%w]+)"):upper() .. "\n")
		end
	end

	-- Radio-Play request?
	local rd = http.formvalue("radio")
	if rd then
		local stat, code, msg = radio(rd)
		if not stat then
			err = msg
		end
	end

	-- Shoutcast-Play request?
	local sc = http.formvalue("sc")
	if sc then
		local stat, code, msg = shoutcast(sc)
		if not stat then
			err = msg
		end
	end

	-- Render view/music/player.htm
	tpl.render(template, {status=state:get_all("audiod", "audiod"), err=err})
end


-- This will be executed when the user requests /luci/music, see index()
function audioplayer()
	player("music/player")
end

-- This will be executed for XHR reloads
function playerxhr()
	player("music/player-status")
end

