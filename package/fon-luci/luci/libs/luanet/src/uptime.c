/* based on busybox code */
#include <stdio.h>
#include <sys/sysinfo.h>
#include <sys/time.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>


int sysinfo(struct sysinfo *info);

int uptime(lua_State *L)
{
	int updays, uphours, upminutes;
	struct sysinfo info;
	char ustr[256];
	sysinfo(&info);

	updays = (int) info.uptime / (60*60*24);
	upminutes = (int) info.uptime / 60;
	uphours = (upminutes / 60) % 24;
	upminutes %= 60;
	if(updays)
		sprintf(ustr, "%d, %02d:%02d", updays, uphours, upminutes);
	else
		sprintf(ustr, "%02d:%02d ", uphours, upminutes);

	lua_pushstring(L, ustr);
	return 1;
}

int Lgettimeofday(lua_State *L)
{
	struct timeval tv;
	gettimeofday(&tv, 0);
	lua_pushinteger(L, (tv.tv_sec * 1000 * 1000) + tv.tv_usec);
	return 1;
}
