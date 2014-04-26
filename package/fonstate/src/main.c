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
#include <libgen.h>
#include <sys/wait.h>

#include <lib/log.h>
#include <lib/uci.h>
#include <lib/sys.h>
#include <lib/state.h>
#include <lib/socket.h>
#include <lib/plugin.h>
#include <lib/signal.h>
#include <lib/ps.h>

#define FS_VER			"2.0"

int daemonize = 0;
/* Allow the ident to be different depending on how we're called
 * (fonstated or fonstate / fs) */
const char *log_ident = "";

int usage(const char *argv)
{
	printf("Usage: %s [OPTION]\n", argv);
	printf("Send commands to FONstate daemon\n\n");
	printf("-v\t\tdisplay version information and exit\n");
	printf("-h\t\tdisplay this help and exit\n");
	printf("-l <runlevel>\task to FONstate daemon for change state to runlevel\n");
	printf("-s\t\tshows current runlevel\n");
	return 0;
}

int main_client(int argc, char **argv)
{
	int c;
	FILE *fp;

	while((c = getopt(argc, argv, "vhl:s")) != -1)
		switch(c) {
		case 'v':
			printf("fonstate client v%s\n", FS_VER);
			break;
		case 'l':
			if (!daemonize) {
			    daemon(0, 0);
			    daemonize = 1;
			}
			issue_command(optarg);
			break;
		case 's':
			fp = fopen("/tmp/run/fonstate", "r");
			if(fp)
			{
				char t[64];
				fgets(t, 64, fp);
				fclose(fp);
				printf("%s\n", t);
			} else {
				printf("ERROR\n");
			}
			break;
		default:
			usage(argv[0]);
			exit(1);
			break;
		}
	return 0;
}

int main(int argc, char **argv)
{
	int c;
	char *t;

	t = basename(argv[0]);
	log_ident = strdup(t);
	if((!strcmp(t, "fonstate")) || (!strcmp(t, "fs")))
		return main_client(argc, argv);

	c = getopt(argc, argv, "D");
	switch(c) {
	case 'D':
		daemon(0,0);
		daemonize = 1;
		break;
	}

	log_printf("fonstated - v%s\n", FS_VER);
	write_pid();
	load_uci();
	load_plugins();
	fon_socket_setup();
	ps_init();
	setup_signals();
	enqueue_boot_jobs();
	while(1)
	{
		fon_socket_handle();
		process_queue();
		process_timers();
		poll(0, 0, 200);
		waitpid(-1, 0, WNOHANG);
	}

	return 0;
}
