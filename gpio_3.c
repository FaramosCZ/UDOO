/* ----------------------------------------------------------------------------

 AUTHOR:
   Michal Schorm    mschorm@redhat.com

 NAME:
   Linux GPIO basics

 DESCRIPTION:
   This piece of code tries to open GPIO device and read some infromation
   about the GPIO and request some lines to our ownership.

 INFO:
   This software only works with 'linux/gpio.h' and in the case, you can see
   any GPIO devices in /dev/. Originally a different approach has been used
   in linux, by 'sysfs' kernel module, which allowed to work with GPIO through
   /sys/class/gpio/...

 COMPILATION:
   gcc -std=c99 -Wall -Wextra -Werror -pedantic -o gpio gpio_3.c && ./gpio

 SAMPLE OUTPUT:
   name: 			gpiochip0
   label:			INT33FF:00
   number of lines:		56

   line offset:			55
   flags:			2
   name:
   consumer:


   PIN 1:			1
   PIN 2:			0

   New data set !

   PIN 1:			0
   PIN 2:			1

--------------------------------------------------------------------------- */

#include <stdio.h>
#include <stdlib.h>

#include <fcntl.h>         // open()
#include <unistd.h>        // close()
#include <sys/ioctl.h>     // ioctl()

#include <linux/gpio.h>

#include <errno.h>         // errno

#include <string.h>        // memset

#define DEBUG 0

