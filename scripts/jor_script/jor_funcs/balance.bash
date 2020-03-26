#!/bin/bash

## get stakes distribution for pool
function currentStakes() {
    blah="$(awk '/node_id/ {print $2}' "$JORMUNGANDR_SECRET")"
    totalStake="$($JCLI rest v0 stake get -h "$JORMUNGANDR_RESTAPI_URL" | sed -n "/$blah/{n;p;}" | awk '{print $2}')"
    echo "CURRENT Staking amounts to $((totalStake / 1000000)) ADA"
}

## get stakes distribution for pool
function epochStakes() {
    intDateFunc

    ## which epoch we want the stat for?
    if [ -n "$1" ]; then
        wantedEpoch="$1"
        if ! [[ "$wantedEpoch" =~ ^[0-9]+$ ]]; then
            echo "INT Error: the epoch number can be integers only"
            exit 30
        fi

        if [[ "$wantedEpoch" -gt "$epoch" ]]; then
            echo "EPOCH Error: the epoch cannot be in the future"
            exit 40
        fi

        if [[ "$wantedEpoch" -lt 0 ]]; then
            echo "EPOCH Error: the epoch cannot be less than the first epoch"
            exit 40
        fi
    else
        echo "you must provide one paramenter, it must be a valid epoch"
        echo "e.g: $SCRIPTNAME --epoch-stakes $1 <epoch>"
        exit 1
    fi

    blah="$(awk '/node_id/ {print $2}' "$JORMUNGANDR_SECRET")"
    totalStake="$($JCLI rest v0 stake get -h "$JORMUNGANDR_RESTAPI_URL" "$wantedEpoch" | sed -n "/$blah/{n;p;}" | awk '{print $2}')"
    echo "EPOCH $2 Staking was $((totalStake / 1000000)) ADA"
}

## self-explanatory
function liveStake() {
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

## Get rewards history for a specific epoch
## https://input-output-hk.github.io/jormungandr/jcli/rest.html#get-rewards-history-for-a-specific-epoch
function oneEpochRewards() {
    ## which epoch we want the stat for?
    if [ -n "$1" ]; then
        wantedEpoch="$1"
        if ! [[ "$wantedEpoch" =~ ^[0-9]+$ ]]; then
            echo "INT Error: the epoch number can be integers only"
            exit 30
        fi

        if [[ "$wantedEpoch" -gt "$epoch" ]]; then
            echo "EPOCH Error: the epoch cannot be in the future"
            exit 40
        fi

        if [[ "$wantedEpoch" -lt 0 ]]; then
            echo "EPOCH Error: the epoch cannot be less than the first epoch"
            exit 40
        fi
    else
        echo "you must provide one paramenter, it must be a valid epoch"
        echo "e.g: $SCRIPTNAME --epoch-stakes $1 <epoch>"
        exit 1
    fi

    $JCLI rest v0 rewards epoch get "$wantedEpoch" -h "$JORMUNGANDR_RESTAPI_URL" | jq .
}

## Get rewards history for some epochs
## https://input-output-hk.github.io/jormungandr/jcli/rest.html#get-rewards-history-for-some-epochs
function rewardsHistory() {
    intDateFunc

    ## which epoch we want the stat for?
    if [ -n "$1" ]; then
        historyLength="$1"
        if ! [[ "$historyLength" =~ ^[0-9]+$ ]]; then
            echo "INT Error: the epoch history length number can be integers only"
            exit 30
        fi

        if [[ "$historyLength" -gt "$epoch" ]]; then
            echo "EPOCH Error: the epoch history length cannot be greater than the current epoch total"
            exit 40
        fi

        if [[ "$historyLength" -lt 1 ]]; then
            echo "EPOCH Error: the epoch cannot be less than one epoch"
            exit 40
        fi
    else
        echo "you must provide one paramenter, it must be a valid history length"
        echo "e.g: $SCRIPTNAME --epoch-stakes $1 <length>"
        exit 1
    fi

    $JCLI rest v0 rewards history get "$historyLength" -h "$JORMUNGANDR_RESTAPI_URL" | jq .
}

