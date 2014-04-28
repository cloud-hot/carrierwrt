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
#include <errno.h>

#include "net_helper.h"

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

int test_dns(char *host)
{
	/* work around a bug in uclibc
	 * res_init resets internal state
	 */
	res_init();
	if(gethostbyname(host) == 0) {
		syslog(0, "onlined: failed to resolve hostname %s: %s\n", host, strerror(errno));
		return 0;
	}
	return 1;
}
