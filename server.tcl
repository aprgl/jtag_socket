#!/home/shaun/altera_lite/15.1/quartus/bin/quartus_stp -t
#  
#	Virtual JTAG interface designed to operate with a struct style
#	messaging protocol between a LCM channel and the Altera USB Blaster.
#
#	This project was inspired by and built off of the Virtual UART toolkit
#
#   Copyright (C) 2014  Binary Logic (nhi.phan.logic at gmail.com).
#   
#   Virtual JTAG is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#   
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Define connection details
set host localhost
set port 3733

# Awesome example code for fake structs from http://wiki.tcl.tk/4286
# proc struct { name thingys } {
#	foreach { key value } $thingys {
#		uplevel set $name.$key $value 
#	} 
# }

# struct jtag_packet {
#	address
#	data
# }

# Setup connection
proc setup_blaster {} {
	global usbblaster_name
	global test_device

	foreach hardware_name [get_hardware_names] {
		if { [string match "USB-Blaster*" $hardware_name] } {
			set usbblaster_name $hardware_name
		}
	}

	puts "Select JTAG chain connected to $usbblaster_name.";

	# List all devices on the chain, and select the first device on the chain.
	#Devices on the JTAG chain:


	foreach device_name [get_device_names -hardware_name $usbblaster_name] {
		if { [string match "@1*" $device_name] } {
			set test_device $device_name
		}
	}
	puts "Selected device: $test_device.";
}

# Open device 
proc openport {} {
	global usbblaster_name
        global test_device
	open_device -hardware_name $usbblaster_name -device_name $test_device
	device_lock -timeout 10000
}


# Close device.  Just used if communication error occurs
proc closeport { } {
	global usbblaster_name
	global test_device

	# Set IR back to 0, which is bypass mode
	# device_virtual_ir_shift -instance_index 0 -ir_value 3 -no_captured_ir_value

	catch {device_unlock}
	catch {close_device}
}

proc slam {jtag_addr jtag_data jtag_data_length} {
	device_virtual_ir_shift -instance_index 0 -ir_value $jtag_addr
	return [device_virtual_dr_shift -dr_value [format %08X $jtag_data] -value_in_hex -instance_index 0 -length $jtag_data_length]
}

# Send data to the Altera input FIFO buffer
proc send {char} {
	device_virtual_ir_shift -instance_index 0 -ir_value [eval jtag_packet.address] -no_captured_ir_value
	device_virtual_dr_shift -dr_value [dec2bin $chr 8] -instance_index 0  -length 8 -no_captured_dr_value
}

# Read data in from the Altera output FIFO buffer
proc recv {} {
	# Check if there is anything to read
	device_virtual_ir_shift -instance_index 0 -ir_value 2 -no_captured_ir_value
	set tdi [device_virtual_dr_shift -dr_value 0000 -instance_index 0 -length 4]
	if {![expr $tdi & 1]} {
		device_virtual_ir_shift -instance_index 0 -ir_value 0 -no_captured_ir_value
		set tdi [device_virtual_dr_shift -dr_value 00000000 -instance_index 0 -length 8]
		return [bin2dec $tdi]
	} else {
		return -1
	}
}

########## Process a connection on the port ###########################
proc server {chan addr port} {
    #global service_port
	#global listen_address
	global wait_connection

	# Connect the USB Blaster
	openport

    fconfigure $chan -buffering none -translation auto ;# NOT -blocking 0 (see below!)
    while {[gets $chan line]>=0} {
        catch $line res
        set numchars [string length $line]
		if {$numchars >= 0} {
			set packet_start [string first "address" $line]
			if {$packet_start > 0} {
				set packet [string range $line $packet_start [string length $line]]
				puts "Packet Recieved: < $packet >"
				set data [split $packet .]
				set jtag_addr [lindex $data 1]
				set jtag_data [lindex $data 3]
				set jtag_data_length [lindex $data 5]
				set from_jtag [slam $jtag_addr $jtag_data $jtag_data_length]
				puts -nonewline $chan [format "ack addr %03d data %s" $jtag_addr $from_jtag]
			} else {
				puts -nonewline $chan "nack bad packet $line"
				puts "nack bad packet"
			}
		} else {
			if { catch { puts -nonewline $chan "nack"} } {
				puts "broken pipe!"
			}
			puts "nack"
			puts $numchars
		}
    }

    close $chan
	puts "\nClosed connection"

	closeport

	set wait_connection 1
}

####################### Main code ###################################
global usbblaster_name
global test_device
global wait_connection

# Find the USB Blaster
setup_blaster

puts "Server started..."
socket -server server $port

# Loop forever
while {1} {

	# Set the exit variable to 0
	set wait_connection 0

	# Display welcome message
	puts "JTAG VComm listening on $host:$port"

	# Wait for the connection to exit
	vwait wait_connection 
}
##################### End Code ########################################
