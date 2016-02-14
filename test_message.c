#include <stdio.h>
#include <lcm/lcm.h>
#include <sys/time.h>
#include "exlcm_jtag_t.h"

int main(int argc, char ** argv){

    uint8_t address = 0;
    uint32_t data = 0;

    if( argc != 3 ) {
        printf("Nope. The useage is: %s [address] [data]\n", argv[0]);
        return 1;
    }else{
        address = atoi(argv[1]);
        data = atoi(argv[2]);
    }

    lcm_t * lcm = lcm_create(NULL);
    if(!lcm){
        printf("Could not create LCM channel.");
        return 1;
    }

    // Timestamp
    struct timeval tv;
    gettimeofday(&tv,NULL);

    exlcm_jtag_t test_packet = {
        .seconds = tv.tv_sec, // seconds
        .microseconds = tv.tv_usec, // microseconds
        .address = address,
        .data = data,
    };

    exlcm_jtag_t_publish(lcm, "JTAG", &test_packet);
    
    lcm_destroy(lcm);
    return 0;
}
