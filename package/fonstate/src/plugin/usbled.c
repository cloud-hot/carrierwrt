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
#include <lib/uci.h>
#include <lib/plugin.h>
#include <lib/log.h>
#include <lib/state.h>

char usbled[16];

int led_start()
{
	FILE *fp;
	int last = 0;

	log_printf("starting usbled fonstate plugin\n");
	while(1)
	{
		static struct uci_context *ctx;
		int mounted, count;
		int led = 1;
		char path[256];
		ctx = ucix_init("mountd");
		mounted = ucix_get_option_int(ctx, "mountd", "mountd", "mounted", 0);
		count = ucix_get_option_int(ctx, "mountd", "mountd", "count", 0);
		ucix_cleanup(ctx);
		if(!count)
			led = 0;
		if(count && !mounted)
			led = 1;
		if(count && mounted)
			last = led = (last + 1) % 2;
		snprintf(path, 256, "/sys/class/leds/%s/brightness", usbled);
		fp = fopen(path, "w");
		if(fp)
		{
			fprintf(fp, "%d", led);
			fclose(fp);
		}
		sleep(1);
	}
	return 0;
}

int fonstate_plugin_register(void *p)
{
	struct fs_ctx *c = (struct fs_ctx*)p;
	const char *tmp;
	static struct uci_context *ctx;
	c->start = led_start;
	c->daemon = 1;
	ctx = ucix_init("system");
	tmp = ucix_get_option(ctx, "system", "usb", "sysfs");
	ucix_cleanup(ctx);
	if(tmp)
	{
		strncpy(usbled, tmp, 16);
	} else {
		syslog(0, "failed to read system.usb.sysfs");
		usbled[0] = '\0';
	}
	return FS_V1;
}
