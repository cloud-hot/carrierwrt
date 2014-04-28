module("luci.fon.pkg", package.seeall)

local util = require("luci.util")

Plugin = util.class()

-- adds a mime type to the 
function add_mime(ext, mime)
	local uci = require("luci.model.uci").cursor()
	if ext and mime then
		uci:set("fon_browser", "mime", ext, mime)
		uci:commit("fon_browser")
	end
end

-- adds a handler for a mime type
function add_mime_handler(module, template, priority, mimes)
	if module and template and priority and mimes then
		local uci = require("luci.model.uci").cursor()
		uci:section("fon_browser", "module", module,
			{template=template,priority=priority})
		uci:set_list("fon_browser", module, "filter", mimes)
		uci:commit("fon_browser")
	end
end

function remove_mime_handler(module)
	if module then
		local uci = require("luci.model.uci").cursor()
		uci:delete("fon_browser", module)
		uci:commit("fon_browser")
	end
end

-- constructor 
function Plugin.__init__(self, title)
	self.uci = require("luci.model.uci").cursor()
	self.title = title
end

-- adds base info about a plugin
function Plugin.add(self, name, provider, version)
	local s = self.uci:get_all("plugfons", self.title)
	if s ~= nil then
		os.exit(1)
	end
	if self.title and name and provider and version then
		self.name = name
		self.provider = provider
		self.version = version
		self.uci:section("plugfons", "plugin", self.title,
			{name=name, provider=provider, version=version})
		return true
	end
	return false
end

-- adds base info about a plugin
function Plugin.load(self)
	if not(self.title) then
		return false
	end
	self.name = self.uci:get("plugfons", self.title, "name")
	self.provider = self.uci:get("plugfons", self.title, "provider")
	self.version = self.uci:get("plugfons", self.title, "version")
	return true
end

function Plugin.add_uninstall(self, file)
	if not(self.name and self.title and self.provider and self.version) then
		return false
	end
	self.uci:set("plugfons", self.title, "uninstall", file)
end

function Plugin.delete(self)
	if not(self.name and self.title and self.provider and self.version) then
		return false
	end
	local fs = require("luci.fs")
	local nodel = self.uci:get("plugfons", self.title, "nodel")
	if nodel == "1" then
		return
	end
	local uninstall = self.uci:get("plugfons", self.title, "uninstall")
	if uninstall ~= nil then
		os.execute(uninstall)
	end
	local files = self.uci:get_list("plugfons", self.title, "files")
	for i,v in ipairs(files) do
		print(v)
		fs.unlink(v)
	end
	self.uci:delete("plugfons", self.title)
	self.uci:commit("plugfons")
	return true
end

-- adds a plugin to the dashboard
function Plugin.dashboard(self, icon, order, href)
	if not(self.title) then
		return nil
	end
	if icon and order and href then
		self.uci:set("plugfons", self.title, "dashicon", icon)
		self.uci:set("plugfons", self.title, "order", order)
		self.uci:set("plugfons", self.title, "href", href)
		return true
	end
	return false
end

-- make luci redirct to the plugin
function Plugin.redirect(self)
	self.redirect = true
end

function reapdir(path, relative, modes)
	if not(relative) then
		relative = ""
	end
	local fs = require("luci.fs")
	local files = {}
	modes = modes or {}
	local dirs = fs.dir(path..relative)
	local size = 0
	for i,j in ipairs(dirs) do
		if j ~= "." and j ~= ".." then
			local stat = fs.stat(path..relative.."/"..j)
			modes[relative.."/"..j] = stat.mode
			if stat.type == "directory" then
				local f
				local s
				f,s = reapdir(path, relative.."/"..j, modes)
				size = size + s
				util.append(files, f)
			else
				if stat.type == "regular" then
					size = size + stat.size
				end
				table.insert(files, relative.."/"..j)
			end
		end
	end
	return files, size, modes
end

-- adds files to a plugin
function Plugin.addfiles(self, path)
	if not(self.title) then
		return nil
	end
	self.path = path
	self.files, self.size, self.modes = reapdir(path)
end

-- helper function for getting jffs partition size, with the reserved part already substracted
function get_free_space()
	local luanet = require("luanet")
	local discs = luanet.df()
	local flash
	local total = 0
	function psize_count(s)
		if s.size then
			total = total + tonumber(s.size)
		end
	end

	local uci = require("luci.model.uci").cursor()
	uci:load("plugfons")
	uci:foreach("plugfons", "plugin", psize_count)
	if discs then
		for i,v in ipairs(discs) do
			if v.mountpoint == "/jffs" then
				flash = v
			end
		end
	end
	-- this is flacky, because we rely on it actually being there ....
	flash.blocks = (flash.blocks - tonumber(require("luci.model.uci").cursor():get("system", "fon", "flash") or "250")) * 1024
	flash.avail = flash.blocks - total
	flash.percent = 100 - ((100 * flash.avail) / flash.blocks)
	--os.execute("logger blocks = "..flash.blocks.."   flash.avail="..flash.avail.."   count="..total.. "  flash.percent="..flash.percent)
	return flash
end

-- after all settings were made, we finalize the install with a uci commit
function Plugin.finalize(self, a)
	if not(self.title) then
		return nil
	end
	local jffs = get_free_space(total)
	if jffs.avail < self.size then
		os.exit(2)
	end
	if self.path and self.files and self.size then
		local fs = require("luci.fs")
		for i,j in ipairs(self.files) do
			fs.mkdir(fs.dirname(j), true)
			if fs.stat(self.path..j, "type") == "link" then
				fs.link(fs.readlink(self.path..j), j, true)
			else
				fs.copy(self.path..j, j)
			end
		end
		for file, mode in pairs(self.modes) do
			fs.chmod(file, mode)
		end
		self.uci:set_list("plugfons", self.title, "files", self.files)
		self.uci:set("plugfons", self.title, "size", self.size)
	end
	if self.redirect == true then
		self.uci:set("plugfons", self.title, "redirect", "1")
	end
	self.uci:commit("plugfons")
	return true
end
