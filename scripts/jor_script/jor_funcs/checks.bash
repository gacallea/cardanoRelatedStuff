#!/bin/bash

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

