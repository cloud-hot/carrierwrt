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

#ifndef _PLUGIN_H__
#define _PLUGIN_H__

#define FS_V1	1

#define DEFAULT_PLUGIN_DIR "/usr/lib/fonstate/"

typedef int(*plugin_register)(void *p);
typedef int(*plugin_start)(void);

struct fs_ctx
{
	int daemon;
	plugin_start start;
};

int load_plugins(void);
void kill_plugins(void);

#endif
