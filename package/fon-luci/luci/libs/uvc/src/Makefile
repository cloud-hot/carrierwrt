PROGS=uvc.so
STRIP?=strip
CFLAGS?=
CFLAGS+=-pedantic -Werror -Wall -I/usr/include/lua5.1/ -std=gnu99
LDFLAGS?=
LDFLAGS+=
OBJS=uvc.o v4l2uvc.o

all: $(PROGS)

$(PROGS): $(OBJS)
	$(CC) $(CFLAGS) -shared -Wl,-soname,uvc -liw $(LDFLAGS) $^ -o $@

clean:
	rm -f $(PROGS) *.o *.so

%.o: %.c
	$(CC) $(CFLAGS) -c  $^ -o $@
