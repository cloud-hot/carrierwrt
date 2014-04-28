module("luci.controller.youtube", package.seeall)

function index(env)
	require("luci.i18n")
	local i18n = luci.i18n.translate
    luci.i18n.loadc("youtube")

	if env.mounted == "0" then
		local e = entry({"youtube"}, template("nodisc"), luci.i18n.translate("youtube_title", "Youtube"))
		e.i18n = "youtube"
		e.icon_path	= "/luci-static/resources/icons/plugins"
		e.page_icon	= "youtube.png"
		return
	end

	if not(env.online) then
		local e = entry({"youtube"}, template("noinet"), luci.i18n.translate("youtube_title", "Youtube"))
		e.i18n = "youtube"
		e.icon_path	= "/luci-static/resources/icons/plugins"
		e.page_icon	= "youtube.png"
		return
	end

	local page  = node("youtube")
	page.css = {"dlmanager/cascade.css"}
	page.target = call("youtube")
	page.title  = luci.i18n.translate("youtube_title", "Youtube")
	page.order  = 50
	page.subindex = 1
	page.icon_path	= "/luci-static/resources/icons/plugins"
	page.page_icon	= "youtube.png"
	page.i18n = "youtube"
	page.sysauth = "root"
	page.sysauth_authenticator = "htmlauth"

	local page  = node("youtube", "auth")
	page.target = call("youtube_passwd")
	page.title  = luci.i18n.translate("youtube_passwd", "Password")
	page.icon_path	= "/luci-static/resources/icons/plugins"
	page.page_icon	= "youtube.png"
	page.order	= 25

	local page = node("youtube", "queue")
	page.target = call("youtube_queue")

	local page = node("youtube", "flush")
	page.target = call("youtube_flush")

	local page = node("youtube", "privacy_on")
	page.target = call("youtube_privacy_on")

	local page = node("youtube", "privacy_off")
	page.target = call("youtube_privacy_off")

	local page = node("youtube", "auth_fail")
	page.target = template("youtube/auth_fail")
	page.title  = luci.i18n.translate("youtube_auth_title", "Authentication")
end

function youtube_passwd()
	local tpl = require "luci.template"
	local gdata = require "luci.fon.gdata"
	local http = require "luci.http"
	local username = http.formvalue("username")
	local password = http.formvalue("password")
	local uci = luci.model.uci.cursor()
	local fail = "0"

	if username and password and #username > 0 and #password > 0 then
		local auth_token = gdata.get_auth_token(username, password, "youtube")
		if auth_token then
			gdata.adduser("youtube", username, password)
			uci:delete("gdata", "youtube", "fail")
			uci:commit("gdata")
			return http.redirect(require("luci.dispatcher").build_url("youtube"))
		else
			fail = "1"
		end
	end

	local user = gdata.getuser("youtube")
	tpl.render("youtube/passwd", {user=(username or user), fail=fail})
end

function youtube_queue()
	local tpl = require "luci.template"
	tpl.render("uploadd_queue", {loader="youtube",loader_name="Youtube"})
end

function youtube_privacy_on()
	local uploadd = require("luci.fon.uploadd")
	uploadd.set_privacy("youtube", 1)
	local http = require "luci.http"
	http.redirect(require("luci.dispatcher").build_url("youtube"))
end

function youtube_privacy_off()
	local uploadd = require("luci.fon.uploadd")
	uploadd.set_privacy("youtube", 0)
	local http = require "luci.http"
	http.redirect(require("luci.dispatcher").build_url("youtube"))
end

function youtube_flush()
	local uploadd = require("luci.fon.uploadd")
	uploadd.flush_queue("youtube")
	local http = require "luci.http"
	http.redirect(require("luci.dispatcher").build_url("youtube"))
end

function youtube()
	local uci = luci.model.uci.cursor_state()
	local tpl = require "luci.template"
	local gdata = require "luci.fon.gdata"
	local http = require "luci.http"
	local username = http.formvalue("username")
	local password = http.formvalue("password")
	local fail = "0"
	if username and password and #username > 0 and #password > 0 then
		local auth_token = gdata.get_auth_token(username, password, "youtube")
		if auth_token then
			gdata.adduser("youtube", username, password)
			uci:delete("gdata", "youtube", "fail")
			uci:commit("gdata")
		else
			fail = "1"
		end
	end

	local user
	local pass
	user, pass = gdata.getuser("youtube")
	if user == nil or pass == nil or #user == 0 or #pass == 0 or fail == "1" then
		tpl.render("youtube/passwd", {user=(user or ""),fail=fail})
		return
	end
	local newfile = http.formvalue("newfile")
	if newfile then
		local u = require("luci.fon.uploadd")
		u.add_queue("youtube", newfile)
		require("luci.http").redirect(require("luci.dispatcher").build_url("youtube"))
		return
	end
	tpl.render("youtube/main")
end
