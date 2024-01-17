#!/bin/bash

# only measured the boot time once
# in the paper, the boot time can be accurate to milliseconds because it measured 10 times and took the average value
mount -t proc proc /proc
echo -e "\n--------------Debug info--------------"
echo "Boot time:"
echo "Boot $1 took $(cut -d' ' -f1 /proc/uptime) seconds"
echo -e "--------------Debug info--------------\n"
