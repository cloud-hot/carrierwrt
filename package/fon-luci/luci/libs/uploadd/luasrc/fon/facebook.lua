-- (c) john@phrozen.org gplv2

module("luci.fon.facebook", package.seeall)

require "nixio.util"

local WAITING = "0"
local LOADING = "1"
local DONE = "2"
local ERROR = "3"
local TOOBIG = "4"

local uci = require("luci.model.uci").cursor()
local facebook = require("facebook")

function content_disposition()
	local tmp = ""
	for i = 1,6 do
		tmp = tmp .. (string.format("%02X",math.random(0,255)))
	end
	return tmp
end

local APIKEY = uci:get("facebook", "facebook", "api_key")

function get_api_key()
	return APIKEY
end

function get_session()
	return uci:get("facebook", "facebook", "session_key"), uci:get("facebook", "facebook", "secret"), uci:get("facebook", "facebook", "uid")
end

function find_fon_album(album)
	local httpc = require "luci.httpclient"
	local uri = "http://api.facebook.com/restserver.php"
	local callid = os.time()
	local session_key, session_secret, session_uid = get_session()
	local request = "api_key="..APIKEY.."callid="..callid.."format=jsonmethod=Photos.getAlbumssession_key="..session_key.."uid="..session_uid.."v=1.0"
	local facebook = require("facebook")
	local sig = facebook.sign_session(request, session_secret)
	local options = {
		body = {
			api_key = APIKEY,
			callid = callid,
			format = "json",
			method = "Photos.getAlbums",
			session_key = session_key,
			uid = session_uid,
			v = "1.0",
			sig = sig
		}
	}

	local response, code, msg = httpc.request_to_buffer(uri, options)
	if not response then
		return nil
	end
	print(response)
	local ltn12 = require "luci.ltn12"
	local decoder = require "luci.json".Decoder()
	ltn12.pump.all(ltn12.source.string(response), decoder:sink())
	local data = decoder:get()
	if data then
		for i,v in ipairs(data) do
			if v.name == album then
				return v.aid
			end
		end
	end
	return false
end

function create_fon_album(album)
	local aid = find_fon_album(album)
	if aid then
		return aid
	end
	local httpc = require "luci.httpclient"
	local uri = "http://api.facebook.com/restserver.php"
	local callid = os.time()
	local session_key, session_secret = get_session()
	local request = "api_key="..APIKEY.."callid="..callid.."format=jsonmethod=Photos.createAlbumname="..album.."session_key="..session_key.."v=1.0"
	local facebook = require("facebook")
	local sig = facebook.sign_session(request, session_secret)
	local options = {
		body = {
			api_key = APIKEY,
			callid = callid,
			format = "json",
			method = "Photos.createAlbum",
			name = album,
			session_key = session_key,
			v = "1.0",
			sig = sig
		}
	}

	local response, code, msg = httpc.request_to_buffer(uri, options)
	if not response then
		return nil
	end
	print(response)
	local ltn12 = require "luci.ltn12"
	local decoder = require "luci.json".Decoder()
	ltn12.pump.all(ltn12.source.string(response), decoder:sink())
	local data = decoder:get()
	return data.aid
end

function get_auth_token()
	local httpc = require "luci.httpclient"
	local uri = "https://api.facebook.com/restserver.php"
	local request = "api_key="..APIKEY.."format=jsonmethod=Auth.createTokenv=1.0"
	local facebook = require("facebook")
	local sig = facebook.sign(request)

	local options = {
		body = {
			v = "1.0",
			format = "json",
			api_key = APIKEY,
			method = "Auth.createToken",
			sig = sig
		}
	}
	local response, code, msg = httpc.request_to_buffer(uri, options)
	if not response then
		return nil
	end
	token = string.match(response, "^\"([0-9a-zA-Z]*)\".*")
	if not(token) or #token > 32 then
		token = nil
	end
	return token
end

function get_session_token(auth_token)
	local httpc = require "luci.httpclient"
	local uri = "https://api.facebook.com/restserver.php"
	local request = "api_key="..APIKEY.."auth_token="..auth_token.."format=jsonmethod=Auth.getSessionv=1.0"
	local facebook = require("facebook")
	local sig = facebook.sign(request)
	local options = {
		body = {
			api_key = APIKEY,
			auth_token = auth_token,
			v = "1.0",
			method = "Auth.getSession",
			format = "json",
			sig = sig
		}
	}

	local response, code, msg = httpc.request_to_buffer(uri, options)
	if not response then
		return nil
	end
	local ltn12 = require "luci.ltn12"
	local decoder = require "luci.json".Decoder()
	ltn12.pump.all(ltn12.source.string(response), decoder:sink())
	local data = decoder:get()
	-- Use string.format to convert the uid, since it can be very
	-- big, causing lua's default string conversion to use
	-- scientific notation...
	return data.session_key, data.secret, data.expires, data.uid and string.format("%.0f", data.uid) or nil
end