int main()
{

 // prepare the data structure, defined in linux/gpio.h, in order to load data in it
 struct gpiochip_info chip_info;
 int fd, rv;


 // Get file descriptor, use read-write mode
 fd = open("/dev/gpiochip0", O_RDWR);
   if(fd == -1){ printf("fopen() failure: %d\n ", fd); return fd; }
   else{ if(DEBUG){printf("fopen() success: %d\n", fd);}}


 // Load data into the prepared structure
 rv = ioctl(fd, GPIO_GET_CHIPINFO_IOCTL, &chip_info);
 if(rv == -1)
  {
   // Save errno before any other call, that could set it differently
   int errsv = errno;
   printf("ioctl() failure: %d\n", rv);
   if(errsv == EBADF) printf("EBADF\n");
   if(errsv == EFAULT) printf("EFAULT\n");
   if(errsv == EINVAL) printf("EINVAL\n");
   if(errsv == ENOTTY) printf("ENOTTY\n");
   return rv;
  }
 else{ if(DEBUG){printf("ioctl() success: %d\n", rv);}}


 // Now, when we have the data, we can look at them
 printf("name: \t\t\t%s\n", chip_info.name);
 printf("label:\t\t\t%s\n", chip_info.label);
 printf("number of lines:\t%lu\n", (unsigned long) chip_info.lines);


 // ---------------------------------------------------------------------------
 printf("\n");


 // prepare the data structure, defined in linux/gpio.h, in order to load data in it
 struct gpioline_info line_info;


 memset(&line_info, 0, sizeof(line_info));
 line_info.line_offset = chip_info.lines - 1;


 rv = ioctl(fd, GPIO_GET_LINEINFO_IOCTL, &line_info);
 if(rv == -1)
  {
   // Save errno before any other call, that could set it differently
   int errsv = errno;
   printf("ioctl() failure: %d\n", rv);
   if(errsv == EBADF) printf("EBADF\n");
   if(errsv == EFAULT) printf("EFAULT\n");
   if(errsv == EINVAL) printf("EINVAL\n");
   if(errsv == ENOTTY) printf("ENOTTY\n");
   return rv;
  }
 else{ if(DEBUG){printf("ioctl() success: %d\n", rv);}}


 // Now, when we have the data, we can look at them
 printf("line offset:\t\t%lu\n", (unsigned long) line_info.line_offset);
 printf("flags:\t\t\t%lu\n", (unsigned long) line_info.flags);
 printf("name:\t\t\t%s\n", line_info.name);
 printf("consumer:\t\t%s\n", line_info.consumer);


 // ---------------------------------------------------------------------------
 printf("\n");


 // prepare the data structure, defined in linux/gpio.h, in order to load data in it
 struct gpiohandle_request request;


 request.flags |= GPIOHANDLE_REQUEST_OUTPUT;
 // We will request eactly 2 lines = 2 GPIO pins
 request.lines = 2;

 // For each requested line fill its number (offset) and default value
 request.lineoffsets[0] = 3;
 request.lineoffsets[1] = 5;
 request.default_values[0] = 1;
 request.default_values[1] = 0;

 strcpy(request.consumer_label, "my gpio program");


 rv = ioctl(fd, GPIO_GET_LINEHANDLE_IOCTL, &request);
 if(rv == -1)
  {
   // Save errno before any other call, that could set it differently
   int errsv = errno;
   printf("ioctl() failure: %d\n", rv);
   if(errsv == EBADF) printf("EBADF\n");
   if(errsv == EFAULT) printf("EFAULT\n");
   if(errsv == EINVAL) printf("EINVAL\n");
   if(errsv == ENOTTY) printf("ENOTTY\n");
   return rv;
  }
 else{ if(DEBUG){printf("ioctl() success: %d\n", rv);}}


 // ---------------------------------------------------------------------------
 printf("\n");


 struct gpiohandle_data data;


 // erase values inside
 memset(&data, 0, sizeof(data));


 // Now we are using the request FD !!
 rv = ioctl(request.fd, GPIOHANDLE_GET_LINE_VALUES_IOCTL, &data);
 if(rv == -1)
  {
   // Save errno before any other call, that could set it differently
   int errsv = errno;
   printf("ioctl() failure: %d\n", rv);
   if(errsv == EBADF) printf("EBADF\n");
   if(errsv == EFAULT) printf("EFAULT\n");
   if(errsv == EINVAL) printf("EINVAL\n");
   if(errsv == ENOTTY) printf("ENOTTY\n");
   return rv;
  }
 else{ if(DEBUG){printf("ioctl() success: %d\n", rv);}}


 printf("PIN 1:\t\t\t%lu\n", (unsigned long) data.values[0]);
 printf("PIN 2:\t\t\t%lu\n", (unsigned long) data.values[1]);


 data.values[0] = 0;
 data.values[1] = 1;


 // Now we are using the request FD !!
 rv = ioctl(request.fd, GPIOHANDLE_SET_LINE_VALUES_IOCTL, &data);
 if(rv == -1)
  {
   // Save errno before any other call, that could set it differently
   int errsv = errno;
   printf("ioctl() failure: %d\n", rv);
   if(errsv == EBADF) printf("EBADF\n");
   if(errsv == EFAULT) printf("EFAULT\n");
   if(errsv == EINVAL) printf("EINVAL\n");
   if(errsv == ENOTTY) printf("ENOTTY\n");
   return rv;
  }
 else{ if(DEBUG){printf("ioctl() success: %d\n", rv);}}


 // erase values inside
 memset(&data, 0, sizeof(data));


 // Now we are using the request FD !!
 rv = ioctl(request.fd, GPIOHANDLE_GET_LINE_VALUES_IOCTL, &data);
 if(rv == -1)
  {
   // Save errno before any other call, that could set it differently
   int errsv = errno;
   printf("ioctl() failure: %d\n", rv);
   if(errsv == EBADF) printf("EBADF\n");
   if(errsv == EFAULT) printf("EFAULT\n");
   if(errsv == EINVAL) printf("EINVAL\n");
   if(errsv == ENOTTY) printf("ENOTTY\n");
   return rv;
  }
 else{ if(DEBUG){printf("ioctl() success: %d\n", rv);}}
 printf("\nNew data set !\n\n");

 printf("PIN 1:\t\t\t%lu\n", (unsigned long) data.values[0]);
 printf("PIN 2:\t\t\t%lu\n", (unsigned long) data.values[1]);

 return 0;
}
