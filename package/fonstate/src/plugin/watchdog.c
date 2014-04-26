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
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#include <lib/plugin.h>
#include <lib/log.h>
#include <lib/state.h>

static int counter = 0;
static int wdt = 0;

void kick_the_dog(void)
{
	counter++;
	if(!(counter%5))
	{
		if(!wdt)
		{
			log_printf("opening wdt\n");
			wdt = open("/dev/watchdog", O_WRONLY);
			return;
		}
		write(wdt, "", 1);
	}
}

int watchdog_start(void)
{
	log_printf("starting usbstatus fonstate plugin\n");
	add_ping(kick_the_dog);
	return 0;
}

int fonstate_plugin_register(void *p)
{
	struct fs_ctx *c = (struct fs_ctx*)p;
	c->start = watchdog_start;
	c->daemon = 0;
	return FS_V1;
}
