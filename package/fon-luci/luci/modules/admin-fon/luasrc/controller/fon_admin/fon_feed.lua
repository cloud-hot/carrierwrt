local req = require
local ipairs, type = ipairs, type

module "luci.controller.fon_admin.fon_feed"

function index()
	entry({"fon_feed"}, call("feed"))


	-- Example code
	
	local os = require "os"
	local webevents = require "luci.tools.webevents"
	local lucievents = require "luci.fon.lucievents"
	local http = require "luci.http"
	
	-- Register a feed handler template for event type "dummy1"
	webevents.feeder("dummy1", "fon_feed/dummy1")
	webevents.feeder("dummy1", function(ev)
		http.write("Hello from function for " .. ev.id .. "\n\n")
		
		-- Fire a new "dummy2" event
		lucievents.fire("dummy2", {id="lolomat"})
		
		-- Fire a new "dummy2" event which is valid for 10 secs
		lucievents.fire("dummy2", {id="roflomat"}, os.time() + 10)
		
		-- Acknowledge the dummy1 event which we are handling
		lucievents.acknowledge(ev.id)
	end)
	
	-- And a feed handler function for event type "dummy2"
	webevents.feeder("dummy2", function(ev)
		http.write("Hello from ANOTHER function for " .. ev.id .. "\n\n")
	end)
	
end

local require = req
function feed()
	local tpl = require "luci.template"
	local http = require "luci.http"
	local webevents = require "luci.tools.webevents"
	
	-- Prepare stuff
	http.prepare_content("text/plain")
	http.write("some head data\n")
	
	-- Over all valid events which have a feed handler
	for _, evstruct in ipairs(webevents.dispatch("feed")) do
		http.write("begin event: " .. evstruct.event.id .. "\n")
		-- Over all handlers of an event
		for _, handler in ipairs(evstruct.handler) do
			http.write("begin handler block\n")
			-- If the handler is a function, call it
			if type(handler) == "function" then
				handler(evstruct.event)
			-- If it is a string, interpret it as a template file
			elseif type(handler) == "string" then
				tpl.render(handler, evstruct)
			end
			http.write("end handler block\n")
		end
		http.write("end event: " .. evstruct.event.id .. "\n")
	end
	
	http.write("some tail data\n")
end