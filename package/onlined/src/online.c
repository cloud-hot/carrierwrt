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

#include "net_helper.h"
#include "sys.h"

#define SERVER_FON      "www.fon.com"
/* While offline, check every second */
#define INTERVAL_OFFLINE_MIN   1
/* But after every 60 seconds, double the delay time */
#define INTERVAL_OFFLINE_DOUBLE_TIME 60
/* Until the delay reaches 64 seconds */
#define INTERVAL_OFFLINE_MAX  64
/* While online, check every 60 seconds */
#define INTERVAL_ONLINE       60
/* But after the first error, check again every second */
#define INTERVAL_ERROR        1
/* And go offline after getting five subsequent errors */
#define ERRORS_NEEDED      5

void send_cmd(char *c)
{
	syslog(0, "new online state %s\n", c);
	system_printf("fs -l %s", c);
}

static char curr_state[16];
int online_start()
{
	int error_count = 0, is_online = 0;
	/* Make sure we do a test request directly on startup */
	int delay = 0;
	/* Give these sane values in case we get started while we're
	 * offline */
	int double_delay = INTERVAL_OFFLINE_DOUBLE_TIME, offline_interval = INTERVAL_OFFLINE_MIN;
	FILE *fp;
	syslog(0, "starting onlined\n");
	sprintf(curr_state, "Offline");
	delay = 0;
	while(1)
	{
		/* When we're offline, we double the interval between
		 * checks every so many seconds. */
		if (!is_online && offline_interval < INTERVAL_OFFLINE_MAX && --double_delay == 0)
		{
				offline_interval *= 2;
				double_delay = INTERVAL_OFFLINE_DOUBLE_TIME;
		}

		if (delay == 0) {
			/* Do a test request */
			int success = test_dns(SERVER_FON);

			if (!success)
			{
				if (is_online) {
					/* Only count errors while we're online, to prevent
					 * overflowing the counter on long periods of
					 * offline-ness */
					error_count++;
					syslog(0, "onlined: Check failed. Error count: %d\n", error_count);

					/* If enough subsequent errors have occured, go offline */
					if (error_count >= ERRORS_NEEDED)
					{
						send_cmd("Offline");
						delay = offline_interval = INTERVAL_OFFLINE_MIN;
						double_delay = INTERVAL_OFFLINE_DOUBLE_TIME;
					}
					else
					{
						delay = INTERVAL_ERROR;
					}
				}
				else
				{
					/* When we're offline, the delay
					 * is dynamic and determined
					 * above */
					delay = offline_interval;
				}
			}
			else
			{
				if (!is_online)
					/* We were offline. This success makes us go online
					 * again. */
					send_cmd("Online");
				else if (error_count)
					/* We've seen a few errors before this success, but
					 * not enough to go offline apparently */
					syslog(0, "onlined: Check ok, resetting error count\n");

				/* Always reset the error counter on success, so we
				 * restart counting after every successful check */
				error_count = 0;

				/* And switch back to the slower checking interval */
				delay = INTERVAL_ONLINE;
			}
		}

		/* Wait for one second */
		poll(0, 0, 1000);
		delay--;
		/* Reread the current online state (something external might
		 * have changed it. */
		fp = fopen("/tmp/run/fonstate", "r");
		if(fp)
		{
			fgets(curr_state, 16, fp);
			fclose(fp);
			is_online = !strcmp(curr_state, "Online");
		}
	}
	return 0;
}

int main(int argc, char **argv)
{
	return online_start();
}
