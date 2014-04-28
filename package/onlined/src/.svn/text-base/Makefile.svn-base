PROGS=onlined
STRIP?=strip
CFLAGS?=
CFLAGS+=-pedantic -Werror -Wall -I./include/ -std=gnu99
LDFLAGS?=
LDFLAGS+=-luci
OBJS=online.o net_helper.o sys.o

all: $(PROGS)

onlined: $(OBJS)
	$(CC) $(CFLAGS) -rdynamic $(LDFLAGS) $^ -o $@

clean:
	rm -f $(PROGS) *.o *.so

%.o: %.c
	$(CC) $(CFLAGS) -c  $^ -o $@
