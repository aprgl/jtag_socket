#include <stdio.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <stdlib.h> // for exit
#include <unistd.h>
#include <string.h>
#include <netdb.h> 

#define MESSAGE_SIZE 32
#define FLAGS 0

// Port FRED!
#define PORT 3733

void error(const char *msg){
    perror(msg);
    exit(0);
}

int main(int argc, char *argv[]){

 	struct timeval tv; /* timeval and timeout stuff added by davekw7x */
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
    for (int l = 0; l < 10; ++l){
	    for (int i = 0; i < 256; ++i){
			//uint8_t message[MESSAGE_SIZE] = {0x11, 0x22, 0x33, 0x44};
		
			char message[MESSAGE_SIZE];
			snprintf(message, sizeof message, "address.%d.data.000.\n", i);
			if (sendto(conn, message, MESSAGE_SIZE-1, FLAGS, (struct sockaddr *)&server, sizeof(struct sockaddr)) < 0) {
				error("Failed to transmit message to server.");
			}
			//printf("Sent: %s",message);


			int numbytes = 0;
			while (((numbytes=recv(conn, message, MESSAGE_SIZE-1, 0)) == -1) && (++timeouts < 1000)) { /* loop to retry in case it timed out; added by davekw7x */ 
				perror("recv"); printf("After timeout #%d, trying again:\n", timeouts); 
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
	}
	//ToDo: Add this as a debug option to check the link ->
	//printf("nacks with %d and acks with %d\n", nack, ack);

	close(conn);

	return 0;
}