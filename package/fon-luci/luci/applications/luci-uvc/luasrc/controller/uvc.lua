module("luci.controller.uvc", package.seeall)

function index()
	entry({"webcam"}, call("webcam"))
end

function webcam()
	local uvc = require("uvc")
	local disposition = luci.http.protocol.content_disposition()

	luci.http.prepare_content("multipart/x-mixed-replace;boundary=------------------------------"..disposition)
	while true do
		luci.http.write("------------------------------"..disposition.."\r\n"..
			"Content-Type: image/jpeg\r\n\r\n")
		luci.http.write(uvc.grab())
		luci.http.write("\r\n")
		require("nixio").nanosleep(0, 100000000)
	end
end
