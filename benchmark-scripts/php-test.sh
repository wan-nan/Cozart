#!/bin/bash
itr=20
reqcnt=100000

source benchmark-scripts/general-helper.sh
bootstrap
mark_start;
echo n | make -C benchmark-scripts/php-src test
mark_end;
write_modules
