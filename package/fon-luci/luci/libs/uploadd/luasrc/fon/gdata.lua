module("luci.fon.gdata", package.seeall)

local WAITING = "0"
local LOADING = "1"
local DONE = "2"
local ERROR = "3"
local TOOBIG = "4"

local FON_CLIENT_ID = "ytapi-FonWirelessLTD-LaFonera2-s85hv7t7-0"
local FON_DEVELOPER_KEY = "AI39si7HfohQLa21wOcPy4ytlhpWuPU2aOMbhgnbVmNBN4DtUWZG_tkirqaKGxtcS1outyO5F9fb_FREqIULKIi3IttUNcxMrg"

function adduser(id, user, pass)
	local uci = require("luci.model.uci").cursor()
	uci:set("gdata", id, "user", user)
	uci:set("gdata", id, "pass", pass)
	uci:delete("gdata", id, "fail")
	local srv = require("luci.fon.service")
	local service = srv.Service(id)
	if service then
		service:start()
	end
	uci:commit("gdata")
end

function getuser(id)
	local uci = require("luci.model.uci").cursor()
	local user = uci:get("gdata", id, "user")
	local pass = uci:get("gdata", id, "pass")
	return user, pass
end

function getprivacy(id)
	local uci = require("luci.model.uci").cursor()
	return uci:get("gdata", id, "privacy") ~= "0"
end

function get_auth_token(username, password, service)
	local httpc = require "luci.httpclient"
	local uri
	if service == "youtube" then
		uri = "https://www.google.com/youtube/accounts/ClientLogin"
	else
		uri = "https://www.google.com/accounts/ClientLogin"
	end
	local options = {
		body = {
			Email = username,
			Passwd = password,
			service = service,
			source = "LaFonera20"
		}
	}

	local response, code, msg = httpc.request_to_buffer(uri, options)
	if not response then
		print("Error : "..code)
		return false
	end
	local x, start = string.find(response, "Auth=")
	local token = string.match(response, ".*Auth=(.*)")
	local stop = string.find(token, "\n")
	if stop then
		token = string.sub(token, 1, stop - 1)
	end
	os.execute("logger "..token)
	return token
end

function content_disposition()
	local tmp = ""
	for i = 1,4 do
		tmp = tmp .. (string.format("%02X",math.random(0,255)))
	end
	return tmp
end

function upload_video(filename, mime, uci, section)
	local user, pass = getuser("youtube")
	local auth_token = get_auth_token(user, pass, "youtube")
	if auth_token == false then
		return false, "auth"
	end

	local httpc = require "luci.httpclient"
	local nixio = require "nixio"
	local ltn12 = require "luci.ltn12"
	local fs = require("luci.fs")
	local file = fs.basename(filename)
	local disposition = content_disposition()
	local uri = "http://uploads.gdata.youtube.com/feeds/api/users/default/uploads"
	local xml_block = "<?xml version=\"1.0\"?>\r\n"..
		"<entry xmlns=\"http://www.w3.org/2005/Atom\" xmlns:media=\"http://search.yahoo.com/mrss/\" xmlns:yt=\"http://gdata.youtube.com/schemas/2007\">\r\n"..
		"<media:group>\r\n"..
		"<media:title type=\"plain\">"..file.."</media:title>\r\n"..
		"<media:description type=\"plain\"></media:description>\r\n"..
		"<media:category scheme=\"http://gdata.youtube.com/schemas/2007/categories.cat\">People</media:category>\r\n"..
		"<media:keywords></media:keywords>\r\n"..
		(getprivacy("youtube") and "<yt:private/>\r\n" or "")..
		"</media:group>\r\n"..
		"</entry>"

	local request = "--"..disposition.."\r\n"..
		"Content-Type: application/atom+xml; charset=UTF-8\r\n\r\n"..
		xml_block.."\r\n"..
		"--"..disposition.."\r\n"..
		"Content-Type: "..mime.."\r\n"..
		"Content-Transfer-Encoding: binary\r\n\r\n"

	local footer = "\r\n--"..disposition.."--\r\n"
	local full_size
	local sent_size = 0

	function bodycallback(socket)
		socket:writeall(request)
		local file = nixio.open(filename)
		local sent, code, msg
		repeat
			sent, code, msg = nixio.sendfile(socket, file, 65536)
			sent_size = sent_size + sent
			local perc = math.floor(((sent_size * 100)/ full_size) * 100) / 100
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
			["Authorization"] = "GoogleLogin auth="..auth_token.."",
			["X-GData-Client"] = FON_CLIENT_ID,
			["X-GData-Key"] =  "key="..FON_DEVELOPER_KEY,
			["Slug"] = file,
			["Content-Type"] = "multipart/related; boundary=\""..disposition.."\"",
			["Content-Length"] = #request + #footer + s.size,
		},
		rcvtimeo = 30
	}
	local response, code, msg = httpc.request_to_buffer(uri, options)
	print(response)
	print(code)
	print(msg)
	if code == 400 then
		return false
	end
	return true
end

