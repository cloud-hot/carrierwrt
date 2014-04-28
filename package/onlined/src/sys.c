#include <sys/types.h>
#include <sys/wait.h>
#include <stdio.h>
#include <syslog.h>
#include <unistd.h>
#include <stdarg.h>
#include <stdlib.h>
#include <libgen.h>

void write_pid()
{
	FILE *fp = fopen("/var/run/onlined.pid", "w");
	if(!fp)
	{
		syslog(0, "Failed to write pid file\n");
		return;
	}
	fprintf(fp, "%d", getpid());
	fclose(fp);
}

int system_printf(char *fmt, ...)
{
	char p[256];
	va_list ap;
	int pid = fork();
	if(!pid)
	{
		va_start(ap, fmt);
		vsnprintf(p, 256, fmt, ap);
		va_end(ap);
		execlp("/bin/sh", "/bin/sh", "-c", p, NULL);
		syslog(0, "oooppps, called %s which does not exist\n", p);
		exit(0);
	} else {
		int t;
		do {
			t = waitpid(pid, NULL, 0);
		} while(t <= 0);
	}
	return 0;
}
