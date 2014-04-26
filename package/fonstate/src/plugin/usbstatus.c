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

#include <stdio.h>
#include <syslog.h>
#include <unistd.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <lib/plugin.h>
#include <lib/log.h>
#include <lib/state.h>
#include <lib/ps.h>

void usb_status_ping(void)
{
	
}

int usb_status_start(void)
{
	log_printf("starting usbstatus fonstate plugin\n");
	add_ping(usb_status_ping);
	return 0;
}

int fonstate_plugin_register(void *p)
{
	struct fs_ctx *c = (struct fs_ctx*)p;
	c->start = usb_status_start;
	c->daemon = 0;
	return FS_V1;
}
