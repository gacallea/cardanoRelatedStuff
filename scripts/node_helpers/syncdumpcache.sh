#!/bin/bash -x

## EXPERIMENTAL, USE AT YOUR OWN RISK!!!
### https://github.com/gacallea/cardanoRelatedStuff
## I noticed that keeping some kind of control on the cache, helps the node.
## place this script in /root/syncdumpcache.sh
## run this in a root crontab (crontab -e)
## */15 * * * * /root/syncdumpcache.sh

howMuchCache=$(/usr/bin/free --mega -w | /usr/bin/awk '/Mem:/ {print $7}')
maxCacheLimit=4096

if [ "$howMuchCache" -ge "$maxCacheLimit" ]; then
    /usr/bin/sync
    /usr/bin/echo 1 >/proc/sys/vm/drop_caches
fi