function upload_a_pic(filename, aid, mime, uci, section)
	local nixio = require "nixio"
	local ltn12 = require "luci.ltn12"
	local fs = require("luci.fs")
	local httpc = require "luci.httpclient"
	local uri = "http://api.facebook.com/restserver.php"
	local callid = os.time()
	local session_key, session_secret = get_session()
	local request = "api_key="..APIKEY.."callid="..callid.."format=jsonmethod=Photos.uploadsession_key="..session_key.."v=1.0"
	if aid then
		request = "aid="..aid..request
	end
	local facebook = require("facebook")
	local sig = facebook.sign_session(request, session_secret)
	local file = fs.basename(filename)
	local disposition = content_disposition()
	local disp = "--"..disposition.."\r\n"

	local request = "--"..disposition.."\r\n"..
		"Content-Disposition: form-data; name=\"api_key\"\r\n\r\n"..
		APIKEY.."\r\n"..
		"--"..disposition.."\r\n"..
		"Content-Disposition: form-data; name=\"callid\"\r\n\r\n"..
		callid.."\r\n"..
		"--"..disposition.."\r\n"..
		"Content-Disposition: form-data; name=\"format\"\r\n\r\n"..
		"json\r\n"..
		"--"..disposition.."\r\n"..
		"Content-Disposition: form-data; name=\"method\"\r\n\r\n"..
		"Photos.upload\r\n"..
		"--"..disposition.."\r\n"..
		"Content-Disposition: form-data; name=\"session_key\"\r\n\r\n"..
		session_key.."\r\n"..
		"--"..disposition.."\r\n"..
		"Content-Disposition: form-data; name=\"v\"\r\n\r\n"..
		"1.0\r\n"..
		"--"..disposition.."\r\n"..
		"Content-Disposition: form-data; name=\"sig\"\r\n\r\n"..
		sig.."\r\n"..
		"--"..disposition.."\r\n"..
		"Content-Disposition: form-data; filename=\""..file.."\"\r\n"..
		"Content-Type: "..mime.."\r\n\r\n"

	if aid then
		request = "--"..disposition.."\r\n"..
		"Content-Disposition: form-data; name=\"aid\"\r\n\r\n"..
        aid.."\r\n"..request
	end

	local footer = "\r\n--"..disposition.."--\r\n"
	local full_size
	local sent_size = 0
	local function bodycallback(socket)
		socket:writeall(request)
		local file = nixio.open(filename)
		local sent, code, msg
		repeat
			sent, code, msg = nixio.sendfile(socket, file, 65536)
			sent_size = sent_size + sent
			local perc = (sent_size * 100)/ full_size
			perc = math.floor(perc * 10)/10
			uci:revert("uploadd", section, "progress")
			uci:set("uploadd", section, "progress", perc)
			uci:save("uploadd")
		until not sent or sent == 0
		if not sent then
			return nil, code, msg
		end
		socket:writeall(footer)
		return true
	end

	local s = fs.stat(filename)
	if not(s) then
		return false
	end
	full_size = s.size
	local options = {
		body = bodycallback,
		headers = {
			["Content-Type"] = "multipart/form-data; boundary="..disposition,
			["Content-Length"] = #request + #footer + s.size,
		},
		rcvtimeo = 30
	}

	local response, code, msg = httpc.request_to_buffer(uri, options)
	print(response)

	if not response then
		return false
	end
	local ltn12 = require "luci.ltn12"
	local decoder = require "luci.json".Decoder()
	ltn12.pump.all(ltn12.source.string(response), decoder:sink())
	local data = decoder:get()
	if data.pid then
		return true
	end
	return false, data.error_code
end

function facebook_uploader()
	local uci2 = require("luci.model.uci").cursor_state()

	local count
	local total = 0
	local done = false
	local fail = false
	local aid
	function facebook_task(s)
		if done or s.status == ERROR or s.status == TOOBIG or s.status == DONE or fail then
			return
		end
		local uci = require("luci.model.uci").cursor_state()
		if aid == nil then
			aid = create_fon_album((uci:get("facebook", "facebook", "album") or "FON").."_"..os.time())
		end
		local fs = require("luci.fs")
		local stat = fs.stat(s.path .. s.file)
		if not(stat) then
			uci:set("uploadd", s[".name"], "status", ERROR)
			uci:save("uploadd")
			return
		end
		if stat.size > 10 * 1024 * 1024 then
			uci:set("uploadd", s[".name"], "status", TOOBIG)
			uci:save("uploadd")
			os.execute("mkdir -p "..s.path.."/done/")
			os.execute("touch \""..s.path.."/done/"..s.file..".done_facebook\"")
			return
		end
		uci:set("uploadd", s[".name"], "status", LOADING)
		uci:save("uploadd")
		count = count + 1
		print("starting upload")
		require("luci.fon.uploadd").set_state("Facebook")
		local u, e = upload_a_pic(s.path .. s.file, aid, s.mime, uci, s[".name"])
		if u == true then
			print("uploaded "..s.type.." "..s.file)
			uci:set("uploadd", s[".name"], "status", DONE)
			uci:save("uploadd")
		else
			if e == 321 then
				aid = create_fon_album((uci:get("facebook", "facebook", "album") or "FON").."_"..os.time())
			else
				print("uploaded "..s.type.." failed "..s.file)
				uci:set("uploadd", s[".name"], "status", ERROR)
				uci:save("uploadd")
				done = true
			end
		end
		os.execute("mkdir -p "..s.path.."/done/")
		os.execute("touch \""..s.path.."/done/"..s.file..".done_facebook\"")
		total = total + 1
	end
	local session_key, session_secret = get_session()
	if not(session_key) then
		return 0
	end
	local luanet = require("luanet")
	repeat
		local online
		repeat
			online = require("luci.model.uci").cursor_state():get("fon", "state", "online")
			if online ~= "1" then
				luanet.sleep(1);
			end
		until online == "1"
		collectgarbage()
		uci2:load("uploadd")
		count = 0
		done = false
		uci2:foreach("uploadd", "facebook", facebook_task)
	until count == 0
	return total
end
