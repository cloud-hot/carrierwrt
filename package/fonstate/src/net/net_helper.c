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
#include <arpa/nameser.h>
#include <resolv.h>

#include <lib/log.h>
#include <lib/plugin.h>
#include <lib/state.h>
#include <lib/socket.h>
#include <lib/net_helper.h>

int connect_timeout(int sfd, struct sockaddr *addr, int addrlen, struct timeval *timeout)
{
	struct timeval sv;
	unsigned int svlen = sizeof sv;
	int ret;

	if(!timeout)
		return connect (sfd, addr, addrlen);
	if(getsockopt (sfd, SOL_SOCKET, SO_SNDTIMEO, (char *)&sv, &svlen) < 0)
		return -1;
	if(setsockopt (sfd, SOL_SOCKET, SO_SNDTIMEO, timeout,sizeof *timeout) < 0)
		return -1;
	ret = connect (sfd, addr, addrlen);
	return ret;
}

int test_url(char *url, char *file, char *buf, int len, int port)
{
	struct timeval tv;
	int fd = 0;
	struct hostent *he;
	struct sockaddr_in their_addr;
	int retval = 0;
	char xmit[256];
	/* work around a bug in uclibc 
	 * res_init resets internal state
	 */
	res_init();
	if((he = gethostbyname(url)) == 0)
		goto out;
	if((fd = socket(PF_INET, SOCK_STREAM, 0)) == -1)
		goto out;
	their_addr.sin_family = AF_INET;
	their_addr.sin_port = htons(port);
	their_addr.sin_addr = *((struct in_addr *)(he->h_addr));
	memset(&(their_addr.sin_zero), '\0', 8);
	tv.tv_sec = 15;
	tv.tv_usec = 0;
	if (connect_timeout(fd, (struct sockaddr *)&their_addr,
		sizeof(struct sockaddr), &tv) == -1)
		goto out;
	sprintf(xmit, "GET %s HTTP/1.0\r\nHost: %s\r\nUser-Agent: LaFonera2.0\r\nAccept: */*\r\n\r\n", file, url);
	if(send(fd, xmit, strlen(xmit), 0) < 1)
		goto out;
	retval = recv(fd, buf, len - 1, 0);
	buf[retval] = '\0';
out:
	if(fd > 0)
		close(fd);
	return retval;
}
