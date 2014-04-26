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
#include <dlfcn.h>
#include <sys/types.h>
#include <dirent.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <unistd.h>
#include <signal.h>

#include <lib/plugin.h>
#include <lib/log.h>
#include <lib/list.h>

struct fonpid {
	struct list_head list;
	int pid;
};

struct list_head fonpids;

int do_load_plugin(char *path, char *filename)
{
	char tmp[128];
	void *d;
	plugin_register cb;
	struct fs_ctx c;
	int v;
	int p;

	snprintf(tmp, 128, "%s%s", path, filename);
	d = dlopen(tmp, RTLD_NOW);
	if(!d)
	{
		log_printf("failed to open %s\n", tmp);
		dlerror();
		return 1;
	}
	cb = (plugin_register)(int)dlsym(d, "fonstate_plugin_register");
	if(!cb)
	{
		log_printf("missing symbol fonstate_plugin_register in %s\n", tmp);
		dlerror();
		return 1;
	}
	v = cb((void*)&c);
	if(c.daemon)
	{
		if(!(p = fork()))
		{
			if(c.start())
	            log_printf("failed to start %s\n", tmp);
			exit(0);
		} else {
			struct fonpid *f = malloc(sizeof(struct fonpid));
			list_add(&f->list, &fonpids);
		}
	} else {
		if(c.start())
			log_printf("failed to start %s\n", tmp);
	}
	return 0;
}

int dir_sort(const struct dirent **a, const struct dirent **b)
{
	if(((*(const struct dirent **) a)->d_type & DT_DIR) &&
		((*(const struct dirent **) b)->d_type & DT_DIR) == 0)
		return 1;
	if(((*(const struct dirent **) a)->d_type & DT_DIR) == 0 &&
		((*(const struct dirent **) b)->d_type & DT_DIR))
		return -1;
	return 0 - strcasecmp((*(const struct dirent **) a)->d_name,
		(*(const struct dirent **) b)->d_name);
}

int dir_filter(const struct dirent *a)
{
	if(strncmp(a->d_name, "fonstate_", 9))
		return 0;
	return (strstr(a->d_name, ".so"))?(1):(0);
}

int load_plugins(void)
{
	int ret = 0;
	struct dirent **namelist;
	int n = scandir(DEFAULT_PLUGIN_DIR,
		&namelist, dir_filter, dir_sort);
	INIT_LIST_HEAD(&fonpids);
	if(n > 0)
	{
		while(n--)
		{
			if(do_load_plugin(DEFAULT_PLUGIN_DIR, namelist[n]->d_name))
				log_printf("failed to load %s\n", namelist[n]->d_name);
		}
		free(namelist);
	}
	return ret;
}

void kill_plugins(void)
{
	struct list_head *p;
	list_for_each(p, &fonpids)
	{
		struct fonpid *q = container_of(p, struct fonpid, list);
		kill(q->pid, SIGKILL);
	}

}
