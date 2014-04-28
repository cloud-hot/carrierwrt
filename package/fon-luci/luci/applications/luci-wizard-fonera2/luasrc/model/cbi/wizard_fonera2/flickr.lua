--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

$Id: passwd.lua 2880 2008-08-17 23:47:38Z jow $
]]--
require("luci.tools.webadmin", package.seeall)

local m = Map("flickr",
	translate("flickr_wiz_title", "Flickr"),
	translate("flickr_wizard_desc", "The La Fonera needs to be authenticated with Flickr before it can upload pictures. Follow the instructions below if you want to do this now"..
		"<br><ol><li>click this icon")..
		"&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"#\" onclick='window.open(\""..require("luci.model.uci").cursor():get("flickr", "flickr", "frob_url").."\", \"_blank\", \"menubar=no,titlebar=no\");'>"..
		"<img src=\"/luci-static/resources/icons/plugins/tiny_flickr.png\"  alt=\"Flickr\" /></a>"..
		translate("flickr_wizard_desc2", "</li><li>a Flickr popup should appear</li>"..
		"<li>Login and get the token (<b>abc-def-ghi</b>)</li>"..
		"<li>Enter the token in the field below</li></ol>").."<br><br>")
m.cancel = false
m.submit = translate("wiz_next", "Next")
m.events = {"ConfigFlickr"}

s = m:section(NamedSection, "flickr")

s:option(Value, "frob", translate("flickr_option_token", "Token"))

return Template("wizard_fonera2/head"), Template("themes/fon/head_darkorange"), Template("wizard_fonera2/map_head"), m
