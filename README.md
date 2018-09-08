# jtag_socket
This is a series of command line tools for sending data to the Altera virtual JTAG IP

# How to build
1. cd tools
2. make

# How to run

1. Launch the JTAG tcl server - *./jtag_server.tcl*
2. Wait for the server to report JTAG VComm listenign on localhost:3733
2. Launch teh lcm server - *./lcm_server*
3. Launch the terminal - *terminal.py*
