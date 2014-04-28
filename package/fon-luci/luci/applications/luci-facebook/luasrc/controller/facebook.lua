--[[
Copyright 2008 John Crispin <john@phrozen.org>
gpl v2
]]--
module("luci.controller.facebook", package.seeall)

function index(env)
	require("luci.i18n")
	luci.i18n.loadc("facebook")

	if env.mounted == "0" then
		local e = entry({"facebook"}, template("nodisc"), luci.i18n.translate("facebook_title", "Facebook"))
		e.i18n = "facebook"
		e.icon_path	= "/luci-static/resources/icons/plugins"
		e.page_icon	= "facebook.png"
		return
	end
	if not(env.online) then
		local e = entry({"facebook"}, template("noinet"), luci.i18n.translate("facebook_title", "Facebook"))
		e.i18n = "facebook"
		e.icon_path  = "/luci-static/resources/icons/plugins"
		e.page_icon = "facebook.png"
		return
	end

	local session_key = env.uci:get("facebook", "facebook", "session_key")

	local page = node("facebook", "config")
	page.target = cbi("facebook/auth_test", {on_success_to = {"facebook"}})
	page.title = luci.i18n.translate("facebook_auth", "Authentication")

	if not(session_key) then
		local e = entry({"facebook"}, cbi("facebook/auth_main", {on_success_to = {"facebook", "config"}}), luci.i18n.translate("facebook_title", "Facebook"))
		e.sysauth = "root"
		e.sysauth_authenticator = "htmlauth"
		e.i18n = "facebook"
		e.icon_path  = "/luci-static/resources/icons/plugins"
		e.page_icon = "facebook.png"
		return
	end

	local e = entry({"facebook"}, call("facebook"), luci.i18n.translate("facebook_title", "Facebook"))
	e.css = {"dlmanager/cascade.css"}
	e.sysauth = "root"
	e.sysauth_authenticator = "htmlauth"
	e.i18n = "facebook"
	e.icon_path  = "/luci-static/resources/icons/plugins"
	e.page_icon = "facebook.png"

	local page  = node("facebook", "auth")
	page.target = template("facebook/auth", {on_success_to = {"facebook"}})
	page.title  = luci.i18n.translate("facebook_auth", "Authentication")
	page.icon	= "icons/pass.png"
	page.order	= 100
	page.icon_path  = "/luci-static/resources/icons/plugins"
	page.page_icon = "facebook.png"

	local page = node("facebook", "queue")
	page.target = call("facebook_queue")

	local page = node("facebook", "flush")
	page.target = call("facebook_flush")

	local page = node("facebook", "queue")
	page.target = call("facebook_queue")

	local page = node("facebook", "privacy_on")
	page.target = call("facebook_privacy_on")

	local page = node("facebook", "privacy_off")
	page.target = call("facebook_privacy_off")

	local page = node("facebook", "auth_test")
	page.target = template("facebook/auth")
	page.title = luci.i18n.translate("facebook_auth", "Authentication")

	local page = node("facebook", "clear_session")
	page.target = call("facebook_clear_session")
end

function facebook_privacy_on()
	local uploadd = require("luci.fon.uploadd")
	uploadd.set_privacy("facebook", 1)
	local http = require "luci.http"
	http.redirect(require("luci.dispatcher").build_url("facebook"))
end

function facebook_privacy_off()
	local uploadd = require("luci.fon.uploadd")
	uploadd.set_privacy("facebook", 0)
	local http = require "luci.http"
	http.redirect(require("luci.dispatcher").build_url("facebook"))
end

function facebook_queue()
	local tpl = require "luci.template"
	tpl.render("uploadd_queue", {loader="facebook",loader_name="Facebook"})
end

function facebook_flush()
	local uploadd = require("luci.fon.uploadd")
	uploadd.flush_queue("facebook")
	local http = require "luci.http"
	http.redirect(require("luci.dispatcher").build_url("facebook"))
end

function facebook()
	local tpl = require "luci.template"
	local http = require "luci.http"
	local newfile = http.formvalue("newfile")
	if newfile then
		local u = require("luci.fon.uploadd")
		u.add_queue("facebook", newfile)
		require("luci.http").redirect(require("luci.dispatcher").build_url("facebook"))
		return
	end
	tpl.render("facebook/main")
end

function facebook_clear_session()
	local uci = require("luci.model.uci").cursor()
	uci:delete("facebook", "facebook", "session_key")
	uci:commit("facebook")
	require("luci.http").redirect(require("luci.dispatcher").build_url("facebook"))
end
