#!/bin/bash

### DO NOT CHANGE THIS
SCRIPTNAME="${0##*/}"

## check if your pool is on the explorer
function isPoolVisible() {
    stake_pool_id="$(awk '/node_id/ {print $2}' "$JORMUNGANDR_FILES"/node-secret.yaml)"
    if $JCLI rest v0 stake-pools get -h "$JORMUNGANDR_RESTAPI_URL" | grep "$stake_pool_id" >/dev/null 2>&1; then
        echo -e "\\nYour Pool is available here: https://shelleyexplorer.cardano.org/en/stake-pool/$stake_pool_id/\\n"
    else
        echo -e "\\nThe search for your pool returned nothing.\\n"
    fi
}

## check which IPs your pool has quarantined
function quarantinedIps() {
    echo "List of IP addresses that were quarantined somewhat recently:"
    curl -s "$JORMUNGANDR_RESTAPI_URL"/v0/network/p2p/quarantined | rg -o "/ip4/.{0,16}" | sed -r '/\n/!s/[0-9.]+/\n&\n/;/^([0-9]{1,3}\.){3}[0-9]{1,3}\n/P;D' | sort -u
    echo "End of somewhat recently quarantined IP addresses."
}

## check how many quaratined IPs are in the above list?
function nOfQuarantinedIps() {
    echo "How many IP addresses were quarantined?"
    quarantinedIps | wc -l
}

## check if your pool was recently quarantined
function isPoolQuarantined() {
    this_node=$(quarantinedIps | rg "${JORMUNGANDR_PUBLIC_IP_ADDR}")
    if [ -n "${this_node}" ]; then
        echo "ERROR! You were quarantined at some point in the recent past!"
        echo "Execute '$SCRIPTNAME --connected-estab' to confirm that you are connecting to other nodes."
    else
        echo "You are clean as a whistle."
    fi
}

## check if a block is valid. if NOT, your pool may be forking
function isBlockValid() {
    if [ -n "$1" ]; then
        blockId="$1"
    else
        echo "you must provide one paramenter, it must be a valid block id"
        echo "e.g: $SCRIPTNAME --block-valid blockId"
        exit 1
    fi

    if $JCLI rest v0 block "$blockId" next-id get -h "$JORMUNGANDR_RESTAPI_URL" >/dev/null 2>&1; then
        echo "Success: \"${blockId}\" is a VALID BLOCK"
    else
        echo "ERROR: \"${blockId}\" NOT FOUND!!! YOU COULD BE FORKED"
    fi
}

## check the current tip of your pool
function getCurrentTip() {
    CURRENTTIPHASH=$($JCLI rest v0 tip get -h "$JORMUNGANDR_RESTAPI_URL")
    LASTBLOCKHEIGHT="$($JCLI rest v0 node stats get -h "$JORMUNGANDR_RESTAPI_URL" | awk '/lastBlockHeight/ {print $2}' | sed 's/"//g')"
    LASTPOOLID="$($JCLI rest v0 block "$CURRENTTIPHASH" get -h "$JORMUNGANDR_RESTAPI_URL" | cut -c169-232)"

    echo "POOL TIP  : $LASTBLOCKHEIGHT"
    echo "TIP HASH  : $CURRENTTIPHASH"
    echo "LASTPOOL  : $LASTPOOLID"
}

## get a list of fragment_id
function fragmentsIds() {
    echo "This is a list of the current fragment_id:"
    $JCLI rest v0 message logs -h "$JORMUNGANDR_RESTAPI_URL" | grep "fragment_id"
}


## returns count for frament_id
function fragmentIdCount() {
    echo "What is the current fragment_id count?"
    $JCLI rest v0 message logs -h "$JORMUNGANDR_RESTAPI_URL" | grep -c "fragment_id"
}

## check the status of a transaction/frament
function fragmentStatus() {
    if [ -n "$1" ]; then
        fragment="$1"
    else
        echo "you must provide one paramenter, it must be a valid fragment_id"
        echo "e.g: $SCRIPTNAME --fragment fragment_id"
        exit 1
    fi

    $JCLI rest v0 message logs -h "$JORMUNGANDR_RESTAPI_URL" --output-format json | jq ".[] | select(.fragment_id==\"$fragment\")"
}

## top snapshot of jourmungandr
function resourcesStat() {
    echo "Here's some quick system resources stats for Jormungandr: "
    top -b -n 4 -d 0.2 -p "$(pidof jormungandr)" | tail -2
}

