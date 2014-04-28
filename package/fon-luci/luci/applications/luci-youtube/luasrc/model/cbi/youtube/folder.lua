-- Copyright 2008 John Crispin <john@phrozen.org>

require("luci.tools.webadmin")
local m = Map("gdata",
	translate("youtube_folder_title", "Folder"),
	translate("youtube_folder_desc", "Here you can configure which folder the La Fonera checks for images when a pendrive is attached."))

s = m:section(NamedSection, "youtube")

s:option(Value, "folder", translate("youtube_option_folder", "Folder"))

return  m, Template("youtube/mime")
