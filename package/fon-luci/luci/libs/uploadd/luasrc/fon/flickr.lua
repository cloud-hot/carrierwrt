-- (c) john@phrozen.org gplv2

module("luci.fon.flickr", package.seeall)

require "nixio.util"

local WAITING = "0"
local LOADING = "1"
local DONE = "2"
local ERROR = "3"
local TOOBIG = "4"

local uci = require("luci.model.uci").cursor()
local flickr = require("flickr")

local api_key = uci:get("flickr", "flickr", "api_key")
local auth_token = uci:get("flickr", "flickr", "auth_token")

function content_disposition()
	local tmp = ""
	for i = 1,6 do
		tmp = tmp .. (string.format("%02X",math.random(0,255)))
	end
	return tmp
end

function upload_a_pic(filename, mime, uci, section)
	local httpc = require "luci.httpclient"
	local nixio = require "nixio"
	local ltn12 = require "luci.ltn12"
	local fs = require("luci.fs")
	local file = fs.basename(filename)
	local disposition = content_disposition()
	local uri = "http://api.flickr.com/services/upload/"
	local privacy = ((uci:get("flickr", "flickr", "privacy") == "0") and "1" or "0")
	local sig = flickr.sign("api_key"..api_key.."auth_token"..auth_token.."content_type1is_family"..privacy.."is_friend"..privacy.."is_public"..privacy.."safety_level1")

	local request = "------------------------------"..disposition.."\r\n"..
		"Content-Disposition: form-data; name=\"api_key\"\r\n\r\n"..
		api_key.."\r\n"..
		"------------------------------"..disposition.."\r\n"..
		"Content-Disposition: form-data; name=\"auth_token\"\r\n\r\n"..
		auth_token.."\r\n"..
		"------------------------------"..disposition.."\r\n"..
		"Content-Disposition: form-data; name=\"content_type\"\r\n\r\n"..
		"1\r\n"..
		"------------------------------"..disposition.."\r\n"..
		"Content-Disposition: form-data; name=\"is_family\"\r\n\r\n"..
		privacy.."\r\n"..
		"------------------------------"..disposition.."\r\n"..
		"Content-Disposition: form-data; name=\"is_friend\"\r\n\r\n"..
		privacy.."\r\n"..
		"------------------------------"..disposition.."\r\n"..
		"Content-Disposition: form-data; name=\"is_public\"\r\n\r\n"..
		privacy.."\r\n"..
		"------------------------------"..disposition.."\r\n"..
		"Content-Disposition: form-data; name=\"safety_level\"\r\n\r\n"..
		"1\r\n"..
		"------------------------------"..disposition.."\r\n"..
		"Content-Disposition: form-data; name=\"api_sig\"\r\n\r\n"..
		sig.."\r\n"..
		"------------------------------"..disposition.."\r\n"..
		"Content-Disposition: form-data; name=\"photo\"; filename=\""..file.."\"\r\n"..
		"Content-Type: "..mime.."\r\n\r\n"

	local footer = "\r\n------------------------------"..disposition.."--\r\n"

	local full_size
    local sent_size = 0

	local function bodycallback(socket)
		socket:writeall(request)
		local file = nixio.open(filename)
		local sent, code, msg
		repeat
			sent, code, msg = nixio.sendfile(socket, file, 65536)
			sent_size = sent_size + sent
			local perc = math.floor((sent_size * 1000)/ full_size) / 10
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
			["Content-Type"] = "multipart/form-data; boundary=----------------------------"..disposition.."",
			["Content-Length"] = #request + #footer + s.size,
		},
		rcvtimeo = 30
	}

	local response, code, msg = httpc.request_to_buffer(uri, options)
	if not response then
		print("Error : "..code)
		return false
	end
	print(response)
	local ok = string.find(response, "<rsp stat=\"ok\">")
	if ok == nil then
		print("Error : Flickr did not like the file ?!")
		return false
	end

	return true
end

function create_album(name, pid)
	local httpc = require "luci.httpclient"
	local uri = "http://api.flickr.com/services/rest/"

	local sig = flickr.sign("api_key"..api_key.."title"..name.."description"..name.."primary_photo_id"..pid.."methodflickr.photosets.create")
	local options = {
		body = {
			api_key = api_key,
			title = name,
			description = name,
			primary_photo_id = pid,
			method = "flickr.photosets.create",
			sig = sig
		}
	}

	local response, code, msg = httpc.request_to_buffer(uri, options)
	if not response then
		return nil
	end
	print(response)
	return
end


function frob2auth(frob)
	frob = string.match(frob, "([0-9][0-9][0-9][\-][0-9][0-9][0-9][\-][0-9][0-9][0-9]).*")
	if not(frob) then
		return false
	end
	local httpc = require "luci.httpclient"
	local uri = "http://www.flickr.com/services/rest/"
	local sig = flickr.sign("api_key"..api_key.."methodflickr.auth.getFullTokenmini_token"..frob)
	local query = "api_key="..api_key.."&method=flickr.auth.getFullToken&mini_token="..frob.."&api_sig="..sig

	local response, code, msg = httpc.request_to_buffer(uri.."?"..query)

	if not response then
		print("Error : "..code)
		return false
	end
	print(response)
	local ok = string.find(response, "<rsp stat=\"ok\">")
	if ok == nil then
		print("Error : Flickr did not like the frob ?!")
		return false
	end
	local d, start = string.find(response, "<token>")
	local stop, d = string.find(response, "</token>")
	if start and stop then
		uci:set("flickr", "flickr", "auth_token", string.sub(response, start + 1, stop - 1))
		uci:commit("flickr")
		return true
	end
	return false
end

function flickr_uploader()
	local uci2 = require("luci.model.uci").cursor_state()

	local count
	local total = 0
	function flickr_task(s)
		local uci = require("luci.model.uci").cursor_state()
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
		uci:set("uploadd", s[".name"], "status", LOADING)
		uci:save("uploadd")
		count = count + 1
		if ((stat.size > 20 * 1024 * 1024) and (s.type == "picture")) or ((stat.size > 500 * 1024 * 1024) and (s.type == "video")) then
			uci:set("uploadd", s[".name"], "status", TOOBIG)
			uci:save("uploadd")
			os.execute("mkdir -p "..s.path.."/done/")
            os.execute("touch \""..s.path.."/done/"..s.file..".done_youtube\"")
		else
			require("luci.fon.uploadd").set_state("Flickr")
			local u = upload_a_pic(s.path..s.file, s.mime, uci, s[".name"])
			if u == true then
				print("uploaded "..s.type.." "..s.path..s.file)
				uci:set("uploadd", s[".name"], "status", DONE)
				uci:save("uploadd")
			else
				print("uploaded "..s.type.." -failed "..s.file)
				uci:set("uploadd", s[".name"], "status", ERROR)
				uci:save("uploadd")
			end
		end
		os.execute("mkdir -p "..s.path.."/done/")
		os.execute("touch \""..s.path.."/done/"..s.file..".done_flickr\"")
		total = total + 1
	end
	if not(auth_token) then
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
		uci2:foreach("uploadd", "flickr", flickr_task)
	until count == 0
	return total
end
