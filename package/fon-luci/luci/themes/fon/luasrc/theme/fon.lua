--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--


local tpl = require "luci.template"
local dsp = require "luci.dispatcher"
local uci = require "luci.model.uci"
local util = require "luci.util"
local unpack = unpack
local sort = require "table".sort


module "luci.theme.fon"


function header(colour)
	-- Dont render header if we are in the _maincontent ns
	local maincontent = dsp.context.requestpath[1] == "_maincontent"
	local dashcontent = dsp.context.requestpath[1] == "_dashcontent"
	local wizard = dsp.context.requestpath[1] == "wizard"
	if dashcontent then
		tpl.render("themes/fon/head_dashboard")
		return
	end
	if wizard then
		--tpl.render "themes/fon/head_wizard"
		--tpl.render("themes/fon/head_" .. colour, {wizard=wizard})
		return
	end
	if dsp.context.request and maincontent then
		if colour then
			tpl.render("themes/fon/head_" .. colour, {maincontent=maincontent,wizard=wizard})
		end
		return
	end
	tpl.render "themes/fon/head"
	if colour then
		tpl.render("themes/fon/head_" .. colour)
	end
end

function subindex(div)
	if dsp.context.dispatched and dsp.context.dispatched.subindex then
		dashboard()
		if div ~= false then
			tpl.render("themes/fon/subindex_div")
		end
	end
end

function indexer()
	header()
	dashboard()
	footer()
end

function dashboard()
	local subnodes = dsp.context.requested and dsp.context.requested.nodes
	if subnodes then
		local inline = ""
		if dsp.context.requested.subindex then
			inline = "_inline"
		end
		local inline2 = inline
		if dsp.context.dispatched.noinline then
			inline2 = ""
		end
		tpl.render("themes/fon/dashboard_head"..inline)

		for k, v in util.spairs(subnodes, function (a,b)
			return (subnodes[a].order or 100) < (subnodes[b].order or 100)
		end) do
			if v.title and #v.title > 0 and not v.ignoreindex and (v.index or v.target) then
				local csscl = "%s" % (v.style or k)
				local iconl = v.icon or ""
				local pref = util.clone(dsp.context.requestpath)
				pref[#pref+1] = k
				local target
				local path = v.icon_path
				if not(path) then
					path = uci.cursor():get("luci", "main", "mediaurlbase")
				end
				if dsp.context.requested.subindex and not(dsp.context.dispatched.noinline) then
					target = dsp.build_url("_maincontent", unpack(pref))
				else
					target = dsp.build_url(unpack(pref))
				end
				if #iconl > 0 then
					tpl.render("themes/fon/dashboard_item"..inline2, {
						csscl = csscl,
						target = target,
						iconl = path.."/"..iconl,
						title = v.title
					})
				end
			end
		end
		tpl.render("themes/fon/dashboard_tail"..inline)
	end
end

function pathbar()
	-- Requested node
	local request = util.clone(dsp.context.path or {})

	-- Back
	request[#request] = nil
	local back = dsp.build_url(unpack(request))

	-- Top-Level
	local home = dsp.build_url("fon_dashboard")

	local plugins = {}
	uci.cursor():foreach("plugfons", "plugin", function(section)
		plugins[#plugins+1] = {
			name = section[".name"],
			icon = section.icon,
			path = dsp.build_url(section[".name"]),
			order = section.order
		}
	end)

	sort(plugins, function(a,b)
		return a.order < b.order
	end)

	tpl.render("themes/fon/pathbar", {
		home=home,
		back=back,
		plugins=plugins
	})
end

function footer(colour)
	-- Dont render footer if we are in the _maincontent ns
	local maincontent = dsp.context.requestpath and dsp.context.requestpath[1] == "_maincontent"
	local dashcontent = dsp.context.requestpath and dsp.context.requestpath[1] == "_dashcontent"
	if dashcontent then
		tpl.render("themes/fon/tail_dashboard")
		return
	end
	if colour then
		tpl.render("themes/fon/tail_" .. colour, {maincontent=maincontent})
	end
	if not(maincontent) then
		tpl.render "themes/fon/tail"
	end
end
