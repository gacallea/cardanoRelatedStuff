#!/bin/bash

### DO NOT CHANGE THIS
SCRIPTNAME="${0##*/}"

## check if your pool is on the explorer
function isPoolVisible() {
    stake_pool_id="$(cat $JORMUNGANDR_FILES/node-secret.yaml | awk -F: '/node_id/ {print $2}' | sed 's/ //g')"
    if $JCLI rest v0 stake-pools get --host "$JORMUNGANDR_RESTAPI_URL" | grep $stake_pool_id 2>&1>/dev/null; then
        echo -e "\nYour Pool is available here: https://shelleyexplorer.cardano.org/en/stake-pool/$stake_pool_id/\n"
    else
        echo -e "\nThe search for your pool returned nothing.\n"
    fi
}

## check which IPs your pool has quarantined
function quarantinedIps() {
    echo "List of IP addresses that were quarantined somewhat recently:"
    curl -s $JORMUNGANDR_RESTAPI_URL/v0/network/p2p/quarantined | rg -o "/ip4/.{0,16}" | tr -d '/ip4tcp' | sort -u
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
    if [ -n ${this_node} ]; then
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
        echo "e.g: $SCRIPTNAME --block-valid #blockId"
        exit 1
    fi

    if $JCLI rest v0 block $blockId next-id get -h $JORMUNGANDR_RESTAPI_URL 2>&1>/dev/null; then
        echo "Success: \"${blockId}\" is a VALID BLOCK"
    else
        echo "ERROR: \"${blockId}\" NOT FOUND!!! YOU COULD BE FORKED"
    fi
}

## check the current tip of your pool
function getCurrentTip() {
    CURRENTTIPHASH=$($JCLI rest v0 tip get -h $JORMUNGANDR_RESTAPI_URL)
    LASTBLOCKHEIGHT="$($JCLI rest v0 node stats get -h $JORMUNGANDR_RESTAPI_URL | awk '/lastBlockHeight/ {print $2}' | sed 's/"//g')"
    LASTPOOLID="$($JCLI rest v0 block $CURRENTTIPHASH get -h $JORMUNGANDR_RESTAPI_URL | cut -c169-232)"

    echo "POOL TIP  : $LASTBLOCKHEIGHT"
    echo "LASTHASH  : $CURRENTTIPHASH"
    echo "LASTPOOL  : $LASTPOOLID"
}

## TODO: UNDERSTAND what fragment_id is and possibly make this func better
function fragmentIdCount() {
    echo "What is the current fragment_id count?"
    $JCLI rest v0 message logs -h $JORMUNGANDR_RESTAPI_URL | grep "fragment_id" | wc -l
}

## top snapshot of jourmungandr
function resourcesStat() {
    echo "Here's some quick system resources stats for Jormungandr: "
    top -b -n 4 -d 0.2 -p $(pidof jormungandr) | tail -2
}
