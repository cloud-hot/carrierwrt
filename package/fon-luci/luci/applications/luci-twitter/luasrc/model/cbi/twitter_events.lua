-- Copyright 2009 John Crispin <john@phrozen.org>

require("luci.tools.webadmin", package.seeall)

username = require("luci.twitter").get_username()

local e = SimpleForm("twitter_events",
	translate("twitter_event_title", "Twitter"),
	translate("twitter_event_desc", "Here you can choose which events you want to tweet about.")
	.. "<br/><br/>"
	.. translate("twitter_event_account", "Events will be tweeted using this account:") .. "<b>" .. username .. "</b>")

local uci = require("luci.model.uci").cursor()
uci:load("twitter")

local name = e:field(Value, "target_user", translate("twitter_username", "Your Twitter Username"))
name.default = uci:get("twitter", "twitter", "target_user")
name.rmempty = false
function name.validate(self, value, section)
	if not(value) or #value == 0 then
		value = false
	end
	return value
end

uci:foreach("twitter", "event", function(s)
	local x = e:field(ListValue, s[".name"], s.desc)
	x:value("0", translate("disable", "Disable"))
	x:value("1", translate("twitter_direct", "Direct"))
	x:value("2", translate("twitter_reply", "Reply"))
	x.default = uci:get("twitter", s[".name"], "enable")
	end)

function e.handle(self, state, data)
	if state == FORM_INVALID then
		name.error = name.error or {}
		name.error[1] = true
	end
	if state == FORM_VALID then
		local t = require("luci.twitter")
		if data["target_user"] then
			t.set_target_username(data["target_user"])
		end
		local uci = require("luci.model.uci").cursor()
		uci:load("twitter")
		uci:foreach("twitter", "event", function(s)
			if data[s[".name"]] then
				t.event_enable(s[".name"], data[s[".name"]])
			end
		end)
	end
	return true
end
e:append(Template("twitter"))
return e
