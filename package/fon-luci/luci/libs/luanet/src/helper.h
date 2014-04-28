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

#ifndef _HELPER_H__
#define _HELPER_H__

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

int char2ipv4(char *c, char *ip);
void ipv42char(char *b, char *ip);
void mac2char(char *b, char *mac);
void add_table_entry(lua_State *L, const char *k, const char *v);
void add_table_entry_int(lua_State *L, const char *k, int v);

#endif
