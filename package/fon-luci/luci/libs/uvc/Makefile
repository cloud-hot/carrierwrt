ifeq ($(CFLAGS),)
	MYLDFLAGS ?= -L../../../contrib/uci/dist/usr/lib/
endif

include ../../build/module.mk
include ../../build/config.mk
include ../../build/gccconfig.mk

compile: 
	make -Csrc \
		CFLAGS="$(CFLAGS) $(FPIC) $(LUA_CFLAGS) $(EXTRA_CFLAGS)" \
		LDFLAGS="$(LDFLAGS) $(LUA_SHLIBS)" \
		MYLDFLAGS="$(MYLDFLAGS)"
	mkdir -p dist/usr/lib/lua/
	cp src/uvc.so dist/usr/lib/lua

clean: luaclean
	make -Csrc clean
