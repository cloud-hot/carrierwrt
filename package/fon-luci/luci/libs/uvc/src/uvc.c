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
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <linux/videodev.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "v4l2uvc.h"

struct vdIn *videoIn = NULL;

struct vdIn*
uvc_init(char *dev, int width, int height)
{
	struct vdIn *videoIn = (struct vdIn *)calloc(1, sizeof (struct vdIn));
	if(init_videoIn(videoIn, dev, width, height, V4L2_PIX_FMT_MJPEG, 1) < 0)
	{
		free(videoIn);
		videoIn = NULL;
	} else {
		v4l2ResetControl(videoIn, V4L2_CID_BRIGHTNESS);
		v4l2ResetControl(videoIn, V4L2_CID_CONTRAST);
		v4l2ResetControl(videoIn, V4L2_CID_SATURATION);
		v4l2ResetControl(videoIn, V4L2_CID_GAIN);
		sleep(1);
	}
	return videoIn;
}

int
uvc_snapshot(struct vdIn *videoIn, char *filename)
{
	FILE *file;

	videoIn->getPict = 0;

	if(uvcGrab(videoIn) < 0)
		return -1;

	file = fopen(filename, "wb");
	if(file != NULL)
	{
		fwrite(videoIn->tmpbuffer, videoIn->buf.bytesused + DHT_SIZE, 1, file);
		fclose(file);
	//	videoIn->getPict = 0;
	}
	return 0;
}

static int u_grab(lua_State *L)
{
	char *filename;
	if(!videoIn)
	{
		videoIn = uvc_init("/dev/video0", 640, 480);
		if(!videoIn)
		{
			lua_pushboolean(L, 0);
			return 1;
		}
	}
	if(uvcGrab(videoIn) < 0)
	{
		close_v4l2(videoIn);
		free(videoIn);
		videoIn = NULL;
		lua_pushnil(L);
	} else {
		lua_pushlstring(L, videoIn->tmpbuffer, videoIn->buf.bytesused + DHT_SIZE);
	}
	return 1;
}

static int u_dump(lua_State *L)
{
	char *filename;
	if(!videoIn)
	{
		videoIn = uvc_init("/dev/video0", 640, 480);
		if(!videoIn)
		{
			lua_pushboolean(L, 0);
			return 1;
		}
	}
	if(lua_gettop(L) != 1)
	{
		lua_pushstring(L, "uvc.dump(\"filename\") : wrong param count");
		lua_error(L);
		return 0;
	}
	filename = (char *)lua_tostring (L, 1);
	if(uvc_snapshot(videoIn, filename) != 0)
	{
		close_v4l2(videoIn);
		free(videoIn);
		videoIn = NULL;
		lua_pushnil(L);
	} else {
		lua_pushboolean(L, 1);
	}
	return 1;
}


static luaL_reg func[] = {
	{"grab", u_grab},
	{"dump", u_dump},
	{NULL, NULL}
};

int luaopen_uvc(lua_State *L)
{
	luaL_openlib(L, "uvc", func, 0);
	lua_pushstring(L, "_VERSION");
	lua_pushstring(L, "1.0");
	lua_rawset(L, -3);
	return 1;
}

int luaclose_uvc(lua_State *L)
{
	if(videoIn)
	{
		close_v4l2(videoIn);
		free(videoIn);
	}
	lua_pushstring(L, "Called");
	return 1;
}


