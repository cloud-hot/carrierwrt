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

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

int char2ipv4(char *c, char *ip)
{
	int i;
	char *tmp = strdup(c);
	char *t = tmp;
	char *e = NULL;
	int ret = -1;
	for(i = 0; i < 4; i++)
	{
		int j = strtol(t, &e, 10);
		if((j < 0) || (j > 255))
			goto error;
		if(i != 3)
			if(*e != '.')
				goto error;
		*ip++ = j;
		t = e + 1;
	}
	ret = 0;
error:
	free(tmp);
	return ret;
}

void ipv42char(char *b, char *ip)
{
	sprintf(ip, "%d.%d.%d.%d", b[0] & 0xff, b[1] & 0xff, b[2] & 0xff, b[3] & 0xff);
}

void mac2char(char *b, char *mac)
{
	sprintf(mac, "%02X:%02X:%02X:%02X:%02X:%02X",
		b[0] & 0xff, b[1] & 0xff, b[2] & 0xff, b[3] & 0xff, b[4] & 0xff, b[5] & 0xff);
}

void add_table_entry(lua_State *L, const char *k, const char *v)
{
	lua_pushstring(L, k);
	lua_pushstring(L, v);
	lua_settable(L, -3);
}

void add_table_entry_int(lua_State *L, const char *k, int v)
{
	lua_pushstring(L, k);
	lua_pushinteger(L, v);
	lua_settable(L, -3);
}
