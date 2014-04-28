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

#ifndef _IWCONFIG_H__
#define _IWCONFIG_H__
int iwc_startup(void);
void iwc_shutdown(void);
int iwc_get(lua_State *L);
int iwc_getall(lua_State *L);
int iwc_set_essid(lua_State *L);
int iwc_set_mode(lua_State *L);
int iwc_set_channel(lua_State *L);
int iwc_scan(lua_State *L);
#endif