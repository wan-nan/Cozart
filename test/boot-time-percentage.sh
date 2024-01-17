#!/bin/bash
average=$(grep -r "avg boot-time =" test/ | grep ".base.boot-time" | awk '{
    if ($4 !~ /[A-Za-z]/){
        sum += $4; 
        n++ 
    }
    } END { 
        if (n > 0) 
            print sum / n; 
    }')

# echo "Average Boot Time: $average"
# grep -r "avg boot-time =" test/ | grep -v ".base.boot-time" | awk '{ print 1-$4/$average }'
grep -r "avg boot-time =" test/ | grep -v ".base.boot-time" | awk -v average="$average" '{ 
    if ($4 !~ /[A-Za-z]/ && average != 0){
        print $1
        print 1 - $4 / average
    }
}'