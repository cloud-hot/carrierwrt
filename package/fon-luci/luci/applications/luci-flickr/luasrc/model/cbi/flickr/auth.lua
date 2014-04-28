-- Copyright 2008 John Crispin <john@phrozen.org>

require("luci.tools.webadmin")
local m = Map("flickr",
	translate("flickr_auth_title", "Authenticate"),
	translate("flickr_auth_desc", "The La Fonera needs to be authenticated with Flickr before it can upload pictures. Follow the instructions below if you want to do this now"..
		"<br><ol><li>click this icon")..
		"&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"#\" onclick='window.open(\""..require("luci.model.uci").cursor():get("flickr", "flickr", "frob_url").."\", \"_blank\", \"menubar=no,titlebar=no\");'>"..
		"<img src=\"/luci-static/resources/icons/plugins/tiny_flickr.png\"  alt=\"Flickr\" /></a>"..
	translate("flickr_auth_desc2", "</li><li>a Flickr popup should appear</li>"..
		"<li>Login and get the token (<b>abc-def-ghi</b>)</li>"..
		"<li>Enter the token in the field below</li>").."<br><br>")

s = m:section(NamedSection, "flickr")

s:option(Value, "frob", translate("flickr_option_token", "Token"))

return  m
