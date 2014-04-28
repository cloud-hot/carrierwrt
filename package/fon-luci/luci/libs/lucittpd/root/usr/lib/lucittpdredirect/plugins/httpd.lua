-- Preload more stuff
require "luci.dispatcher"
require "luci.uvl"
require "luci.cbi"
require "luci.template"
require "luci.json"

local lucittpd = require "luci.ttpd.server"
local redirect  = require "luci.ttpd.handler.redirect"
local lucihnd  = require "luci.ttpd.handler.luci"

local server  = lucittpd.Server()
local vhost   = lucittpd.VHost()
server:set_default_vhost(vhost)

local redirhandler = redirect.Simple()
vhost:set_default_handler(redirhandler)

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
		end
	})
end
