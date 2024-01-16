#!/usr/bin/env bash
source /benchmark-scripts/general-helper.sh
mount -t proc proc /proc;
echo -e "\n--------------Debug info--------------"
echo "Kernel: $1"
cat /proc/meminfo | head -n1 | cut -f2
echo -e "--------------Debug info--------------\n"
