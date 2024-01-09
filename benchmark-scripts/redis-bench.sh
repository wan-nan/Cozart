#!/bin/bash
itr=20
reqcnt=100000

source benchmark-scripts/general-helper.sh
bootstrap;

cd /benchmark-scripts/redis-src/src
rm *.gcda
rm *.gcov
rm *.log
rm gmon.out
cd /benchmark-scripts/redis-src
rm gmon.out

src/redis-server > ser.log 2>&1 &
sleep 2;

# need to move to another folder according to 
# https://code.google.com/archive/p/redis/issues/584
# 
# " If you still want to use gprof, make sure to compile 
# with make PROF="-pg" V=on ; and check that -pg is 
# correctly used on all command lines. Also deactivate 
# bgsave (since the gmon.out file tends to be trashed by 
# forked child processes), and avoid to launch client 
# commands in the same directory as the gmon.out file 
# generated by the server "
# 
cd /benchmark-scripts/redis-src/src

redis-benchmark -n $reqcnt -t SET,GET --csv > ben.log 2>&1
redis-cli SHUTDOWN

gcov -f -w -c -j * > gcov_fwcj.log 2>&1
sync
