module("luci.controller.upgrade", package.seeall)

function index()
	require("luci.i18n")
	local i18n = luci.i18n.translate
	luci.i18n.loadc("fwupgrade")

	local e = entry({"upgrader"}, call("fwupgrade"), luci.i18n.translate("upgrader_title", "Upgrade"))
	e.i18n = "fwupgrade"

	local e = entry({"upgrade_error"}, template("upgrade/main"), luci.i18n.translate("upgrader_title", "Upgrade"))
	e.i18n = "fwupgrade"

	local e = entry({"upgrade_noinet"}, template("upgrade/noinet"), luci.i18n.translate("upgrader_title", "Upgrade"))
	e.i18n = "fwupgrade"

	local page  = node("fwupgrade")
	page.target = call("fwupgrade")
end

function fwupgrade()
	local tmpfile = "/tmp/image/update.img"
	if not(require("luci.fon").state.online()) then
		return require("luci.http").redirect(require("luci.dispatcher").build_url("upgrade_noinet"))
	end
	os.execute("mkdir /tmp/image/")
	local r
	if require("luci.model.uci").cursor():get("registered", "fonreg", "dev") == "1" then
		r = os.execute("wget http://download.fonosfera.org/Elan/20090921_FON2303_2.3.0.0_DEV.tgz -O "..tmpfile)
	else
		r = os.execute("wget http://download.fonosfera.org/Elan/20090921_FON2303_2.3.0.0.tgz -O "..tmpfile)
	end
	if r == 0 then
		local verify = require("luci.fon.pkg.verify")
		local str, key, err = verify.fonidentify(tmpfile)
		if str == "reflash" then
			local dir, str = verify.fonverify(tmpfile, "/etc/fon/keyring/", false)
			if dir ~= nil then
				local uci = require("luci.model.uci").cursor_state()
				uci:set("fon", "state", "upgrade", dir)
				uci:save("fon")
				require("luci.fon.event").new("FlashDevice")
				return luci.http.redirect(luci.dispatcher.build_url("upgrading"))
			end
		end
	end
	return require("luci.http").redirect(require("luci.dispatcher").build_url("upgrade_error"))
end

