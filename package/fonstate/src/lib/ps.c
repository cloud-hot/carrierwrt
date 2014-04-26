#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <dirent.h>
#include <libgen.h>

#include <lib/state.h>

struct pstable
{
	char proc[64];
	int pid;
};

struct pstable pstable[128];
int pstabel_count = 0;

int numeric(char *a)
{
	while(*a)
	{
		if(!((*a >= '0') && (*a <= '9')))
			return 1;
		a++;
	}
	return 0;
}
void ps(void)
{
	int n;
	struct dirent **namelist;
	n = scandir("/proc/", &namelist, 0, 0);
	pstabel_count = 0;
	if(n)
	{
		while(n--)
		{
			if(namelist[n]->d_type & DT_DIR)
			{
				if(!numeric(namelist[n]->d_name))
				{
					FILE *fp;
					char tmp[64];
					sprintf(tmp, "/proc/%s/cmdline", namelist[n]->d_name);
					fp = fopen(tmp, "r");
					if(fp)
					{
						char *i = fgets(tmp, 64, fp);
						if(i)
						{
							if(pstabel_count < 128)
							{
								pstable[pstabel_count].pid = atoi(namelist[n]->d_name);
								strcpy(pstable[pstabel_count].proc, basename(tmp));
								pstabel_count++;
							}
						}
						fclose(fp);
					}
				}
			}
			free(namelist[n]);
		}
		free(namelist);
	}
}

void ps_dump(void)
{
	int i;
	for(i = 0; i < pstabel_count; i++)
	{
		printf("%d %s\n", pstable[i].pid, pstable[i].proc);
	}
}

char *ps_find(int pid)
{
	int i;
	for(i = 0; i < pstabel_count; i++)
	{
		if(pstable[i].pid == pid)
		{
			return pstable[i].proc;
		}
	}
	return 0;
}

void ps_init(void)
{
	add_ping(ps);
}
