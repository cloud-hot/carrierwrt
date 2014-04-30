#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <vbutil_firmware.h>

#define FONVERIFY_VERSION "0.0.1"

static int fr_verify(lua_State *L);
static int fr_error(lua_State *L);

static luaL_reg func[] = {
    {"verify",    fr_verify},
    {"error",     fr_error},
    {NULL,        NULL}
};

static int fr_verify(lua_State *L)
{
	char *file_path, *signature_path, *out_path, n;
	int err;
	if ((n = lua_gettop(L))!= 3) {
		lua_pushstring(L, "fonrsa.verify(): specify file, signature paths and output path ");
		lua_error(L);
		return 0;
	}
	file_path = (char *)lua_tostring (L, 1);
	signature_path = (char *)lua_tostring (L, 2);
	out_path = (char *)lua_tostring (L, 3);
	err = Verify(file_path, signature_path, NULL, NULL, out_path);
	if (err == 0)
		lua_pushboolean(L, 1);
	else
		lua_pushboolean(L, 0);
	return 1;
}

static int fr_error(lua_State *L)
{
	lua_pushstring(L, "fr_error");
	lua_error(L);
	return 0;
}

int luaopen_fonrsa (lua_State *L)
{
	luaL_openlib(L, "fonverify", func, 0);
	lua_pushstring(L, "_VERSION");
	lua_pushstring(L, FONVERIFY_VERSION);
	lua_rawset(L, -3);
	return 1;
}

int luaclose_fonrsa(lua_State *L)
{
	lua_pushstring(L, "Called");
	return 1;
}

