#!/usr/bin/python

import select
import lcm
import time,readline,thread, math
import sys,struct,fcntl,termios
import ctypes
from exlcm import jtag_t

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def my_handler(channel, data):
    msg = jtag_t.decode(data)
    #print("Message on channel \"%s\"" % channel)
    print (bcolors.OKBLUE + "\x1b[0G\x1b[2K< %u.%u\033[93m" \
    	" Address[%u, 0x%02X]\033[92m Data[%u, 0x%08X]\033[0m" \
    	% (msg.seconds, msg.microseconds, msg.address, msg.address, \
    		msg.data , msg.data))

lc = lcm.LCM()
subscription = lc.subscribe("JTAG", my_handler)

def send_message(a, b):
    msg = jtag_t()
    microseconds = round(time.time()*1000)
    msg.seconds = int(math.floor(microseconds/1000))
    msg.microseconds = int(microseconds-msg.seconds*1000)
    msg.address = int(a)
    msg.data = int(b)
    lc.publish("JTAG", msg.encode())

def yellow( str ):
   print (bcolors.WARNING + str + bcolors.ENDC)
   return

def blue( str ):
   print (bcolors.OKBLUE + str + bcolors.ENDC)
   return

def bblue( str ):
   print (bcolors.OKBLUE + bcolors.BOLD + str + bcolors.ENDC)
   return

def green( str ):
   print (bcolors.OKGREEN + str + bcolors.ENDC)
   return

def red( str ):
   print (bcolors.FAIL + str + bcolors.ENDC)
   return

bblue("Welcome to the FRED control terminal\n")

def blank_current_readline():
    # Next line said to be reasonably portable for various Unixes
    (rows,cols) = struct.unpack('hh', \
    	fcntl.ioctl(sys.stdout, termios.TIOCGWINSZ,'1234'))

    text_len = len(readline.get_line_buffer())+2

    # ANSI escape sequences (All VT100 except ESC[0G)
    sys.stdout.write('\x1b[2K')                         # Clear current line
    sys.stdout.write('\x1b[1A\x1b[2K'*(text_len/cols))  # Cursor up & clear
    sys.stdout.write('\x1b[0G')                         # Move to start of line


def noisy_thread():
    while True:
        blank_current_readline()
        rfds, b, c = select.select([lc.fileno()], [], [], 0.001)
        if rfds:
            lc.handle()
        sys.stdout.write('> ' + readline.get_line_buffer())
        sys.stdout.flush() # Needed or text doesn't show until key press

if __name__ == '__main__':
    thread.start_new_thread(noisy_thread, ())
    while True:
    	try:
            s = raw_input('> ')
            values = s.split()
            if (len(values) == 2):
            	print ("> Command [%s %s] Sent" % (values[0], values[1]))
                send_message(values[0], values[1])
            else:
                print("Nope. I need two arguements [address] and " \
                	"[data] I recieved:\"" + s + "\"")
        except KeyboardInterrupt:
            red("\nFred teminal is offline.\n")
            lc.unsubscribe(subscription)
            sys.exit()
