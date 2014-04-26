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
#include <signal.h>

#include <lib/plugin.h>
#include <lib/state.h>

void handler_INT(int signo)
{
	kill_plugins();
	exit(0);
}

void handler_ALRM(int signo)
{
	alarm(1);
	state_ping();
}

void setup_signals(void)
{
	struct sigaction s1, s2;
	s1.sa_handler = handler_INT;
	s1.sa_flags = 0;
	sigaction(SIGINT, &s1, NULL);
	s2.sa_handler = handler_ALRM;
	s2.sa_flags = 0;
	sigaction(SIGALRM, &s2, NULL);
	alarm(1);
}
