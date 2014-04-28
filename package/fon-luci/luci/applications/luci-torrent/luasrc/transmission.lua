module("luci.transmission", package.seeall)

local session_id

function init()
	local httpc = require "luci.httpclient"
	local uri = "http://localhost:9091/transmission/rpc/"
	local response, code, msg = httpc.request_to_buffer(uri)
	if not response then
		return false
	end
	session_id = string.sub(response, string.find(response, "<code>") + 33, string.find(response, "</code>") - 1)
	return true
end

function speed_limit(dir, limit)
	if init() == false then
		return
	end
	local httpc = require "luci.httpclient"
	local uri = "http://localhost:9091/transmission/rpc/"
	local body
	if limit then
		body = "{\"method\":\"session-set\",\"arguments\":{\"speed-limit-"..dir.."\":"..limit..",\"speed-limit-"..dir.."-enabled\":true}}"
	else
		body = "{\"method\":\"session-set\",\"arguments\":{\"speed-limit-"..dir.."-enabled\":false}}"
	end
	local options = {
		headers = {
			["X-Transmission-Session-Id"] = session_id,
		},
		body = body
	}
	local response, code, msg = httpc.request_to_buffer(uri, options)
	if not response then
		return 0
	end
	print(response)
end

function get_speed_limit()
	if init() == false then
		return
	end
	local httpc = require "luci.httpclient"
	local uri = "http://localhost:9091/transmission/rpc/"
	local body = "{\"method\":\"session-get\"}"
	local options = {
		headers = {
			["X-Transmission-Session-Id"] = session_id,
		},
		body = body
	}
	local response, code, msg = httpc.request_to_buffer(uri, options)
	if not response then
		return 0
	end
	print(response)
	local ltn12 = require "luci.ltn12"
	local decoder = require "luci.json".Decoder()
	ltn12.pump.all(ltn12.source.string(response), decoder:sink())
	local data = decoder:get()
	return data
end

function issue_cmd(cmd, id)
	if init() == false then
		return
	end
	local httpc = require "luci.httpclient"
	local uri = "http://localhost:9091/transmission/rpc/"
	local options = {
		headers = {
			["X-Transmission-Session-Id"] = session_id,
		},
		body = "{\"method\":\"torrent-"..cmd.."\",\"arguments\":{\"ids\":["..id.."]}}"
	}
	local response, code, msg = httpc.request_to_buffer(uri, options)
	if not response then
		return 0
	end
	print(response)
end

function add_torrent(url)
	if init() == false then
		return
	end
	local httpc = require "luci.httpclient"
	local uri = "http://localhost:9091/transmission/rpc/"
	local options = {
		headers = {
			["X-Transmission-Session-Id"] = session_id,
		},
		body = "{\"method\":\"torrent-add\",\"arguments\":{\"filename\":\""..url.."\"}}"
	}
	local response, code, msg = httpc.request_to_buffer(uri, options)
	if not response then
		return 0
	end
	print(response)
end

function get_list()
	if init() == false then
		return
	end
	local httpc = require "luci.httpclient"
	local uri = "http://localhost:9091/transmission/rpc/"
	local options = {
		headers = {
			["X-Transmission-Session-Id"] = session_id,
		},
		body = "{\"method\":\"torrent-get\",\"arguments\":{\"fields\":[\"id\",\"error\",\"errorString\",\"eta\",\"leftUntilDone\",\"rateDownload\",\"rateUpload\",\"status\",\"name\",\"totalSize\"]}}"
	}
	local response, code, msg = httpc.request_to_buffer(uri, options)
	if not response then
		return 0
	end
	print(response)
	local ltn12 = require "luci.ltn12"
	local decoder = require "luci.json".Decoder()
	ltn12.pump.all(ltn12.source.string(response), decoder:sink())
	local data = decoder:get()
	return data
end
