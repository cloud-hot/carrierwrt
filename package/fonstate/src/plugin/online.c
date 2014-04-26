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
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <stdarg.h>
#include <syslog.h>
#include <string.h>
#include <poll.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <netdb.h>

#include <lib/log.h>
#include <lib/plugin.h>
#include <lib/state.h>
#include <lib/socket.h>
#include <lib/net_helper.h>

#define SERVER_FON		"updates.fon.com"
#define PATH_FON		"/firmware/conncheck/conncheck.txt"
#define SERVER_GOOGLE	"www.google.com"
#define PATH_GOOGLE		"/index.html"
#define TOUT_OFFLINE	1
#define TOUT_ONLINE		10

int daemonize = 0;

void send_cmd(char *c)
{
	log_printf("new online state %s\n", c);
	issue_command(c);
}

static char curr_state[16];
int online_start()
{
	int g, f, count = 0;
	char tmp[1024];
	FILE *fp;
	log_printf("starting online fonstate plugin\n");
	sprintf(curr_state, "Offline");
	while(1)
	{
		if(!strcmp(curr_state, "Online") && count > TOUT_ONLINE)
		{
			g = test_url(SERVER_GOOGLE, PATH_GOOGLE, tmp, 1024, 80);
			f = test_url(SERVER_FON, PATH_FON, tmp, 1024, 80);
			/*log_printf("g: %d f: %d\n", g, f);*/
			if(!g && !f)
				send_cmd("Offline");
			count = 0;
		}
		if(!strcmp(curr_state, "Offline") && count > TOUT_OFFLINE)
		{
			f = 0;
			g = test_url(SERVER_GOOGLE, PATH_GOOGLE, tmp, 1024, 80);
			if(!g)
				f = test_url(SERVER_FON, PATH_FON, tmp, 1024, 80);
			/*log_printf("g: %d f: %d\n", g, f);*/
			if(g || f)
				send_cmd("Online");
			count = 0;
		}
		poll(0, 0, 1000);
		count++;
		fp = fopen("/tmp/run/fonstate", "r");
		if(fp)
		{
			fgets(curr_state, 16, fp);
			fclose(fp);
		}
	}
	return 0;
}

int fonstate_plugin_register(void *p)
{
	struct fs_ctx *c = (struct fs_ctx*)p;
	c->start = online_start;
	c->daemon = 1;
	return FS_V1;
}
