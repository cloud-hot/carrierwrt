include ../../build/config.mk
include ../../build/module.mk
include ../../build/gccconfig.mk

%.o: %.c
	$(COMPILE) $(LUA_CFLAGS) $(FPIC) -c -o $@ $< 

compile: src/music.o
	mkdir -p dist$(LUA_LIBRARYDIR)
	$(LINK) $(SHLIB_FLAGS) -o dist$(LUA_LIBRARYDIR)/music.so src/music.o

clean: luaclean
	rm -f src/*.o
