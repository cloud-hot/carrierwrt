/*
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, write to the Free Software
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
 *
 *   Copyright (C) 2008 John Crispin <blogic@openwrt.org> 
 *   Copyright (C) 2008 Steven Barth <steven@midlink.org>
 */

#include <stdio.h>
#include <unistd.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "route.h"
#include "bridge.h"
#include "ifconfig.h"
#include "iwconfig.h"
#include "vconfig.h"
#include "df.h"
#include "base64.h"
#include "uptime.h"
#include "df.h"

int psleep(lua_State *L)
{
	int s;
	if(lua_gettop(L) != 1)
	{
		lua_pushstring(L, "invalid arg list");
		lua_error(L);
		return 0;
	}

	s = (int)lua_tointeger (L, 1);
	sleep(s);
	return 0;
}

static luaL_reg func[] = {
	{"ifc_getall", ifc_getall},
	{"ifc_setip", ifc_setip},
	{"ifc_setnetmask", ifc_setnetmask},
	{"ifc_setbroadcast", ifc_setbroadcast},
	{"ifc_setmtu", ifc_setmtu},
	{"ifc_up", ifc_up},
	{"ifc_down", ifc_down},
	{"bridge_getall", bridge_getall},
	{"bridge_new", bridge_new},
	{"bridge_del", bridge_del},
	{"bridge_addif", bridge_addif},
	{"bridge_delif", bridge_delif},
	{"iwc_getall", iwc_getall},
	{"iwc_set_essid", iwc_set_essid},
	{"iwc_set_mode", iwc_set_mode},
	{"iwc_set_channel", iwc_set_channel},
	{"iwc_scan", iwc_scan},
	{"vlan_getall", vlan_getall},
	{"vlan_add", vlan_add},
	{"vlan_del", vlan_del},
	{"df", df},
	{"b64_encode", b64_encode},
	{"b64_decode", b64_decode},
	{"sleep", psleep},
	{"uptime", uptime},
	{"df_used", df_used},
	{"gettimeofday", Lgettimeofday},
	{NULL, NULL}
};

int luaopen_luanet(lua_State *L)
{
	ifc_startup();
	bridge_startup();
	iwc_startup();
	luaL_openlib(L, "luanet", func, 0);
	lua_pushstring(L, "_VERSION");
	lua_pushstring(L, "1.0");
	lua_rawset(L, -3);
	return 1;
}

int luaclose_luanet(lua_State *L)
{
	ifc_shutdown();
	bridge_shutdown();
	iwc_shutdown();
	lua_pushstring(L, "Called");
	return 1;
}
