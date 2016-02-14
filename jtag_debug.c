#include <stdio.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <stdlib.h> // for exit
#include <unistd.h>
#include <string.h>
#include <netdb.h> 

/* Stuff for the LCM channel */
//#include <inttypes.h>
#include <lcm/lcm.h>
#include "exlcm_jtag_t.h"

#define MESSAGE_SIZE 65
#define FLAGS 0

// Port FRED!
#define PORT 3733

uint8_t jtag_address = 0;
uint32_t jtag_data = 0;

void error(const char *msg2){
    perror(msg2);
    exit(0);
}

static void
my_handler(const lcm_recv_buf_t *rbuf, const char * channel, 
	const exlcm_jtag_t * msg, void * user){
    int i;
    printf("Received message on channel \"%s\":\n", channel);
    printf("  timestamp   = %u.%u\n", msg->seconds, msg->microseconds);
    printf("  address     = %d\n", msg->address);
    printf("  data        = %d\n", msg->data);
    jtag_address = msg->address;
    jtag_data = msg->data;
}

int main(int argc, char *argv[]){

	lcm_t * lcm = lcm_create(NULL);
   if(!lcm)
		error("Faied to create LCM channel!");
    exlcm_jtag_t_subscribe(lcm, "JTAG", &my_handler, NULL);

 	struct timeval tv;
	int timeouts = 0; 
	tv.tv_sec = 3;
	tv.tv_usec = 0;

	// Information about the other computer
	struct sockaddr_in server;
    struct hostent *hostname;

    hostname = gethostbyname("localhost");

    // Socket type
	int conn = socket(AF_INET, SOCK_STREAM, 0);
	if (conn < 0){
		error("Failed to open socket!");
	}

	// Connection information and attempt
	server.sin_family = AF_INET;
    server.sin_port = htons(PORT);
    server.sin_addr = *((struct in_addr *)hostname->h_addr);
    memset(&(server.sin_zero), '\0', 8);
	if (connect(conn,(struct sockaddr *)&server, sizeof(server)) < 0){ 
        error("Failed to connect to connect to server.");
    }
	
	while(1){
		lcm_handle(lcm);

		char message[MESSAGE_SIZE];
		snprintf(message, MESSAGE_SIZE-1, "address.%d.data.%d.size.%d.\n", jtag_address, jtag_data, 32);
		if (sendto(conn, message, MESSAGE_SIZE-1, FLAGS, (struct sockaddr *)&server, sizeof(struct sockaddr)) < 0) {
			error("Failed to transmit message to server.");
		}

		int numbytes = 0;
		while (((numbytes=recv(conn, message, MESSAGE_SIZE-1, 0)) == -1) && (++timeouts < 1000)) {
			perror("recv"); 
			printf("After timeout #%d, trying again:\n", timeouts); 
		} 

		if(numbytes >= 1 ){
			if(message[0] == 'a'){
				printf("Ack: %s \n", message);
			}else{
				printf("Nack: %s \n", message);
			}
		}
	}

	//ToDo: Add this as a debug option to check the link ->
	//printf("nacks with %d and acks with %d\n", nack, ack);
	
	close(conn);
	lcm_destroy(lcm);
	return 0;
}