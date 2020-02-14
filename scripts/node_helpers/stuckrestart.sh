#!/bin/bash -x

### THIS SCRIPT IS EXPERIMENTAL, USE AT YOUR OWN RISK.

### https://github.com/gacallea/cardanoRelatedStuff
### this script checks against date delta and last received block time delta
### if conditions are met (defaults to 100 slots and 5 minutes lag) it restarts the node
### put the script in '/root/stuckrestart.sh'
### put this in root's crontab (crontab -e):
### */5 * * * * /root/stuckrestart.sh

## CHANGE TO WHAT SUITS YOU THE BEST
maxBlockDelta=100 ## incremental
maxDateDelta=300  ## seconds

#######################################################################################################################################

### DO NOT EDIT PAST THIS POINT ### ## DO NOT CHANGE ### DO NOT EDIT PAST THIS POINT ### ## DO NOT CHANGE #### ## #
### DO NOT EDIT PAST THIS POINT ### ## DO NOT CHANGE ### DO NOT EDIT PAST THIS POINT ### ## DO NOT CHANGE #### ## #

JORMUNGANDR_RESTAPI_PORT="<REST_API_PORT>"
JORMUNGANDR_RESTAPI_URL="http://127.0.0.1:${JORMUNGANDR_RESTAPI_PORT}/api"

JCLI="$(command -v jcli)"
[ -z "${JCLI}" ] && [ -f jcli ] && JCLI="./jcli"

JORM="$(command -v jormungandr)"
[ -z "${JORM}" ] && [ -f jormungandr ] && JORM="./jormungandr"
## jcli path
JCLI="$(command -v jcli)"
[ -z "${JCLI}" ] && JCLI="/usr/local/bin/jcli"

## jormungandr path
JORM="$(command -v jormungandr)"
[ -z "${JORM}" ] && JORM="/usr/local/bin/jormungandr"

## time and date calculations, used internally by the script
function intDateFunc() {
    chainstartdate=1576264417
    elapsed=$((($(date +%s) - chainstartdate)))
    epoch=$(((elapsed / 86400)))
    slot=$(((elapsed % 86400) / 2))
    nowBlockDate="$epoch.$slot"
    dateNow="$(date --iso-8601=s)"
}

## what is the pool block delta?
function blocksDelta() {
    intDateFunc
    lastBlockDate="$($JCLI rest v0 node stats get -h "$JORMUNGANDR_RESTAPI_URL" | awk '/lastBlockDate/ {print $2}' | sed 's/\"//g')"
    deltaBlockCount=$(echo "$nowBlockDate - $lastBlockDate" | bc | sed 's/0//g' | sed 's/\.//g')
    return "$deltaBlockCount"
}

## what is the pool block delta?
function lastDelta() {
    intDateFunc
    lastReceivedTime="$($JCLI rest v0 node stats get -h "$JORMUNGANDR_RESTAPI_URL" | awk '/lastReceivedBlockTime/ {print $2}' | sed 's/\"//g')"
    deltaReceivedCount=$(dateutils.ddiff "$lastReceivedTime" "$dateNow" -f '%S')
    return "$deltaReceivedCount"
}

## pool state?
poolStatus=$($JCLI rest v0 node stats get -h "$JORMUNGANDR_RESTAPI_URL" | awk '/state/ {print $2}')

## if the pool is running, check against the blocks delta
if [ "$poolStatus" == "Running" ]; then
    blocksDelta
    if [ "$deltaBlockCount" -ge "$maxBlockDelta" ]; then
        ## if the date delta is 100 or more, check against received blocks delta with current date
        lastDelta
        if [ "$deltaReceivedCount" -ge "$maxDateDelta" ]; then
            ## if the received delta is 300 or more seconds, restart jormungandr
            /usr/bin/systemctl restart jormungandr.service
        fi
    fi
elif [ "$poolStatus" == "Bootstrapping" ]; then
    echo "the pool is Bootstrapping, exiting the routine"
    exit 1
else
    echo "the pool is not running, exiting the routine"
    exit 127
fi