function picasa_upload_image(filename, mime, uci, section)
	local user, pass = getuser("picasa")
	local auth_token = get_auth_token(user, pass, "lh2")
	if auth_token == false then
		return false, "auth"
	end
	local httpc = require "luci.httpclient"
	local nixio = require "nixio"
	local ltn12 = require "luci.ltn12"
	local fs = require("luci.fs")
	local file = fs.basename(filename)
	local disposition = content_disposition()
	local uri = "http://picasaweb.google.com/data/feed/api/user/default/albumid/default"
	local xml_block = "<entry xmlns='http://www.w3.org/2005/Atom'>\r\n" ..
		"<title>"..file.."</title>\r\n" ..
		"<summary>"..file.."</summary>\r\n" ..
		"<category scheme=\"http://schemas.google.com/g/2005#kind\" term=\"http://schemas.google.com/photos/2007#photo\"/>\r\n"..
		"</entry>"

	local request = "--"..disposition.."\r\n"..
		"Content-Type: application/atom+xml; charset=UTF-8\r\n\r\n"..
		xml_block.."\r\n"..
		"--"..disposition.."\r\n"..
		"Content-Type: "..mime.."\r\n"..
		"Content-Transfer-Encoding: binary\r\n\r\n"

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
			local perc = math.floor(((sent_size * 100)/ full_size) * 100) / 100
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
	full_size = s.size
	if not(s) then
		return false
	end
--	print(auth_token.. ".."..file..".."..mime..".."..s.size)
	local options = {
		body = bodycallback,
		headers = {
			["Authorization"] = "GoogleLogin auth="..auth_token.."",
			["Content-Type"] = "multipart/related; boundary=\""..disposition.."\"",
			["Content-Length"] = #request + #footer + s.size,
		}
	}
	local response, code, msg = httpc.request_to_buffer(uri, options)
	print(response)
	print(code)
	print(msg)
	-- We expect request_to_buffer to fail (response = nil)
	-- because the HTTP code returned is 201 Created (which
	-- request_to_buffer doesn't know about).
	if response or code ~= 201 then
		return false
	end
	return true
end

function youtube_uploaddaemon()
	local uci = require("luci.model.uci").cursor_state()
	local count
	local total = 0
	function uploader_task(s)
		local auth = require("luci.model.uci").cursor_state():get("gdata", "youtube", "fail")
		if auth == "1" then
			return
		end
		if s.status == nil then
			s.status = WAITING
		end
		if s.status ~= WAITING and s.status ~= LOADING then
			return
		end

		local fs = require("luci.fs")
		local stat = fs.stat(s.path .. s.file)
		if not(stat) then
			uci:set("uploadd", s[".name"], "status", ERROR)
			uci:save("uploadd")
			return
		end
		if (stat.size > 2 * 1024 * 1024 * 1024) and s.type == "video" then
			uci:set("uploadd", s[".name"], "status", TOOBIG)
			uci:save("uploadd")
			os.execute("mkdir -p "..s.path.."/done/")
			os.execute("touch \""..s.path.."/done/"..s.file..".done_youtube\"")
			return
		end
		count = count + 1
		if s.file then
			local result
			local err
			local uci = require("luci.model.uci").cursor_state()
			uci:set("uploadd", s[".name"], "status", LOADING)
			uci:save("uploadd")
			require("luci.fon.uploadd").set_state("Youtube")
			local result, err = upload_video(s.path..s.file, s.mime, uci, s[".name"])
			if result == true then
				uci:set("uploadd", s[".name"], "status", DONE)
				uci:save("uploadd")
						else
				if err == "auth" then
					local uci = require("luci.model.uci").cursor()
					uci:set("gdata", "youtube", "fail", "1")
					uci:commit("uploadd")
				else
					uci:set("uploadd", s[".name"], "status", ERROR)
					uci:save("uploadd")
				end
			end
			os.execute("mkdir -p "..s.path.."/done/")
			os.execute("touch \""..s.path.."/done/"..s.file..".done_youtube\"")
			total = total + 1
		end
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

		uci:load("uploadd")
		count = 0
		collectgarbage()
		uci:foreach("uploadd", "youtube", uploader_task)
	until count == 0
	return total
end

function picasa_uploaddaemon()
	local uci = require("luci.model.uci").cursor_state()
	local count
	local total = 0
	function uploader_task(s)
		local auth = require("luci.model.uci").cursor_state():get("gdata", "picasa", "fail")
		if auth == "1" then
			return
		end
		if s.status == nil then
			s.status = WAITING
		end
		if s.status ~= WAITING and s.status ~= LOADING then
			return
		end

		local fs = require("luci.fs")
		local stat = fs.stat(s.path..s.file)
		if not(stat) then
			uci:set("uploadd", s[".name"], "status", ERROR)
			uci:save("uploadd")
			return
		end
		if ((stat.size > 10 * 1024 * 1024) and s.type == "picture")
			or ((stat.size > 50 * 1024 * 1024) and s.type == "video") then
			uci:set("uploadd", s[".name"], status, TOOBIG)
			uci:save("uploadd")
			os.execute("mkdir -p "..s.path.."/done/")
			os.execute("touch \""..s.path.."/done/"..s.file..".done_picasa\"")
			return
		end
		count = count + 1
		if s.file then
			local result
			local err
			local uci = require("luci.model.uci").cursor_state()
			uci:set("uploadd", s[".name"], "status", LOADING)
			uci:save("uploadd")
			require("luci.fon.uploadd").set_state("Picasa")
			local result, err = picasa_upload_image(s.path..s.file, s.mime, uci, s[".name"])
			if result == true then
				uci:set("uploadd", s[".name"], "status", DONE)
				uci:save("uploadd")
			else
				if err == "auth" then
					local uci = require("luci.model.uci").cursor()
					uci:set("gdata", "picasa", "fail", "1")
					uci:commit("gdata")
				else
					uci:set("uploadd", s[".name"], "status", ERROR)
					uci:save("uploadd")
				end
			end
			os.execute("mkdir -p "..s.path.."/done/")
			os.execute("touch \""..s.path.."/done/"..s.file..".done_picasa\"")
			total = total + 1
		end
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

		uci:load("uploadd")
		count = 0
		collectgarbage()
		uci:foreach("uploadd", "picasa", uploader_task)
	until count == 0
	return total
end
