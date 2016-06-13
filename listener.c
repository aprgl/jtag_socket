#include <stdio.h>
#include <inttypes.h>
#include <lcm/lcm.h>
#include "exlcm_jtag_t.h"

static void
my_handler(const lcm_recv_buf_t *rbuf, const char * channel, 
    const exlcm_jtag_t * msg, void * user){
    int i;
    printf("Received message on channel \"%s\":\n", channel);
    printf("  timestamp   = %u.%u\n", msg->seconds, msg->microseconds);
    printf("  address     = %d\n", msg->address);
    printf("  data        = %d\n", msg->data);
}

int main(int argc, char ** argv){
    lcm_t * lcm = lcm_create(NULL);
    if(!lcm)
        return 1;

    exlcm_jtag_t_subscribe(lcm, "FROM_JTAG", &my_handler, NULL);

    while(1)
        lcm_handle(lcm);

    lcm_destroy(lcm);
    return 0;
}