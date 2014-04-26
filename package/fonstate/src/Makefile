PROGS=fonstated
STRIP?=strip
CFLAGS?=
CFLAGS+=-pedantic -Werror -Wall -I./include/ -std=gnu99
LDFLAGS?=
LDFLAGS+=-luci -ldl
OBJS=main.o lib/log.o lib/uci.o lib/sys.o fon/state.o net/socket.o plugin/plugin.o lib/signal.o net/net_helper.o lib/ps.o

all: $(PROGS)

$(PROGS): $(OBJS)
	$(CC) $(CFLAGS) -rdynamic $(LDFLAGS) $^ -o $@
	
#fonstate_usbled.so: plugin/usbled.c
#	$(CC) $(CFLAGS) -o $@ $^ -shared

fonstate_online.so: plugin/online.c
	$(CC) $(CFLAGS) -o $@ $^ -shared

#fonstate_usbstatus.so: plugin/usbstatus.c
#	$(CC) $(CFLAGS) -o $@ $^ -shared

#fonstate_watchdog.so: plugin/watchdog.c
#	$(CC) $(CFLAGS) -o $@ $^ -shared

clean:
	rm -f $(PROGS) *.o *.so

%.o: %.c
	$(CC) $(CFLAGS) -c  $^ -o $@
