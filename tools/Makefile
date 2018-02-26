# This Makefile was tested with GNU Make
CC=gcc

# Use pkg-config to lookup the proper compiler and linker flags for LCM
CFLAGS=`pkg-config --cflags lcm`
LDFLAGS=`pkg-config --libs lcm`

all: lcm_server \
	send_message

lcm_server: exlcm_jtag_t.o lcm_server.c
	$(CC) -g -o $@ $^ $(LDFLAGS)

send_message: exlcm_jtag_t.o send_message.c
	$(CC) -g -o $@ $^ $(LDFLAGS)

exlcm_%.c exlcm_%.h: types/jtag_t.lcm
	lcm-gen -c $<
	lcm-gen -p types/jtag_t.lcm # generate the lcm files for python

# prevent auto-generated lcm .c/.h files from being deleted
.SECONDARY : exlcm_jtag_t.c exlcm_jtag_t.h

%.o: %.c %.h
	$(CC) $(CFLAGS) -c $< 

clean:
	rm -f lcm_server send_message
	rm -f *.o
	rm -f exlcm_jtag_t.c exlcm_jtag_t.h
	rm -rf exlcm
	rm -f *.csv
