# This Makefile was tested with GNU Make
CC=gcc

all: jtag_debug

jtag_debug: jtag_debug.c
	$(CC) -o $@ $^ $(LDFLAGS)

%.o: %.c %.h
	$(CC) $(CFLAGS) -c $< 

clean:
	rm -f client
	rm -f *.o
