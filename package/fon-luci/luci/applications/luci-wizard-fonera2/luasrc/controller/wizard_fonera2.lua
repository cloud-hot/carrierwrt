module("luci.controller.wizard_fonera2", package.seeall)

function index(env)
	local done = env.uci:get("wizard", "fon2wiz", "called")
	if done == "1" then
		local e = entry({"wizard"}, call("wizard_redir"), "")
		return
	end

	require("luci.i18n")

	local page  = node("wizard")
	local uci = env.uci_state
	local inet = uci:get("wizard", "fon2wiz", "online") or uci:get("fon", "state", "online") or "0"
	local umts = uci:get("wizard", "fon2wiz", "umts") or uci:get("fon", "wan", "mode")
	uci:set("wizard", "fon2wiz", "online", inet)
	uci:set("wizard", "fon2wiz", "umts", umts)
	uci:save("wizard")

	if inet == "1" then
		local page  = node("wizard", "step1")
		page.target = cbi("wizard_fonera2/password", {on_success_to = {"wizard", "step2"}, noheader=true, skip=true})
		page.page_icon = "icons/pass.png"

		local page  = node("wizard", "step2")
		page.target = cbi("wizard_fonera2/youtube", {on_success_to = {"wizard", "step3"}, noheader=true, skip=true})
		page.icon_path  = "/luci-static/resources/icons/plugins"
		page.page_icon = "youtube.png"

		local page  = node("wizard", "step3")
		page.target = cbi("wizard_fonera2/picasa", {on_success_to = {"wizard", "step4"}, noheader=true, skip=true})
		page.icon_path  = "/luci-static/resources/icons/plugins"
		page.page_icon = "picasa.png"

		local page  = node("wizard", "step4")
		page.target = cbi("wizard_fonera2/flickr", {on_success_to = {"wizard", "step5"}, noheader=true, skip=true})
		page.icon_path  = "/luci-static/resources/icons/plugins"
		page.page_icon = "flickr.png"

		local page  = node("wizard", "step5")
		page.target = cbi("wizard_fonera2/facebook", {on_success_to = {"wizard", "step6"}, noheader=true, skip=true})
		page.icon_path  = "/luci-static/resources/icons/plugins"
		page.page_icon = "facebook.png"

		local page  = node("wizard", "step6")
		page.target = cbi("wizard_fonera2/dlmanager_rs", {on_success_to = {"wizard", "step7"}, noheader=true, skip=true})
		page.icon_path  = "/luci-static/resources/"
		page.page_icon = "rs.png"

		local page  = node("wizard", "step7")
		page.target = template("wizard_fonera2/register")
	else
		local page  = node("wizard", "step1")
		if umts == "umts" then
			page.target = cbi("wizard_fonera2/umts", {on_success_to = {"wizard", "step2"}, noheader=true, skip=true})
			page.icon_path  = "/luci-static/fon/icons/"
			page.page_icon = "umts_on.png"
		else
			page.target = cbi("wizard_fonera2/inet", {on_success_to = {"wizard", "step2"}, noheader=true, skip=true})
			page.icon_path  = "/luci-static/fon/icons/"
			page.page_icon = "inet.png"
		end

		local page  = node("wizard", "step2")
		page.target = cbi("wizard_fonera2/password", {on_success_to = {"wizard", "step5"}, noheader=true, skip=true})
		page.page_icon = "icons/pass.png"

		local page  = node("wizard", "step5")
		page.target = cbi("wizard_fonera2/activation", {on_success_to = {"wizard", "step3"}, noheader=true, skip=true})
		page.page_icon = "icons/pass.png"

		local page  = node("wizard", "step3")
		page.target = template("wizard_fonera2/services")

		local page  = node("wizard", "step4")
		page.target = template("wizard_fonera2/register")
	end

	local page  = node("wizard", "end")
	page.target = template("wizard_fonera2/end")
end

function youtube_passwd()
	local tpl = require "luci.template"
	local gdata = require "luci.fon.gdata"
	local http = require "luci.http"
	local username = http.formvalue("username")
	local password = http.formvalue("password")

	if username and password and #username > 0 and #password > 0 then
		tpl.render("youtube/close")
		gdata.adduser("default", username, password)
	else
		local user = gdata.getuser("default")
		tpl.render("wizard_fonera2/youtube", {user=(username or user)})
	end
end


function wizard_redir()
	return require("luci.http").redirect(require("luci.dispatcher").build_url(""))
end
