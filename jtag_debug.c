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

#define MESSAGE_SIZE 50
#define FLAGS 0

// Port FRED!
#define PORT 3733

void error(const char *msg2){
    perror(msg2);
    exit(0);
}

static void
my_handler(const lcm_recv_buf_t *rbuf, const char * channel, 
	const exlcm_jtag_t * msg, void * user){
    int i;
    printf("Received message on channel \"%s\":\n", channel);
    printf("  timestamp   = %lu\n", msg->timestamp);
    printf("  position    = (%f, %f, %f)\n",
            msg->position[0], msg->position[1], msg->position[2]);
    printf("  orientation = (%f, %f, %f, %f)\n",
            msg->orientation[0], msg->orientation[1], msg->orientation[2],
            msg->orientation[3]);
    printf("  ranges:");
    for(i = 0; i < msg->num_ranges; i++)
        printf(" %d", msg->ranges[i]);
    printf("\n");
    printf("  name        = '%s'\n", msg->name);
    printf("  enabled     = %d\n", msg->enabled);
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

    int ack, nack = 0;
	    for (int i = 0; i < 256; ++i){
		//uint8_t message[MESSAGE_SIZE] = {0x11, 0x22, 0x33, 0x44};
	
		uint32_t data = 55;
		int data_size = 8;
		char message[MESSAGE_SIZE];
		snprintf(message, MESSAGE_SIZE-1, "address.%d.data.%02x.size.%d.\n", i, data, data_size);
		if (sendto(conn, message, MESSAGE_SIZE-1, FLAGS, (struct sockaddr *)&server, sizeof(struct sockaddr)) < 0) {
			error("Failed to transmit message to server.");
		}

		int numbytes = 0;
		while (((numbytes=recv(conn, message, MESSAGE_SIZE-1, 0)) == -1) && (++timeouts < 1000)) { /* loop to retry in case it timed out; added by davekw7x */ 
			perror("recv"); 
			printf("After timeout #%d, trying again:\n", timeouts); 
		} 
		//printf("numbytes = %d\n", numbytes); 
		message[numbytes] = '\0';
		if(numbytes >= 1 ){
			if(message[0] == 'a'){
				ack++;
				//printf("Received Ack!");
				printf("Ack?: %s \n",message);
			}else{
				nack++;
				printf("Nack?: %s \n",message);
				//printf("Something went wrong.");
			}
		}else{
			//printf("Received incomplete packet");
		}
	}
	
	while(1)
		lcm_handle(lcm);

	//ToDo: Add this as a debug option to check the link ->
	//printf("nacks with %d and acks with %d\n", nack, ack);
	
	close(conn);

	lcm_destroy(lcm);

	return 0;
}