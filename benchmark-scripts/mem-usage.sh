#!/usr/bin/env bash
source /benchmark-scripts/general-helper.sh
mount -t proc proc /proc;
echo -e "\n--------------Debug info--------------"
echo "Kernel: $1"
cat /proc/meminfo | awk '/MemTotal/ {total=$2} /MemFree/ {free=$2} END {print "MemTotal: " total;print "MemFree: " free; print "MemTotal-MemFrees: " total-free}'
echo -e "--------------Debug info--------------\n"
