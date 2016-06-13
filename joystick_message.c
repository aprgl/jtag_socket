#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/joystick.h>
#include <stdio.h>
#include <lcm/lcm.h>
#include <sys/time.h>
#include "exlcm_jtag_t.h"

#define JOY_DEV "/dev/input/js1"

int main(int argc, char ** argv){

    uint8_t address = 1;
    uint32_t data = 0;

    printf("XBox Servo Nonsense starting...");

    lcm_t * lcm = lcm_create(NULL);
    if(!lcm){
        printf("Could not create LCM channel.");
        return 1;
    }

    int joy_fd, *axis=NULL, num_of_axis=0, num_of_buttons=0, x;
    char *button=NULL, name_of_joystick[80];
    struct js_event js;

    if( ( joy_fd = open( JOY_DEV , O_RDONLY)) == -1 )
    {
        printf( "Couldn't open joystick\n" );
        return -1;
    }

    ioctl( joy_fd, JSIOCGAXES, &num_of_axis );
    ioctl( joy_fd, JSIOCGBUTTONS, &num_of_buttons );
    ioctl( joy_fd, JSIOCGNAME(80), &name_of_joystick );

    axis = (int *) calloc( num_of_axis, sizeof( int ) );
    button = (char *) calloc( num_of_buttons, sizeof( char ) );

    printf("Joystick detected: %s\n\t%d axis\n\t%d buttons\n\n"
        , name_of_joystick
        , num_of_axis
        , num_of_buttons );

    fcntl( joy_fd, F_SETFL, O_NONBLOCK );   /* use non-blocking mode */

    int index = 1;
    while( 1 )  /* infinite loop */
    {
            /* read the joystick state */
        read(joy_fd, &js, sizeof(struct js_event));
        
            /* see what to do with the event */
        switch (js.type & ~JS_EVENT_INIT)
        {
            case JS_EVENT_AXIS:
                axis   [ js.number ] = js.value;
                break;
            case JS_EVENT_BUTTON:
                button [ js.number ] = js.value;
                break;
        }

            /* print the results */
        printf( "X1:%6d Y1:%6d ", (int)((axis[0]+32767)*0.00091554131), (int)((axis[1]+32767)*0.00091554131));
        printf( "X2:%6d Y2:%6d ", (int)((axis[2]+32767)*0.00091554131), (int)((axis[3]+32767)*0.00091554131));
        printf( "X3:%6d Y3:%6d ", (int)((axis[4]+32767)*0.00091554131), (int)((axis[5]+32767)*0.00091554131));

        printf("  \r");
        fflush(stdout);

        // Timestamp
        struct timeval tv;
        gettimeofday(&tv,NULL);


        data = (int)((axis[index-1]+32767)*0.00091554131);
        exlcm_jtag_t test_packet = {
            .seconds = tv.tv_sec, // seconds
            .microseconds = tv.tv_usec, // microseconds
            .address = index,
            .data = data,
        };

        exlcm_jtag_t_publish(lcm, "TO_JTAG", &test_packet);

        index++;
        if(index > 6){
            index = 1;
        }

    }

    close( joy_fd );    /* too bad we never get here */

    lcm_destroy(lcm);
    return 0;
}
