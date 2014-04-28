require("luci.tools.webadmin")

m = Map("webcam",
	translate("webcam_title", "Webcam Settings"),
	translate("webcam_desc", "Here you can view the attached webcams."))
s = m:section(NamedSection, "webcam", "webcam")
m.pageaction = false
--name = s:option(Value, "name", "Name")

local state = luci.model.uci.cursor_state()
state:load("webcam")
enable = state:get("webcam", "webcam", "connected")
if enable and enable == "true" then
	local port = state:get("webcam", "webcam", "port")
	local daemon = state:get("webcam", "webcam", "daemon")
	if daemon and daemon == "true" then
		local netdata = luci.sys.net.getifconfig()
		x = Template("fon_webcam/main")
		x.ip = netdata["br-lan"] and netdata["br-lan"]["inet addr"] or "N/A"
		x.port = state:get("webcam", "webcam", "port")
		x.name = state:get("webcam", "webcam", "name")
		s:append(x)
	end
else
	s:append(Template("fon_webcam/none"))
end
return m
