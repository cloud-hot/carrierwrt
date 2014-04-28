-- Copyright 2008 John Crispin <john@phrozen.org>

require("luci.tools.webadmin")
local m = Map("gdata",
	translate("picasa_folder_title", "Folder"),
	translate("picasa_folder_desc", "Here you can configure which folder the La Fonera checks for images when a pendrive is attached."))

s = m:section(NamedSection, "picasa")

s:option(Value, "folder", translate("picasa_option_folder", "Folder"))

return  m, Template("picasa/mime")
