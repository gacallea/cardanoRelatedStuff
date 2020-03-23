#!/bin/bash

## self-explanatory
function leaderLogs() {
    echo "Leader Logs for $POOL_TICKER:"
    $JCLI rest v0 leaders logs get -h "$JORMUNGANDR_RESTAPI_URL"
}

## self-explanatory
function howManySlots() {
    echo -n "HOW MANY slots has $POOL_TICKER been scheduled for? "
    $JCLI rest v0 leaders logs get -h "$JORMUNGANDR_RESTAPI_URL" | grep -c created_at_time
}

## self-explanatory
function scheduleDates() {
    echo "Which DATES have been scheduled during this epoch?"
    $JCLI rest v0 leaders logs get -h "$JORMUNGANDR_RESTAPI_URL" | awk '/scheduled_at_date/ {print $2}' | sed 's/"//g' | sort -V
}

## self-explanatory
function scheduleTime() {
    echo "Which TIMES have been scheduled during this epoch?"
    $JCLI rest v0 leaders logs get -h "$JORMUNGANDR_RESTAPI_URL" | awk '/scheduled_at_time/ {print $2}' | sed 's/"//g' | sort -g
}

## self-explanatory
function nextScheduledBlock() {
    mapfile -t scheduleDateToTest < <($JCLI rest v0 leaders logs get -h "$JORMUNGANDR_RESTAPI_URL" | awk '/scheduled_at_time/ {print $2}' | sed 's/"//g' | sort -V)
    for i in "${scheduleDateToTest[@]}"; do
        if ! [[ $(dateutils.ddiff now "$i") =~ "-" ]]; then
            dateutils.ddiff now "$i" -f "BLOCK SCHEDULED IN %H hours %M minutes and %S seconds"
        fi
    done
}

