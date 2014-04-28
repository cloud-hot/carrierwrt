module("socket.http", package.seeall)

-- The consumer token shown below is registered using the official "Fon"
-- twitter account and is used for authenticating all Fonera's. Note
-- that even though this is referred to as a "secret", Twitter does not
-- do any provider verification, so there's no harm in making this key
-- public (an attacker would still need the actual access token to make
-- authenticated requests, just the consumer token is never enough).
local fon_consumer_key = "8yt3hYM0MkivQQ6qQGug"
local fon_consumer_secret = "UujZXj55t1Ck8SEfrpzgMIrSRIRRTlKtPO87uj2Ra4"

-- Fake socket.http.request function, that wraps luci.httpclient to do
-- the hard work.  This allows us to use the bbl-twitter file
-- unmodified.
function request(uri, body)
	local httpc = require "luci.httpclient"

	options = { body = body }
	local response, code, msg = httpc.request_to_buffer(uri, options)

	if (not response) then
		-- In case of an error, msg is the error message and
		-- code is the HTTP response code, if any
		return msg, code
	else
		-- In case of a succesful request, only the response is
		-- returned by request_to_buffer, so we suppose the HTTP
		-- response code is 200
		return response, 200
	end
end


--
-- The real module starts here.
--

module("luci.twitter", package.seeall)

require("luci.bbl-twitter")

-- The current client instance. Use get_client instead of accessing this
-- directly.
local c

-- Gets a client instance, creating it if needed.
local function get_client()
	if not c then
		local uci = require("luci.model.uci").cursor()
		-- These default to the consumer token defined at the
		-- top of this file, but can be overridden using config
		-- values (just in case this might be useful for
		-- someone).
		local consumer_key = uci:get("twitter", "twitter", "consumer_key") or fon_consumer_key
		local consumer_secret = uci:get("twitter", "twitter", "consumer_secret") or fon_consumer_secret
		-- These will only be present when we're in the middle
		-- of oauth, but otherwise we'll just pass nils to
		-- client().
		local token_key = uci:get("twitter", "twitter", "token_key")
		local token_secret = uci:get("twitter", "twitter", "token_secret")
		c = client(consumer_key, consumer_secret, token_key, token_secret)
	end

	return c
end

-- Send a message to syslog. Writes the message to the "logger" program
-- through stdin instead of putting the message on the commandline, to
-- prevent (security) problems with shell special characters in the
-- message
local function log(msg)
	f = io.popen("logger", "w")
	f:write(msg)
	f:close()
end

-- does the actual tweeting. Returns true or false depending on whether
-- the Tweet succeeded. If problems were encountered, they are logged to
-- syslog.
local function do_tweet(client, msg)
	-- Make an authenticated request
	succes, response = pcall(signed_request, client, "/1.1/statuses/update.json", {status = msg})
	if not succes then
		log("Failed to post tweet to Twitter: " .. response)
		return 0
	end

	-- Decode the response as JSON
	local ltn12 = require "luci.ltn12"
	local decoder = require "luci.json".Decoder()
	ltn12.pump.all(ltn12.source.string(response), decoder:sink())
	local data = decoder:get()
	if data and data.text then
		log("Succesfully posted tweet to Twitter: " .. msg)
		return true
	end
	log("Failed to post tweet to Twitter, response was: " .. (data or "No response received") )
	return false
end

-- a tweet event can be enabled and/or disabled
function event_status(name)
	return require("luci.model.uci").cursor():get("twitter", name, "enable") or "0"
end

function event_enable(name, enable)
	local uci = require("luci.model.uci").cursor()
	uci:set("twitter", name, "enable", enable)
	uci:commit("twitter")
end

function event_add(name, default, description)
	local uci = require("luci.model.uci").cursor()
	uci:section("twitter", "event", name,
		{desc=description, enable=default})
	uci:commit("twitter")
end

-- Return the username for which we have authentication info, or nil if
-- no authentication info is stored.
function get_username()
	local uci = require("luci.model.uci").cursor()
	local key = uci:get("twitter", "twitter", "token_key")
	local secret = uci:get("twitter", "twitter", "token_secret")
	local username = uci:get("twitter", "twitter", "username")

	if key and secret then
		return username
	else
		return nil
	end
end

function set_target_username(name)
        local uci = require("luci.model.uci").cursor()
        uci:set("twitter", "twitter", "target_user", name)
        uci:commit("twitter")
end

function get_target_username()
        local uci = require("luci.model.uci").cursor()
        return uci:get("twitter", "twitter", "target_user")
end

function reset_auth_info()
	local uci = require("luci.model.uci").cursor()
	uci:load("twitter")
	uci:delete("twitter", "twitter", "token_key")
	uci:delete("twitter", "twitter", "token_secret")
	uci:delete("twitter", "twitter", "username")
	uci:commit("twitter")
end

-- Starts oauth authentication. Returns an URL the use should be redirected
-- to.
function oauth_start(callback_url)
	client = get_client()

	get_request_token(client, callback_url)

	local uci = require("luci.model.uci").cursor()

	-- Store the request token to request an acces token later on
	-- (in oauth_handle_callback).
	uci:set("twitter", "twitter", "request_token", c.req_token)
	uci:set("twitter", "twitter", "request_secret", c.req_secret)
	uci:commit("twitter")

	return get_authorize_url(client)
end

-- Finish oauth authentication. Should be passed the oauth_token and
-- oauth_verifier parameters from the url.
function oauth_handle_callback(oauth_token, oauth_verifier)
	local uci = require("luci.model.uci").cursor()

	client = get_client()

	-- Get the request token we obtained earlier.
	client.req_token = uci:get("twitter", "twitter", "request_token")
	client.req_secret = uci:get("twitter", "twitter", "request_secret")

	-- Check the token from the url
	assert(client.req_token == oauth_token, "Request token (" .. (oauth_token or "") .. ") does not match stored token (" .. (client.req_token or "") .. ")")

	-- Trade the verifier for an access token
	get_access_token(client, oauth_verifier)

	-- Save the obtained access token and trash the request token
	uci:load("twitter")
	uci:delete("twitter", "twitter", "request_token")
	uci:delete("twitter", "twitter", "request_secret")
	uci:set("twitter", "twitter", "token_key", c.token_key)
	uci:set("twitter", "twitter", "token_secret", c.token_secret)
	uci:set("twitter", "twitter", "username", c.screen_name)

	-- Use the authenticating user as a default for the target user
	if  not uci:get("twitter", "twitter", "target_user") then
		uci:set("twitter", "twitter", "target_user", c.screen_name)
	end
	uci:commit("twitter")
end

-- tweet wrapper that takes care of authentication and event status
-- settings.
function tweet(msg, event)
	-- Username we authenticated as
	local username = get_username()
	if not username then
		-- Twitter is not configured
		return false
	end

	local s = event_status(event)
	if s == "0" then
		return false
	end

	local uci = require("luci.model.uci").cursor()
	local target_user = get_target_username()
	if not target_user then
		log("Not posting tweet to Twitter, no target user configured")
		return false
	end

	-- See if we send a direct message or a public tweet
	local prefix
	if s == "1" then
		prefix = "d "..target_user.." "
	else -- s must be "2"
		prefix = "@"..target_user.." "
	end

	-- Post the tweet
	client = get_client()
	do_tweet(client, prefix..msg)
	return true
end
