function initialize()
	local lucittpd = require "luci.ttpd.server"
	local vhost = lucittpd.VHost()
	server = lucittpd.Server(vhost)

	function vhost.process(self, req, ...)
		local uci = require "luci.model.uci".cursor_state()
		local check = require "luci.sys".user.checkpasswd
		local ltn12 = require "luci.ltn12"
		local unb64 = require "luanet".b64_decode
		if req.env.SERVER_ADDR ~= require "luci.model.uci".cursor():get("fon", "lan", "ipaddr") then
			local lock = uci:get("lucittpd", "lucittpd", "lock") or 0
			if os.difftime(os.time(), lock) < 180 then
				return {status=403, headers={}}, ltn12.source.string("Unauthorized")
			end
			local auth = (req.headers.Authorization or ""):match("Basic (.*)")
			auth = auth and (unb64(auth)) or ""
			local user, pass = auth:match("(.*):(.*)")
			if user == "admin" or user == "fonero" then
				user = "root"
			end
			if user ~= "root" or not pass or not check(user, pass) then
				local hammer = uci:get("lucittpd", "lucittpd", "hammer") or "0"
				hammer = hammer + 1
				uci:set("lucittpd", "lucittpd", "hammer", hammer)
				uci:save("lucittpd")
				if hammer > 5 then
					uci:set("lucittpd", "lucittpd", "lock", os.time())
					uci:revert("lucittpd", "lucittpd", "hammer")
					uci:save("lucittpd")
					return {status=403, headers={}}, ltn12.source.string("Unauthorized")
				end
				return {status=401, headers={
					["WWW-Authenticate"] = 'Basic realm="Restricted"'
				}}, ltn12.source.string("Unauthorized")
			end
			uci:revert("lucittpd", "lucittpd", "hammer")
			uci:save("lucittpd")
		end
		return lucittpd.VHost.process(self, req, ...)
	end
end

function register()
	local filehnd = require "luci.ttpd.handler.file"
	local uci = require "luci.model.uci".cursor()
	local filehandler = filehnd.Simple((uci:get("lucittpd", "lucittpd", "root") or "/www"))
	server:get_default_vhost():set_default_handler(filehandler)
end

function accept()
	server:process({
		_read = function(...)
			local chunk, err = webuci_read(...)
			return chunk or (err and error(err, 0))
		end,

		_write = function(...)
			local chunk, err = webuci_write(...)
			return chunk or (err and error(err, 0))
		end,

		_close = function(...)
			local chunk, err = webuci_close(...)
			return chunk or (err and error(err, 0))
		end,

		_sendfile = function(...)
			local chunk, err = webuci_sendfile(...)
			return chunk or (err and error(err, 0))
		end,

		_REMOTE_ADDR = webuci_REMOTE_ADDR,
		_SERVER_ADDR = webuci_SERVER_ADDR
	})
end
