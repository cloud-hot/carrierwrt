require("luci.tools.webadmin")
local uci = require "luci.model.uci".cursor()

m = Map("fon",
	"Log file",
        "This area shows the most recent log messages emitted by the Fonera and the applications running off it. These log messages are only stored in memory, so older log messages are automatically deleted to make room for newer ones."
)
m:append(Template("fon_debug/log"))

n = Map("system",
	"Settings")
s = n:section(TypedSection, "system")

log_size = s:option(Value, "log_size", "Log buffer size", "Needs a Fonera reboot to take effect")
log_size.default = "64"
for i = 2, 10 do -- minimum size is 4Kib
  local v = math.pow(2, i)
  log_size:value(tostring(v), tostring(v) .. "Kib")
end

-- This stuff didn't work because system is an unnamed section and the
-- @system[0] doesn't seem to be supported by the luci.model.uci
-- library. Still, this approach might be useful when we need to write
-- to other config files later on.
--
-- log_size.default = uci:get("system", "system", "log_size") or "64"
-- function log_size.write(self, section, value)
--   local uci = require "luci.model.uci".cursor()
--   uci:set("system", "system", "log_size", value)
--   uci:save("system")
--   uci:commit("system")
--   return true
-- end

o = Map("fon",
	"USB devices",
        "This area shows detailed output of the connected USB devices (it shows the contents of <tt>/proc/bus/usb/devices</tt>)."
)
o:append(Template("fon_debug/usb"))

return m, n, o
