#!/bin/bash

### DO NOT CHANGE THIS
SCRIPTNAME="${0##*/}"

### NOTE FOR CHRIS: PLEASE TEST THESE AS MY POOL HAS NEVER BEEN SCHEDULED AND I CANNOT CONFIRM THEM ###
### NOTE FOR CHRIS: PLEASE TEST THESE AS MY POOL HAS NEVER BEEN SCHEDULED AND I CANNOT CONFIRM THEM ###
### NOTE FOR CHRIS: PLEASE TEST THESE AS MY POOL HAS NEVER BEEN SCHEDULED AND I CANNOT CONFIRM THEM ###

## self-explanatory
function isPoolScheduled() {
    echo -n "Has this node been scheduled to be leader?  ==>   "
    $JCLI rest v0 leaders logs get -h $JORMUNGANDR_RESTAPI_URL | grep -v "\-\-"
}

## self-explanatory
function howManySlots() {
    echo -n "HOW MANY slots has this leader been scheduled for? "
    $JCLI rest v0 leaders logs get -h $JORMUNGANDR_RESTAPI_URL | grep created_at_time | wc -l
}

## self-explanatory
function scheduleDates() {
    echo "Which DATES have been scheduled during this epoch?"
    $JCLI rest v0 leaders logs get -h $JORMUNGANDR_RESTAPI_URL | grep scheduled_at_date | cut -d'"' -f2 | cut -d'.' -f2 | sort -g
}

## self-explanatory
function scheduleTime() {
    echo "Which TIMES have been scheduled during this epoch?"
    $JCLI rest v0 leaders logs get -h $JORMUNGANDR_RESTAPI_URL | grep scheduled_at_time | sort
}

## self-explanatory
function nextScheduledBlock() {
    internalTimeFunc
    NEWEPOCH=$epoch
    maxSlots=$($JCLI rest v0 leaders logs get -h $JORMUNGANDR_RESTAPI_URL | grep -P 'scheduled_at_date: "'$NEWEPOCH'.' | grep -P '[0-9]+' | wc -l)
    leaderSlots=$($JCLI rest v0 leaders logs get -h $JORMUNGANDR_RESTAPI_URL | grep -P 'scheduled_at_date: "'$NEWEPOCH'.' | grep -P '[0-9]+' | awk -v i="$rowIndex" '{print $2}' | awk -F "." '{print $2}' | tr '"' ' ' | sort -V)

    for ((rowIndex = 1; rowIndex <= $maxSlots; rowIndex++)); do
        currentSlotTime=$((slot / 2))
        blockCreatedSlotTime=$(awk -v i="$rowIndex" 'NR==i {print $1}' <<<$leaderSlots)

        if [[ $blockCreatedSlotTime -ge $currentSlotTime ]]; then
            timeToNextSlotLead=$(($blockCreatedSlotTime - $currentSlotTime))
            currentTime=$(date +%s)
            nextBlockDate=$(($chainstartdate + $blockCreatedSlotTime * 2 + ($epoch) * 86400))
            echo "TimeToNextSlotLead: " $(awk '{print int($1/(3600*24))":"int($1/60)":"int($1%60)}' <<<$(($timeToNextSlotLead * 2))) "("$(awk '{print strftime("%c",$1)}' <<<$nextBlockDate)") - $(($blockCreatedSlotTime))"
            break
        fi
    done
}

