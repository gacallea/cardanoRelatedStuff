#!/bin/bash

## time and date calculations, used internally by the script
function intDateFunc() {
    ## getting a constant from jcli is taxing for the REST API....
    #chainstartdate=$($JCLI rest v0 settings get -h "$JORMUNGANDR_RESTAPI_URL" | awk '/block0Time/ {print $2}' | tr -d '"' | xargs -I{} date "+%s" -d {})
    ## .... better to just shove it in a variables if it changes..
    chainstartdate=1576264417
    elapsed=$((($(date +%s) - chainstartdate)))
    epoch=$(((elapsed / 86400)))
    slot=$(((elapsed % 86400) / 2))
    nowBlockDate="$epoch.$slot"
    nextepoch="$((($(date +%s) + (86400 - (elapsed % 86400)))))"
    nextepochToDate="$(date --iso-8601=s -d@+$nextepoch)"
    dateNow="$(date --iso-8601=s)"
    ### not possible to calculate nowBlockHeight=""
}

## self-explanatory
function nodeStats() {
    $JCLI rest v0 node stats get -h "$JORMUNGANDR_RESTAPI_URL"
}

## self-explanatory
function poolStats() {
    $JCLI rest v0 stake-pool get "$(awk '/node_id/ {print $2}' "$JORMUNGANDR_SECRET")" -h "$JORMUNGANDR_RESTAPI_URL"
}

## self-explanatory
function netStats() {
    $JCLI rest v0 network stats get -h "$JORMUNGANDR_RESTAPI_URL"
}

## get stakes distribution for pool
function currentStakes() {
    blah="$(awk '/node_id/ {print $2}' "$JORMUNGANDR_SECRET")"
    totalStake="$($JCLI rest v0 stake get -h "$JORMUNGANDR_RESTAPI_URL" | sed -n "/$blah/{n;p;}" | awk '{print $2}')"
    echo "CURRENT Staking amounts to $((totalStake / 1000000)) ADA"
}

## self-explanatory
function liveStakes() {
    totalStake="$($JCLI rest v0 stake-pool get "$(awk '/node_id/ {print $2}' "$JORMUNGANDR_SECRET")" -h "$JORMUNGANDR_RESTAPI_URL" | awk '/total_stake/ {print $2}')"
    echo "LIVE Staking amounts to $((totalStake / 1000000)) ADA"
}

## self-explanatory
function accountBalance() {
    $JCLI rest v0 account get "$RECEIVER_ACCOUNT" -h "$JORMUNGANDR_RESTAPI_URL"
}

## self-explanatory
function rewardsBalance() {
    rewardsTotal="$($JCLI rest v0 account get "$RECEIVER_ACCOUNT" -h "$JORMUNGANDR_RESTAPI_URL" | awk '/value/ {print $2}')"
    echo "Current Rewards Total to $((rewardsTotal / 1000000)) ADA"
}

## top snapshot of jourmungandr
function resourcesStat() {
    echo "Here's some quick system resources stats for Jormungandr: "
    top -b -n 4 -d 0.2 -p "$(pidof jormungandr)" | tail -2
}

## check logs to calculate exact bootstrap time
function bootstrapTime() {
    JORMUNGANDR_STATE=$($JCLI rest v0 node stats get -h "$JORMUNGANDR_RESTAPI_URL" | awk '/state/ {print $2}')
    if [ "$JORMUNGANDR_STATE" == "Bootstrapping" ]; then
        echo -e "\\nJormungandr is still bootstrapping, check back soon\\n"
        exit 1
    else
        JORMUNGANDR_PID=$(pidof jormungandr)
        JORMUNGANDR_UPTIME=$($JCLI rest v0 node stats get -h "$JORMUNGANDR_RESTAPI_URL" | awk '/uptime/ {print $2}')
        JORMUNGANDR_PSTIME=$(ps -o etimes= -p "$JORMUNGANDR_PID" | awk '{print $1}')
        todateUPTIME=$(date --iso-8601=s -d@+"$JORMUNGANDR_UPTIME")
        toDatePSTIME=$(date --iso-8601=s -d@+"$JORMUNGANDR_PSTIME")
        echo -e "\\n$(dateutils.ddiff "$todateUPTIME" "$toDatePSTIME" -f "Bootstrap took exactly %M minutes and %S seconds")\\n"
    fi
}

## when was jormungandr last restarted
function lastStart() {
    JORMUNGANDR_PID=$(pidof jormungandr)
    JORMUNGANDR_PSTIME=$(ps -o etimes= -p "$JORMUNGANDR_PID" | awk '{print $1}')
    echo -e "\\nJormungandr was last started @: $(date --date "-$JORMUNGANDR_PSTIME seconds")\\n"
}

## self-explanatory
function currentBlockDate() {
    intDateFunc
    echo "nowBlockDate: \"$nowBlockDate\""
}

## self-explanatory
function nextEpoch() {
    intDateFunc
    echo "NEXT    EPOCH: $(dateutils.ddiff "$dateNow" "$nextepochToDate" -f "%H hours %M minutes and %S seconds")"
}

## currently not possible to calculate nowBlockHeight=""
## function tipHeightDelta() {
##     intDateFunc
##     lastBlockHeight="$($JCLI rest v0 node stats get -h "$JORMUNGANDR_RESTAPI_URL" | awk '/lastBlockHeight/ {print $2}' | sed 's/\"//g')"
##     deltaHeightCount=$(echo "$nowBlockHeight - $lastBlockHeight" | bc)
##
##     echo "CURRENT   TIP: $nowBlockHeight"
##     echo "$POOL_TICKER      TIP: $lastBlockHeight"
##     echo "TIP     DELTA: $deltaHeightCount"
## }

## check the current tip of your pool
function getCurrentTip() {
    CURRENTTIPHASH=$($JCLI rest v0 tip get -h "$JORMUNGANDR_RESTAPI_URL")
    LASTBLOCKHEIGHT="$($JCLI rest v0 node stats get -h "$JORMUNGANDR_RESTAPI_URL" | awk '/lastBlockHeight/ {print $2}' | sed 's/"//g')"
    LASTPOOLID="$($JCLI rest v0 block "$CURRENTTIPHASH" get -h "$JORMUNGANDR_RESTAPI_URL" | cut -c169-232)"

    echo "POOL TIP  : $LASTBLOCKHEIGHT"
    echo "TIP HASH  : $CURRENTTIPHASH"
    echo "LASTPOOL  : $LASTPOOLID"
}

## what is the pool date delta?
function blocksDelta() {
    intDateFunc
    lastBlockDate="$($JCLI rest v0 node stats get -h "$JORMUNGANDR_RESTAPI_URL" | awk '/lastBlockDate/ {print $2}' | sed 's/\"//g')"
    deltaBlockCount=$(echo "$nowBlockDate - $lastBlockDate" | bc)
    if ! [[ "$deltaBlockCount" =~ ^[0-9]+$ ]]; then
        deltaBlockCount="${deltaBlockCount//\./0\.}"
    fi

    echo "CURRENT  DATE: $nowBlockDate"
    echo "$POOL_TICKER     DATE: $lastBlockDate"
    echo "DATE    DELTA: $deltaBlockCount"
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

    journalctl --no-pager -n "$howManyLogLines" -u jormungandr.service | awk '/date:/ {print $18}' | sort | uniq -c | sort -Vr -k2 | sed 's/,//g' | head -"$howManyDateResults"
}

