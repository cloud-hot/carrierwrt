module("luci.fon.uploadd", package.seeall)

local i18n = require("luci.i18n")
local count = 0

function clear_state()
	local u = require("luci.model.uci").cursor_state()
	u:load("uploadd")
	u:delete("uploadd", "uploadd", "service")
	u:save("uploadd")
end

function set_state(s)
	local u = require("luci.model.uci").cursor_state()
	u:load("uploadd")
	u:set("uploadd", "uploadd", "service", s)
	u:save("uploadd")
end

function set_privacy(s, t)
	local uci = require("luci.model.uci").cursor_state()
	if s == "youtube" or s == "picasa" then
		uci:load("gdata")
		uci:set("gdata", s, "privacy", t)
		uci:commit("gdata")
	else
		uci:load(s)
		uci:set(s, s, "privacy", t)
		uci:commit(s)
	end
end

function get_privacy(s)
	local uci = require("luci.model.uci").cursor_state()
	if s == "youtube" or s == "picasa" then
		local p = uci:get("gdata", s, "privacy") or "1"
		return p
	else
		return uci:get(s, s, "privacy") or "1"
	end
end

function get_state()
	local u = require("luci.model.uci").cursor_state()
	return (u:get("uploadd", "uploadd", "service") or "")
end

function finish_event(count, service, msg)
	if count > 0 then
		local t = require("luci.twitter")
		t.tweet(msg .." ("..count..")", service)
	end
end

function start_youtube()
	local u = require("luci.model.uci").cursor():get("gdata", "youtube", "user")
	if u and #u > 3 then
		local g = require("luci.fon.gdata")
		local r = g.youtube_uploaddaemon()
		count = count + r
		finish_event(r, "youtube", i18n.translate("youtube_finished", "Uploaded new files to YouTube"))
		clear_state()
	end
end

function start_picasa()
	local u = require("luci.model.uci").cursor():get("gdata", "picasa", "user")
	if u and #u > 3 then
		local g = require("luci.fon.gdata")
		local r = g.picasa_uploaddaemon()
		count = count + r
		finish_event(r, "picasa", i18n.translate("picasa_finished", "Uploaded new files to Picasa"))
		clear_state()
	end
end

function start_facebook()
	local u = require("luci.model.uci").cursor():get("facebook", "facebook", "secret")
	if u and #u > 1 then
		local f = require("luci.fon.facebook")
		local r = f.facebook_uploader()
		count = count + r
		finish_event(r, "facebook", i18n.translate("facebook_finished", "Uploaded new files to Facebook"))
		clear_state()
	end
end

function start_flickr()
	local u = require("luci.model.uci").cursor():get("flickr", "flickr", "auth_token")
	if u and #u > 1 then
		local f = require("luci.fon.flickr")
		local r = f.flickr_uploader()
		count = count + r
		finish_event(r, "flickr", i18n.translate("flickr_finished", "Uploaded new files to Flickr"))
		clear_state()
	end
end

function run()
	local luanet = require("luanet");
	while true do
		local online = require("luci.model.uci").cursor_state():get("fon", "state", "online")
		if online == "1" then
			local fs = require("luci.fs")
			local stat = fs.stat("/var/state/uploadd")
			if stat and stat.size > 0 then
				start_youtube()
				start_flickr()
				start_picasa()
				start_facebook()
			end
		end
		if count == 0 then
			return
		end
		luanet.sleep(30);
		count = 0
		collectgarbage("collect")
	end
end

function flush_queue(service)
	local uci = require("luci.model.uci").cursor_state()
	function flush_task(s)
		if (s.status and tonumber(s.status) < 2) or not(s.status) then
			return
		end
		local uci = require("luci.model.uci").cursor_state()
		uci:load("upload")
		uci:delete("uploadd", s[".name"])
		uci:delete("uploadd", s.ref)
		uci:save("uploadd")
	end

	uci:load("uploadd")
	uci:foreach("uploadd", service, flush_task)
end

function add_queue(s, file)
	local uci = require("luci.model.uci").cursor_state()
	local id = uci:get("uploadd", "uploadd", "id") or 65335
	local fs = require("luci.fs")
	id = id + 1
	uci:set("uploadd", "uploadd", "id", id)
	local ext = fs.basename(file):match("%.([%w]+)$")
	local mime = (ext and uci:get("fon_browser", "mime", ext)) or "unknown"
	local t
	if mime:find("video") then
		t = "video"
	else
		t = "picture"
	end
	local stat = fs.stat(file)
	local ref = file:gsub("-","_"):gsub("%.", "_"):gsub("/", "_")..s
	uci:section("uploadd", s, "u"..id, {
			type=t,path=luci.fs.dirname(file).."/",file=luci.fs.basename(file),type=t,mime=mime,ref=ref})
	uci:section("uploadd", "file", ref, {exists=1})
	uci:save("uploadd")
	require("luci.fon.event").new("StartUploadd")
end
