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

#ifndef _IFCONFIG_H__
#define _IFCONFIG_H__
int ifc_startup(void);
void ifc_shutdown(void);

int ifc_getall(lua_State *L);
int ifc_setip(lua_State *L);
int ifc_setnetmask(lua_State *L);
int ifc_setbroadcast(lua_State *L);
int ifc_setmtu(lua_State *L);
int ifc_up(lua_State *L);
int ifc_down(lua_State *L);
#endif
