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
 *   Provided by fon.com
 *   Copyright (C) 2008 John Crispin <blogic@openwrt.org> 
 */

#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#define FON_VERSION "0.0.1"

static int fr_detachconsole(lua_State *L)
{
	int null = open("/dev/null", O_RDWR);
	if(null)
	{
		dup2(null, 0);
		dup2(null, 1);
	}
	return 1;
}

static luaL_reg func[] = {
    {"detachconsole", fr_detachconsole},
    {NULL, NULL}
};

int luaopen_fon(lua_State *L)
{
	luaL_openlib(L, "fon", func, 0);
	lua_pushstring(L, "_VERSION");
	lua_pushstring(L, FON_VERSION);
	lua_rawset(L, -3);
	return 1;
}

int luaclose_fon(lua_State *L)
{
	lua_pushstring(L, "Called");
	return 1;
}
