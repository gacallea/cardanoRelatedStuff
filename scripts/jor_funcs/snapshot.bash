#!/bin/bash

### DO NOT CHANGE THIS
SCRIPTNAME="${0##*/}"

## gives a bird-view of node health and stats
## don't run this too often. a watch -n5 is more than enough
## NOTE: you could have multiple tmux panels open with fewer checks in each one

function currentStatus() {
    clear
    echo "---"
    nextEpoch
    blocksDelta
    echo -e "$POOL_TICKER CONNECTS: $(netstat -punt 2>/dev/null | grep jormungandr | grep ESTAB | wc -l)\n"
    isPoolScheduled
    howManySlots
    #    scheduleDates
    #    scheduleTime
    echo -e "\n%CPU %MEM CACHE LOAD AVERAGE"
    echo -e "$(top -b -n 2 -d 0.1 -p $(pidof jormungandr) | tail -1 | awk '{print $9,$10}') $(free --mega -w | awk '/Mem:/ {print $7}')M $(cat /proc/loadavg | awk '{print $1,$2,$3}')\n"
    nodeStats
    echo
    echo "---"
    isBlockValid $($JCLI rest v0 node stats get -h $JORMUNGANDR_RESTAPI_URL | awk '/lastBlockHash/ {print $2}')
    echo
}
