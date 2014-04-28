--[[
Copyright 2008 John Crispin <john@phrozen.org>
gpl v2
]]--
module("luci.controller.flickr", package.seeall)

function index(env)
	require("luci.i18n")
	luci.i18n.loadc("flickr")

	if env.mounted == "0" then
		local e = entry({"flickr"}, template("nodisc"), luci.i18n.translate("flickr_title", "Flickr"))
		e.i18n = "flickr"
		e.icon_path	= "/luci-static/resources/icons/plugins"
		e.page_icon	= "flickr.png"
		return
	end
	if not(env.online) then
		local e = entry({"flickr"}, template("noinet"), luci.i18n.translate("flickr_title", "Flickr"))
		e.i18n = "flickr"
		e.icon_path  = "/luci-static/resources/icons/plugins"
		e.page_icon = "flickr.png"
		return
	end
	local auth_token = env.uci:get("flickr", "flickr", "auth_token")

	if not(auth_token) then
		local e = entry({"flickr"}, cbi("flickr/auth_main", {on_success_to = {"flickr", "auth_test"}}), luci.i18n.translate("flickr_title", "Flickr"))
		e.sysauth = "root"
		e.sysauth_authenticator = "htmlauth"
		e.i18n = "flickr"
		e.subindex = 1
		e.icon_path  = "/luci-static/resources/icons/plugins"
		e.page_icon = "flickr.png"

		local page = node("flickr", "auth_test")
		page.target = call("flickr_auth_test")
		page.title = luci.i18n.translate("flickr_auth", "Authentication")
		page.icon_path  = "/luci-static/resources/icons/plugins"
		page.page_icon = "flickr.png"
		return
	end

	local e = entry({"flickr"}, call("flickr"), luci.i18n.translate("flickr_title", "Flickr"))
	e.css = {"dlmanager/cascade.css"}
	e.sysauth = "root"
	e.sysauth_authenticator = "htmlauth"
	e.i18n = "flickr"
	e.icon_path  = "/luci-static/resources/icons/plugins"
	e.page_icon = "flickr.png"

	local page  = node("flickr", "auth")
	page.target = cbi("flickr/auth", {on_success_to = {"flickr", "auth_test"}})
	page.title  = luci.i18n.translate("flickr_auth", "Authentication")
	page.icon_path  = "/luci-static/resources/icons/plugins"
	page.page_icon	= "flickr.png"

	local page = node("flickr", "queue")
	page.target = call("flickr_queue")

	local page = node("flickr", "flush")
	page.target = call("flickr_flush")

	local page = node("flickr", "privacy_on")
	page.target = call("flickr_privacy_on")

	local page = node("flickr", "privacy_off")
	page.target = call("flickr_privacy_off")

	local page = node("flickr", "auth_test")
	page.target = template("flickr/auth_test")
	page.title = luci.i18n.translate("flickr_auth", "Authentication")
	page.icon_path  = "/luci-static/resources/icons/plugins"
	page.page_icon	= "flickr.png"
end

function flickr_privacy_on()
	local uploadd = require("luci.fon.uploadd")
	uploadd.set_privacy("flickr", 1)
	local http = require "luci.http"
	http.redirect(require("luci.dispatcher").build_url("flickr"))
end

function flickr_privacy_off()
	local uploadd = require("luci.fon.uploadd")
	uploadd.set_privacy("flickr", 0)
	local http = require "luci.http"
	http.redirect(require("luci.dispatcher").build_url("flickr"))
end

function flickr_queue()
	local tpl = require "luci.template"
	tpl.render("uploadd_queue", {loader="flickr",loader_name="Flickr"})
end

function flickr_flush()
	local uploadd = require("luci.fon.uploadd")
	uploadd.flush_queue("flickr")
	local http = require "luci.http"
	http.redirect(require("luci.dispatcher").build_url("flickr"))
end

function flickr_auth_test()
	local tpl = require "luci.template"
	local http = require "luci.http"
	local frob = require("luci.model.uci").cursor():get("flickr", "flickr", "frob")
	if not(frob) then
		http.redirect(require("luci.dispatcher").build_url("flickr"))
		return
	end
	local flickr = require("luci.fon.flickr")
	local uci = require("luci.model.uci").cursor()
	local frob = string.gsub(uci:get("flickr", "flickr", "frob"), " ", "")
	local res = flickr.frob2auth(frob)
	uci:load("flickr")
	uci:delete("flickr", "flickr", "frob")
	uci:commit("flickr")
	if res then
		local srv = require("luci.fon.service")
		local service = srv.Service("flickr")
		service:start()
		http.redirect(require("luci.dispatcher").build_url("flickr"))
	else
		tpl.render("flickr/auth_test_main")
	end
end

function flickr()
	local tpl = require "luci.template"
	local http = require "luci.http"
	local newfile = http.formvalue("newfile")
	if newfile then
		local u = require("luci.fon.uploadd")
		u.add_queue("flickr", newfile)
		require("luci.http").redirect(require("luci.dispatcher").build_url("flickr"))
		return
	end
	tpl.render("flickr/main")
end
