# This Makefile was tested with GNU Make
CC=gcc

# Use pkg-config to lookup the proper compiler and linker flags for LCM
CFLAGS=`pkg-config --cflags lcm`
LDFLAGS=`pkg-config --libs lcm`

all: jtag_debug \
	test_message \
	listener

jtag_debug: exlcm_jtag_t.o jtag_debug.c
	$(CC) -g -o $@ $^ $(LDFLAGS)

test_message: exlcm_jtag_t.o test_message.c
	$(CC) -g -o $@ $^ $(LDFLAGS)

listener: exlcm_jtag_t.o listener.c
	$(CC) -g -o $@ $^ $(LDFLAGS)

exlcm_%.c exlcm_%.h: types/jtag_t.lcm
	lcm-gen -c $<
	lcm-gen -p types/jtag_t.lcm # generate the lcm files for python

# prevent auto-generated lcm .c/.h files from being deleted
.SECONDARY : exlcm_jtag_t.c exlcm_jtag_t.h

%.o: %.c %.h
	$(CC) $(CFLAGS) -c $< 

clean:
	rm -f jtag_debug test_message listener
	rm -f *.o
	rm -f exlcm_jtag_t.c exlcm_jtag_t.h
	rm -r exlcm
