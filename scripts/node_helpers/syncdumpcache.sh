#!/bin/bash -x

## EXPERIMENTAL, USE AT YOUR OWN RISK!!!
## I noticed that keeping some kind of control on the cache, helps the node.
## run this in a root crontab (crontab -e)
## */15 * * * * /root/nodehelperscripts/syncdumpcache.sh

howMuchCache=$(/usr/bin/free --mega -w | /usr/bin/awk '/Mem:/ {print $7}')
maxCacheLimit=4096

if [ "$howMuchCache" -ge "$maxCacheLimit" ]; then
    /usr/bin/sync
    /usr/bin/echo 1 >/proc/sys/vm/drop_caches
fi
