module("luci.controller.twitter", package.seeall)

function index(env)
	require("luci.i18n")
	local i18n = luci.i18n.translate
	luci.i18n.loadc("twitter")

	if not(env.online) then
		local e = entry({"twitter"}, template("noinet"), luci.i18n.translate("twitter_title", "Twitter"))
		e.i18n = "twitter"
		e.icon_path	= "/luci-static/resources/icons/plugins"
		e.page_icon	= "twitter.png"
		return
	end

	local e = entry({"twitter", "oauth_start"}, call("oauth_start"))
	local e = entry({"twitter", "oauth_callback"}, call("oauth_callback"))

	local t = require("luci.twitter")
	if not t.get_username() then
		local e = entry({"twitter"}, template("twitter_auth"), luci.i18n.translate("twitter_title", "Twitter"))
		e.i18n = "twitter"
		e.icon_path	= "/luci-static/resources/icons/plugins"
		e.page_icon	= "twitter.png"
		return
	end

	local page  = node("twitter")
	page.title  = luci.i18n.translate("twitter_title", "Twitter")
	page.icon_path	= "/luci-static/resources/icons/plugins"
	page.page_icon	= "twitter.png"
	page.i18n = "twitter"
	page.sysauth = "root"
	page.sysauth_authenticator = "htmlauth"

	page.target = cbi("twitter_events", {on_success_to={"fon_dashboard"}})

	entry({"twitter", "reset"}, call("twitter_reset_user"))
end

function oauth_start()
	local t = require("luci.twitter")
	local http = require "luci.http"
	local tpl = require "luci.template"

	callback_url = luci.dispatcher.build_complete_url("twitter", "oauth_callback")

	success, r = pcall(t.oauth_start, callback_url)
	if not success then
		tpl.render("twitter_auth_error", {errmsg=r})
		return
	end

	url = r

	return http.redirect(url)

end

function oauth_callback()
	local tpl = require "luci.template"
	local http = require "luci.http"

	local oauth_token = http.formvalue("oauth_token")
	local oauth_verifier = http.formvalue("oauth_verifier")

	local t = require("luci.twitter")

	success, r = pcall(t.oauth_handle_callback, oauth_token, oauth_verifier)
	if not success then
		tpl.render("twitter_auth_error", {errmsg=r})
		return
	end


	http.redirect(luci.dispatcher.build_url("twitter"))
end

function twitter_reset_user()
	local t = require("luci.twitter")
	t.reset_auth_info()

	require("luci.http").redirect(luci.dispatcher.build_url("twitter"))
end
