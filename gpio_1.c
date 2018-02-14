/* ----------------------------------------------------------------------------

 AUTHOR:
   Michal Schorm    mschorm@redhat.com

 NAME:
   Linux GPIO basics

 DESCRIPTION:
   This piece of code tries to open GPIO device and read some infromation
   about the GPIO chip.

 INFO:
   This software only works with 'linux/gpio.h' and in the case, you can see
   any GPIO devices in /dev/. Originally a different approach has been used
   in linux, by 'sysfs' kernel module, which allowed to work with GPIO through
   /sys/class/gpio/...

 COMPILATION:
   gcc -std=c99 -Wall -Wextra -Werror -pedantic -o gpio gpio_1.c && ./gpio

 SAMPLE OUTPUT:
   name: 			gpiochip0
   label:			INT33FF:00
   number of lines:		56

--------------------------------------------------------------------------- */

#include <stdio.h>
#include <stdlib.h>

#include <fcntl.h>         // open()
#include <unistd.h>        // close()
#include <sys/ioctl.h>     // ioctl()

#include <linux/gpio.h>

#include <errno.h>         // errno

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

 return 0;
}
