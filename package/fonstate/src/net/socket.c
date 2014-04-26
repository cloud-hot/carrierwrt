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

#include <sys/socket.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/poll.h>
#include <stdarg.h>
#include <fcntl.h>
#include <lib/state.h>
#include <lib/log.h>

#define SOCKET_PATH "/tmp/fonstated.sock"

typedef struct _FON_NIX_SOCKET {
	int listener;
} FON_NIX_SOCKET;

static FON_NIX_SOCKET fon_socket;

int fon_socket_setup(void)
{
	struct sockaddr_un myaddr;
	int yes=1;
	int len;

	if((fon_socket.listener = socket(AF_UNIX, SOCK_DGRAM, 0)) == -1)
	{
		log_printf("Failed to open socket: %s\n", strerror(errno));
		return 1;
	}
	if (setsockopt(fon_socket.listener, SOL_SOCKET,
				SO_REUSEADDR, &yes, sizeof(int)) == -1)
	{
		log_printf("Failed to set socket options: %s\n", strerror(errno));
		return 1;
	}
	myaddr.sun_family = AF_UNIX;
	strcpy(myaddr.sun_path, SOCKET_PATH);
	unlink(myaddr.sun_path);
	len = strlen(myaddr.sun_path) + sizeof(myaddr.sun_family);
	if(bind(fon_socket.listener, (struct sockaddr *)&myaddr, len) == -1)
	{
		log_printf("Failed to bind socket to path (%s): %s\n", myaddr.sun_path, strerror(errno));
		return 1;
	}
	fcntl(fon_socket.listener, F_SETFL, O_NONBLOCK);
	return 0;
}

int fon_socket_handle(void)
{
	char buf[1024];
	int nbytes;
	while((nbytes = recv(fon_socket.listener, buf, sizeof(buf), 0)) > 0)
	{
		buf[nbytes] = '\0';
		enqueue_job(buf);
	}
	return 0;
}

void issue_command(char *str)
{
	int s, len;
	struct sockaddr_un remote;

	if((s = socket(AF_UNIX, SOCK_DGRAM, 0)) == -1)
	{
		log_printf("Failed to open socket: %s\n", strerror(errno));
		return;
	}
	remote.sun_family = AF_UNIX;
	strcpy(remote.sun_path, SOCKET_PATH);
	len = strlen(remote.sun_path) + sizeof(remote.sun_family);
	if(connect(s, (struct sockaddr *)&remote, len) == -1)
	{
		log_printf("Failed to connect to socket (%s): %s\n", remote.sun_path, strerror(errno));
		goto out;
	}
	if(send(s, str, strlen(str), 0) == -1)
	{
		log_printf("Failed to send message (%s): %s\n", str, strerror(errno));
		goto out;
	}
out:
	close(s);
	return;
}
