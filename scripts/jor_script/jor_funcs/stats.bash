#!/bin/bash

### DO NOT CHANGE THIS
SCRIPTNAME="${0##*/}"

## time and date calculations, used internally by the script
function intDateFunc() {
    ## getting a constant from jcli is taxing for the REST API....
    #chainstartdate=$($JCLI rest v0 settings get --host ${JORMUNGANDR_RESTAPI_URL} | awk '/block0Time/ {print $2}' | tr -d '"' | xargs -I{} date "+%s" -d {})
    ## .... better to just shove it in a variables if it changes..
    chainstartdate=1576264417
    elapsed=$((($(date +%s) - $chainstartdate)))
    epoch=$((($elapsed / 86400)))
    slot=$((($elapsed % 86400) / 2))
    nowBlockDate="$epoch.$slot"
    nextepoch="$((($(date +%s) + (86400 - (elapsed % 86400)))))"
    nextepochToDate="$(date --iso-8601=s -d@+$nextepoch)"
    dateNow="$(date --iso-8601=s)"
    ### currently not possible to calculate nowBlockHeight=""
}

## self-explanatory
function nodeStats() {
    $JCLI rest v0 node stats get -h $JORMUNGANDR_RESTAPI_URL
}

## self-explanatory
function poolStats() {
    $JCLI rest v0 stake-pool get $(cat $JORMUNGANDR_FILES/node-secret.yaml | awk '/node_id/ {print $2}') -h $JORMUNGANDR_RESTAPI_URL
}

## self-explanatory
function netStats() {
    $JCLI rest v0 network stats get -h $JORMUNGANDR_RESTAPI_URL
}

## check logs to calculate exact bootstrap time
function bootstrapTime() {
    JORMUNGANDR_PID=$(pidof jormungandr)
    JORMUNGANDR_PSTIME=$(ps -o etimes= -p $JORMUNGANDR_PID | awk '{print $1}')
    JORMUNGANDR_UPTIME=$($JCLI rest v0 node stats get -h $JORMUNGANDR_RESTAPI_URL | awk '/uptime/ {print $2}')
    toDatePSTIME=$(date --iso-8601=s -d@+$JORMUNGANDR_PSTIME)
    todateUPTIME=$(date --iso-8601=s -d@+$JORMUNGANDR_UPTIME)
    echo "$(dateutils.ddiff $todateUPTIME $toDatePSTIME -f "Bootstrap took exactly %M minutes and %S seconds")"
}

## self-explanatory
function accountBalance() {
    $JCLI rest v0 account get $RECEIVER_ACCOUNT -h $JORMUNGANDR_RESTAPI_URL
}

## self-explanatory
function currentBlockDate() {
    intDateFunc
    echo "nowBlockDate: \"$nowBlockDate\""
}

## self-explanatory
function nextEpoch() {
    intDateFunc
    echo "NEXT    EPOCH: $(dateutils.ddiff $dateNow $nextepochToDate -f "%H hours %M minutes and %S seconds")"
}

## currently not possible to calculate nowBlockHeight=""
## function tipHeightDelta() {
##     intDateFunc
##     lastBlockHeight="$($JCLI rest v0 node stats get -h $JORMUNGANDR_RESTAPI_URL | awk '/lastBlockHeight/ {print $2}' | sed 's/\"//g')"
##     deltaHeightCount=$(echo "$nowBlockHeight - $lastBlockHeight" | bc)
##
##     echo "CURRENT   TIP: $nowBlockHeight"
##     echo "$POOL_TICKER      TIP: $lastBlockHeight"
##     echo "TIP     DELTA: $deltaHeightCount"
## }

## what is the pool date delta?
function blocksDelta() {
    intDateFunc
    lastBlockDate="$($JCLI rest v0 node stats get -h $JORMUNGANDR_RESTAPI_URL | awk '/lastBlockDate/ {print $2}' | sed 's/\"//g')"
    deltaBlockCount=$(echo "$nowBlockDate - $lastBlockDate" | bc | sed 's/\./0\./g')

    echo "CURRENT  DATE: $nowBlockDate"
    echo "$POOL_TICKER     DATE: $lastBlockDate"
    echo "DATE    DELTA: $deltaBlockCount"

    #### DO NOT ENABLE THIS, NOT IMPLEMENTED YET
    ## UNDERSTAND THIS
    #    nextScheduledBlock
    #
    #    now=$(date +"%r")
    #
    #    isNumberRegex='^[0-9]+$'
    #    if [[ -z $lastBlockDate || ! $lastBlockDate =~ $isNumberRegex ]]; then
    #        echo -e "$now: Your node appears to be starting or not running at all. Execute 'stats' to get more info."
    #        return
    #    fi
    #    if [[ $deltaBlockCount -lt $deltaMax && $deltaBlockCount -gt 0 ]]; then
    #        echo -e "$now: WARNING: Your node is starting to drift. It could end up on an invalid fork soon."
    #        return
    #    fi
    #    if [[ $deltaBlockCount -gt $deltaMax ]]; then
    #        echo -e "$now: WARNING: Your node might be forked."
    #        return
    #    fi
    #    if [[ $deltaBlockCount -le 0 ]]; then
    #        echo -e "$now: Your node is running well."
    #        return
    #    fi
}

## check the count for last received dates in logs
function lastDates() {
    ## default values
    howManyLogLines=5000
    howManyDateResults=20

    ## how far back
    if [ -n "$1" ]; then
        howManyLogLines="$1"
        if ! [[ "$howManyLogLines" =~ ^[0-9]+$ ]]; then
            echo "Sorry integers only"
            exit 1
        fi
    fi

    ## how many to display
    if [ -n "$2" ]; then
        howManyDateResults="$2"
        if ! [[ "$howManyDateResults" =~ ^[0-9]+$ ]]; then
            echo "Sorry integers only"
            exit 1
        fi
    fi

    journalctl --no-pager -n $howManyLogLines -u jormungandr.service | awk '/date:/ {print $18}' | sort | uniq -c | sort -Vr -k2 | sed 's/,//g' | head -$howManyDateResults
}
