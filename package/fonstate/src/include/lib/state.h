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

#ifndef _STATE_H__
#define _STATE_H__

#include <lib/list.h>

typedef void (*timercb_t)(void);
typedef void (*eventcb_t)(void);

struct fontimer {
	struct list_head list;
	char action[64];
	char pidfile[64];
	int period;
	int count;
	timercb_t timercb;
};

struct fonevent {
	struct list_head list;
	char event[64];
	char action[64];
	int fast;
	eventcb_t eventcb;
};

struct fonqueue {
	struct list_head list;
	struct fonevent *event;
	char cmdline[128];
};

struct fonping {
	struct list_head list;
	timercb_t timercb;
};

void add_event(const char *event, const char *action, eventcb_t cb, int fast);
void add_timer(const char *a, const char *f, int p, timercb_t cb);
void enqueue_job(const char *name);
void load_uci();
void process_queue();
void process_timers();
void state_ping();
void add_ping(timercb_t timercb);
void enqueue_boot_jobs(void);
#endif
