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
 *   Copyright (C) 2008 John Crispin <blogic@openwrt.org> 
 *   Copyright (C) 2008 Steven Barth <steven@midlink.org>
 */

#include <linux/sockios.h>
#include <net/route.h>
#include <sys/ioctl.h>

#include "helper.h"

extern int sock_ifconfig;

int route_add(char *dev, int flag_gateway, int flag_host, char *dst, char *gateway, char *mask)
{
	struct rtentry r;
	char ip[4];
	r.rt_flags = RTF_UP;
	if(flag_gateway)
		r.rt_flags |= RTF_GATEWAY;
	if(flag_host)
		r.rt_flags |= RTF_HOST;
	r.rt_dst.sa_family = AF_INET;
	r.rt_gateway.sa_family = AF_INET;
	r.rt_genmask.sa_family = AF_INET;
	char2ipv4(dst, ip);
	((struct sockaddr_in *) &r.rt_dst)->sin_addr.s_addr = (unsigned int)ip;
	char2ipv4(gateway, ip);
	((struct sockaddr_in *) &r.rt_gateway)->sin_addr.s_addr = (unsigned int)ip;
	char2ipv4(mask, ip);
	((struct sockaddr_in *) &r.rt_genmask)->sin_addr.s_addr = (unsigned int)ip;
	return ioctl(sock_ifconfig, SIOCADDRT, (void *) &r);
}
