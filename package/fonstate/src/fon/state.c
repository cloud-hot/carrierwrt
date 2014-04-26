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
#include <dirent.h>

#include <lib/log.h>
#include <lib/uci.h>
#include <lib/sys.h>
#include <lib/state.h>
#include <lib/ps.h>

#define MAX_PATH		256

struct list_head fontimers;
struct list_head fonqueue;
struct list_head fonevents;
struct list_head fonpings;

static struct uci_context *ctx;

void dump_queue(void)
{
	FILE *fp = fopen("/tmp/fonstate.queue", "w");
	struct list_head *p;
	if(!fp)
	{
		log_printf("Failed to dump state queue\n");
		return;
	}
	list_for_each(p, &fonqueue)
	{
		struct fonqueue *q = container_of(p, struct fonqueue, list);
		if(q->event)
			fprintf(fp, "%s\n", q->event->event);
		else
			fprintf(fp, "%s\n", q->cmdline);
	}
	fclose(fp);
}

struct fonevent* find_event(const char *event)
{
	struct list_head *p;
	list_for_each(p, &fonevents)
	{
		struct fonevent *e = container_of(p, struct fonevent, list);
		if(!strcmp(event, e->event))
			return e;
	}
	return 0;
}

void enqueue_job(const char *q)
{
	struct fonqueue *f;
	struct fonevent *e;
	log_printf("enqueue --> %s\n", q);
	e = find_event(q);
	if(e)
	{
		if(e->fast)
		{
			log_printf("running fast event %s\n", e->event);
			if(e->eventcb)
				e->eventcb();
			else
				system_printf("%s 2> /dev/null", e->action);
			return;
		}
	}
	f = malloc(sizeof(struct fonqueue));
	INIT_LIST_HEAD(&f->list);
	if(e)
	{
		f->event = e;
	} else {
		f->event = 0;
		strncpy(f->cmdline, q, 128);
	}
	list_add_tail(&f->list, &fonqueue);
	dump_queue();
}

struct fonqueue *pop_queue()
{
	struct fonqueue *q;
	if(list_empty(&fonqueue))
		return 0;
	q = container_of(fonqueue.next, struct fonqueue, list);
	fonqueue.next = q->list.next;
	q->list.next->prev = &fonqueue;
	dump_queue();
	return q;
}

void add_timer(const char *a, const char *f, int p, timercb_t cb)
{
	struct fontimer *t;
	t = malloc(sizeof(struct fontimer));
	INIT_LIST_HEAD(&t->list);
	if(a)
		strcpy(t->action, a);
	else
		t->action[0] = '\0';
	if(f)
		strcpy(t->pidfile, f);
	else
		t->pidfile[0] = '\0';
	t->period = p * 5;
	t->count = 0;
	t->timercb = cb;
	list_add_tail(&t->list, &fontimers);
	if(cb)
		log_printf("added fontimer libcallback period=%d\n", p);
}

void load_timers(const char *name, void *priv)
{
	const char *a = ucix_get_option(ctx, "fonstate", name, "action");
	const char *f = ucix_get_option(ctx, "fonstate", name, "pidfile");
	int p = ucix_get_option_int(ctx, "fonstate", name, "period", 0);

	if(!a || !p)
		return;
	add_timer(a, f, p, 0);
	log_printf("loaded fontimer for \"%s\" period=%d\n", a, p);
}

void add_event(const char *e, const char *a, eventcb_t cb, int fast)
{
	struct fonevent *f;
	f = malloc(sizeof(struct fonevent));
	INIT_LIST_HEAD(&f->list);
	strcpy(f->event, e);
	if(a)
		strcpy(f->action, a);
	else
		f->action[0] = '\0';
	f->eventcb = cb;
	f->fast = fast;
	list_add_tail(&f->list, &fonevents);
	if(cb)
		log_printf("added fonevent %s -> libcallback %d\n", e, fast);

}

void load_events(const char *name, void *priv)
{
	const char *e = ucix_get_option(ctx, "fonstate", name, "event");
	const char *a = ucix_get_option(ctx, "fonstate", name, "action");
	int f = ucix_get_option_int(ctx, "fonstate", name, "fast", 0);
	if(!a || !e)
		return;
	add_event(e, a, 0, f);
	log_printf("loaded fonevent %s -> \"%s\"\n", e, a);
}

void load_uci()
{
	INIT_LIST_HEAD(&fontimers);
	INIT_LIST_HEAD(&fonqueue);
	INIT_LIST_HEAD(&fonevents);
	INIT_LIST_HEAD(&fonpings);
	ctx = ucix_init("fonstate");
	ucix_for_each_section_type(ctx, "fonstate", "fontimer", load_timers, NULL);
	ucix_for_each_section_type(ctx, "fonstate", "fonevent", load_events, NULL);
}

void load_boot(const char *name, void *priv)
{
	const char *e = ucix_get_option(ctx, "fonstate", name, "event");
	if(!e)
		return;
	enqueue_job(e);
}

void enqueue_boot_jobs(void)
{
	ucix_for_each_section_type(ctx, "fonstate", "fonboot", load_boot, NULL);
}

void process_queue()
{
	struct fonqueue *q;
	while((q = pop_queue()))
	{
		if(q->event)
		{
			log_printf("running event %s\n", q->event->event);
			if(q->event->eventcb)
				q->event->eventcb();
			else
				system_printf("%s > /dev/null <&1 2>&1", q->event->action);
			log_printf("finished running\n");

		}
		if(q->cmdline)
		{
			log_printf("running event /etc/fonstated/%s\n", q->cmdline);
			system_printf("/etc/fonstated/%s > /dev/null <&1 2>&1", q->cmdline);
			log_printf("finished running /etc/fonstated/%s\n", q->cmdline);
		}

		free(q);
	}
}

void process_wdt(struct fontimer *t)
{
	FILE *fp = fopen(t->pidfile, "r");
	int pid;
	char p[MAX_PATH];
	if(!fp)
		goto restart;
	fgets(p, MAX_PATH, fp);
	pid = atoi(p);
	fclose(fp);
	if(!ps_find(pid))
		goto restart;
	return;

restart:
	system_printf("%s start 2> /dev/null", t->action);
}

void process_timers()
{
	struct list_head *p;
	list_for_each(p, &fontimers)
	{
		struct fontimer *t = container_of(p, struct fontimer, list);
		if((++t->count)%t->period == 0)
		{
			if(strlen(t->pidfile))
				process_wdt(t);
			else if(t->timercb)
				t->timercb();
			else
				system_printf("%s 2> /dev/null", t->action);
		}
	}
}

void add_ping(timercb_t timercb)
{
	struct fonping *f = malloc(sizeof(struct fonping));
	INIT_LIST_HEAD(&f->list);
	f->timercb = timercb;
	list_add_tail(&f->list, &fonpings);
}

void state_ping()
{
	struct list_head *p;
	list_for_each(p, &fonpings)
	{
		struct fonping *q = container_of(p, struct fonping, list);
		if(q)
			q->timercb();
	}
}
