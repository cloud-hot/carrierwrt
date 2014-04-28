-- Copyright 2008 John Crispin <john@phrozen.org>

require("luci.tools.webadmin")
local uci = luci.model.uci.cursor()

m = Map("fonbackup", "Fonbackup", translate("fb_desc", "Fonbackup turns your USB-harddisk into a powerful backup device"))
m.done_btn = true
s = m:section(NamedSection, "fonbackup", "fonbackup")
--s:option(DummyValue, "cnt", translate("fb_sessions", "Backup Sessions"))
lastcl = s:option(DummyValue, "_lcl", translate("fb_lastsess", "Last Session"))
function lastcl.value()
	local time = tonumber(m:get("fonbackup", "lastclts"))
	local clip = m:get("fonbackup", "lastclip") or "n/a"
	if not time then
		return translate("fb_never", "never")
	else
		return translatef("fb_sessdesc", "On %s from %s", os.date("%c", time), clip)
	end
end

local fs = require("luci.fs")
local sessions = {}

m2 = Map("fonbackup", "")
m2.done_btn = true

local folders = require("luci.fs").glob("/tmp/mounts/*/*-fonBackup-*")
if folders then
	for i, v in ipairs(folders) do
		local disc = fs.basename(fs.dirname(v))
		local file = fs.basename(v)
		local year, month, day, hours, min, pc = string.match(file, "^([0-9][0-9][0-9][0-9])([0-9][0-9])([0-9][0-9])_([0-9][0-9])([0-9][0-9]).fonBackup.([0-9]*)$")
		if pc then
			table.insert(sessions, {year.."-"..month.."-"..day, hours.."h ".. min.."m", pc, disc.."/"..file})
		end
	end
end

if sessions then
	v = m2:section(Table, sessions, translate("backup_sessions", "Recent Sessions"))
	v:option(DummyValue, 1, translate("backup_date", "Date"))
	v:option(DummyValue, 2, translate("backup_time", "Time"))
	v:option(DummyValue, 3, translate("backup_pc", "PC"))
	link = v:option(DummyValue, 4, translate("backup_link", "Link"))
	link.custom = true
	function link.cfghref(self,...)
		local value = DummyValue.cfgvalue(self, ...)
		return "<a href='"..luci.dispatcher.build_url("fon_devices", "fon_browser", value).."')\"><img src=\"/luci-static/resources/icons/tiny_backup.png\"></a>"
	end
end

s = m2:section(NamedSection, "fonbackup", "fonbackup")
s:append(Template("backup/get"))

return m, m2
