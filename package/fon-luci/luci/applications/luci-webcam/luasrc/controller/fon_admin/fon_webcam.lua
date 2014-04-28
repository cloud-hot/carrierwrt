module("luci.controller.fon_admin.fon_webcam", package.seeall)

function index()
	require("luci.i18n")

	local page  = node("fon_devices", "fon_webcam")
	page.target = cbi("fon_webcam/main")
	page.title  = luci.i18n.translate("webcam", "Webcam")
	page.order  = 150
	page.page_icon  = "/icons/webcam_on.png"
	page.fon_status = function()
		local ico = luci.config.main.mediaurlbase.."/icons/webcam_%s.png"
		local cfg = {"webcam", "webcam", "connected"}
		local uci = require "luci.model.uci".cursor_state()
		local val = uci:get(unpack(cfg))
		local icon = ico % ((not val or val ~= "true") and "off" or "on")
		return {icon=icon}
	end

	page.fon_reload = function()
		local cfg = {"webcam", "webcam", "daemon"}
		local uci = require "luci.model.uci".cursor_state()
		local val = uci:get(unpack(cfg))
		local reload = ((not val or val ~= "true") and "0" or "1")
		return {reload=reload}
	end

	page.icon_select = function()
		local u = luci.model.uci.cursor_state()
		local c = u:get("webcam", "webcam", "connected")
		if c and c == "true" then
			return "icons/webcam_on.png"
		else
			return "icons/webcam_off.png"
		end
	end

	local page  = node("fon_devices", "fon_webcam", "big")
	page.target = cbi("fon_webcam/big")
	page.title  = luci.i18n.translate("webcam", "Webcam")
	page.page_icon  = "/icons/webcam_on.png"

	entry({"fon_devices", "fon_webcam", "mjpeg"}, call("mjpeg"), "Webcam")
end

function mjpeg()
	local uvc = require("uvc")
	local disposition = luci.http.protocol.content_disposition()

	luci.http.prepare_content("multipart/x-mixed-replace;boundary=------------------------------"..disposition)
	while true do
		local u = uvc.grab()
		if u ~= false and u then
			luci.http.write("------------------------------"..disposition.."\r\n"..
				"Content-Type: image/jpeg\r\n\r\n")
			luci.http.write(uvc.grab())
			luci.http.write("\r\n")
		end
	end
end
