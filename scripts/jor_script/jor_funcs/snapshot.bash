#!/bin/bash

## gives a bird-view of node health and stats
## don't run this too often. a watch -n5 is more than enough
## NOTE: you could have multiple panels open with fewer checks in each one

## TODO: improve 'dashboard' and possibly offer switches for diversify info
function currentStatus() {
    clear
    echo "---"
    nextEpoch
    blocksDelta
    echo -e "$POOL_TICKER CONNECTS: $(netstat -punt 2>/dev/null | grep jormungandr | grep -c ESTAB)\\n"
    howManySlots
    nextScheduledBlock
    echo -e "\\n%CPU %MEM CACHE LOAD AVERAGE"
    echo -e "$(top -b -n 2 -d 0.1 -p "$(pidof jormungandr)" | tail -1 | awk '{print $9,$10}') $(free --mega -w | awk '/Mem:/ {print $7}')M  $(awk '{print $1,$2,$3}' /proc/loadavg)\\n"
    nodeStats
    echo
    echo "---"
    isBlockValid "$($JCLI rest v0 node stats get -h "$JORMUNGANDR_RESTAPI_URL" | awk '/lastBlockHash/ {print $2}')"
    echo
}

