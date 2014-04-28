module("luci.controller.picasa", package.seeall)

function index(env)
	require("luci.i18n")
	local uci = require("luci.model.uci").cursor()
	local i18n = luci.i18n.translate
    luci.i18n.loadc("picasa")

	if env.mounted == "0" then
		local e = entry({"picasa"}, template("nodisc"), luci.i18n.translate("picasa_title", "Picasa"))
		e.i18n = "picasa"
		e.icon_path	= "/luci-static/resources/icons/plugins"
		e.page_icon	= "picasa.png"
		return
	end

	if not(env.online) then
		local e = entry({"picasa"}, template("noinet"), luci.i18n.translate("picasa_title", "Flickr"))
		e.i18n = "picasa"
		e.icon_path  = "/luci-static/resources/icons/plugins"
		e.page_icon = "picasa.png"
		return
	end

	local page  = node("picasa")
	page.css = {"dlmanager/cascade.css"}
	page.target = call("picasa")
	page.title  = luci.i18n.translate("picasa_title", "Youtube")
	page.order  = 50
	page.subindex = 1
	page.icon_path  = "/luci-static/resources/icons/plugins"
	page.page_icon = "picasa.png"
	page.i18n = "picasa"
	page.sysauth = "root"
	page.sysauth_authenticator = "htmlauth"

	local page  = node("picasa", "auth")
	page.target = call("picasa_passwd")
	page.title  = luci.i18n.translate("picasa_passwd", "Password")
	page.icon_path  = "/luci-static/resources/icons/plugins"
	page.page_icon = "picasa.png"

	local page = node("picasa", "privacy_on")
	page.target = call("picasa_privacy_on")

	local page = node("picasa", "privacy_off")
	page.target = call("picasa_privacy_off")

	local page = node("picasa", "queue")
	page.target = call("picasa_queue")

	local page = node("picasa", "flush")
	page.target = call("picasa_flush")

	local page = node("picasa", "auth_fail")
	page.target = template("picasa/auth_fail")
	page.title  = luci.i18n.translate("picasa_auth_title", "Authentication")
end

function picasa_queue()
	local tpl = require "luci.template"
	tpl.render("uploadd_queue", {loader="picasa",loader_name="Picasa"})
end

function picasa_privacy_on()
	local uploadd = require("luci.fon.uploadd")
	uploadd.set_privacy("picasa", 1)
	local http = require "luci.http"
	http.redirect(require("luci.dispatcher").build_url("picasa"))
end

function picasa_privacy_off()
	local uploadd = require("luci.fon.uploadd")
	uploadd.set_privacy("picasa", 0)
	local http = require "luci.http"
	http.redirect(require("luci.dispatcher").build_url("picasa"))
end

function picasa_flush()
	local uploadd = require("luci.fon.uploadd")
	uploadd.flush_queue("picasa")
	local http = require "luci.http"
	http.redirect(require("luci.dispatcher").build_url("picasa"))
end

function picasa_passwd()
	local tpl = require "luci.template"
	local gdata = require "luci.fon.gdata"
	local http = require "luci.http"
	local username = http.formvalue("username")
	local password = http.formvalue("password")
	local uci = luci.model.uci.cursor()
	local fail = "0"

	if username and password and #username > 0 and #password > 0 then
		local auth_token = gdata.get_auth_token(username, password, "lh2")
		if auth_token then
			gdata.adduser("picasa", username, password)
			return require("luci.http").redirect(require("luci.dispatcher").build_url("picasa"))
		else
			fail = "1"
		end
	end

	local user = gdata.getuser("picasa")
	tpl.render("picasa/passwd", {user=(username or user), fail=fail})
end

function picasa()
	local uci = luci.model.uci.cursor_state()
	local tpl = require "luci.template"
	local gdata = require "luci.fon.gdata"
	local http = require "luci.http"
	local username = http.formvalue("username")
	local password = http.formvalue("password")
	local fail = "0"

	if username and password and #username > 0 and #password > 0 then
		local auth_token = gdata.get_auth_token(username, password, "lh2")
		if auth_token then
			gdata.adduser("picasa", username, password)
			uci:delete("gdata", "picasa", "fail")
			uci:commit("gdata")
		else
			fail = "1"
		end
	end

	local user
	local pass
	user, pass = gdata.getuser("picasa")
	if user == nil or pass == nil or #user == 0 or #pass == 0 or fail == "1" then
		tpl.render("picasa/passwd", {user=(user or ""), fail=fail})
		return
	end
	local newfile = http.formvalue("newfile")
	if newfile then
		local u = require("luci.fon.uploadd")
		u.add_queue("picasa", newfile)
		require("luci.http").redirect(require("luci.dispatcher").build_url("picasa"))
		return
	end
	tpl.render("picasa/main")
end
