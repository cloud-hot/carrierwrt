/*
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; version 2 of the License.
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
 *   Copyright (C) 2009 Steven Barth <steven@midlink.org>
 */

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <arpa/inet.h>
#include <errno.h>

#define VERSION "0.1"
#define METANAME "music.meta"

/* static ssize_t Readline(int sockd, void *vptr, size_t maxlen); */
static ssize_t Writeline(int sockd, const void *vptr, size_t n);

/* checks whether the first argument is an music object and returns it */
static int* music__get(lua_State *L) {
    int *sock = (int*)luaL_checkudata(L, 1, METANAME);
    luaL_argcheck(L, sock != NULL, 1, "`music' expected");
    return sock;
}


/* sends a message */
static int music__send(lua_State *L, const char *msg)
{
	char cmsg[1024];
	size_t length;
	int *sock = music__get(L);

	length = strlen(msg);
	memcpy(cmsg, msg, length);
	cmsg[length++] = '\n';
	cmsg[length] = '\0';
	if ((Writeline(*sock, (const void *)cmsg, length)) != (ssize_t)length) {
		return luaL_error(L, "write() failed");
	}
	return 0;
}


/**
 * create new music object
 */
static int music_open(lua_State *L) {
	int *sock;
	struct sockaddr_in servaddr;

	/* create userdata */
	sock = lua_newuserdata(L, sizeof(int));
	luaL_getmetatable(L, METANAME);
	lua_setmetatable(L, -2);

	if (!sock) {
		return luaL_error(L, "malloc() failed");
	}

	*sock = socket(AF_INET, SOCK_STREAM, 0);

	if ((*sock) < 0) {
		return luaL_error(L, "socket() failed");
	}
        servaddr.sin_family = AF_INET;
        servaddr.sin_port  = htons(15051);
        inet_aton("127.0.0.1", &servaddr.sin_addr);

	if(connect(*sock, (struct sockaddr *)&servaddr, sizeof(servaddr)) == -1) {
		close(*sock);
		return luaL_error(L, "connect() failed");
	}

	return 1;
}

/* volume up */
static int music_volup(lua_State *L) {
	return music__send(L, "VOLUP");
}

/* volume down */
static int music_voldown(lua_State *L) {
	return music__send(L, "VOLDOWN");
}

/* next track */
static int music_next(lua_State *L) {
	return music__send(L, "NEXT");
}

/* previous track */
static int music_prev(lua_State *L) {
	return music__send(L, "PREV");
}

/* stop */
static int music_stop(lua_State *L) {
	return music__send(L, "STOP");
}

/* start */
static int music_start(lua_State *L) {
	return music__send(L, "START");
}

/* set volume (0-100) */
static int music_volset(lua_State *L) {
	char msg[12];
	int volume = (int)luaL_checkinteger(L, 2);

	luaL_argcheck(L, volume >= 0 && volume <= 100, 1, "out of range");
	snprintf(msg, sizeof(msg), "VOLSET|%i|", volume);

	return music__send(L, msg);
}

/* volset */
static int music_list(lua_State *L) {
	char msg[256];
	size_t len;
	const char *file = luaL_checklstring(L, 2, &len);
	luaL_argcheck(L, len <= sizeof(msg) - 7, 1, "too long");

	snprintf(msg, sizeof(msg), "LIST|%s|", file);
	return music__send(L, msg);
}


/**
 * garbage collector
 */
static int music__gc(lua_State *L) {
	int *sock = music__get(L);
	close(*sock);
	return 0;
}

/* module table */
static const luaL_reg R[] = {
	{"open",		music_open},
	{NULL,			NULL}
};

/* object table */
static const luaL_reg M[] = {
	{"volup",		music_volup},
	{"voldown",		music_voldown},
	{"next",		music_next},
	{"prev",		music_prev},
	{"stop",		music_stop},
	{"start",		music_start},
	{"volset",		music_volset},
	{"list",		music_list},
	{"__gc",		music__gc},
	{NULL,			NULL}
};

/* entry point */
LUALIB_API int luaopen_music(lua_State *L) {
	/* create metatable */
	luaL_newmetatable(L, METANAME);

	/* metatable.__index = metatable */
	lua_pushvalue(L, -1);
	lua_setfield(L, -2, "__index");

	/* fill metatable */
	luaL_register(L, NULL, M);
	lua_pop(L, 1);

	/* register module */
	luaL_register(L, "music", R);

	/* module version */
	lua_pushliteral(L, VERSION);
	lua_setfield(L, -2, "version");

	return 1;
}
/*
static ssize_t Readline(int sockd, void *vptr, size_t maxlen)
{
	ssize_t n, rc;
	char    c, *buffer;

	buffer = vptr;

	for ( n = 1; n < maxlen; n++ ) {
		if ( (rc = read(sockd, &c, 1)) == 1 ) {
			*buffer = c;
		if ( c == '\n' )
			break;
		} else if ( rc == 0 ) {
			if ( n == 1 )
				return 0;
			else
				break;
		} else {
			if ( errno == EINTR )
				continue;
			return -1;
		}
		buffer++;
        }

	*buffer = 0;
	return n;
}
*/

static ssize_t Writeline(int sockd, const void *vptr, size_t n)
{
	size_t      nleft;
	ssize_t     nwritten;
	const char *buffer;

	buffer = vptr;
	nleft  = n;

	while ( nleft > 0 ) {
	if ( (nwritten = write(sockd, buffer, nleft)) <= 0 ) {
		if ( errno == EINTR )
			nwritten = 0;
		else
			return -1;
		}
		nleft  -= nwritten;
		buffer += nwritten;
	}

	return n;
}

