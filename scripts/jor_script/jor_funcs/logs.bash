#!/bin/bash

## live scrolling current logs
function liveLogs() {
    journalctl -f -u jormungandr.service
}

## the last $howManyLines lines of the current logs
function lastLogs() {
    if [ -n "$1" ]; then
        howManyLines="$1"
        if ! [[ "$howManyLines" =~ ^[0-9]+$ ]]; then
            echo "Sorry integers only"
            exit 1
        fi
    else
        echo "you must provide how many lines you want to go far back in the logs, as one paramenter"
        echo "e.g: $SCRIPTNAME --last-logs 500"
        exit 2
    fi

    journalctl --no-pager -n "$howManyLines" -u jormungandr.service
}

## are there any serious problems in the last $howManyLines lines of the current logs?
function problemsInLogs() {
    if [ -n "$1" ]; then
        howManyLines="$1"
        if ! [[ "$howManyLines" =~ ^[0-9]+$ ]]; then
            echo "Sorry integers only"
            exit 1
        fi
    else
        echo "you must provide how many lines you want to go far back in the logs, as one paramenter"
        echo "e.g: $SCRIPTNAME --problems 500"
        exit 2
    fi

    journalctl --no-pager -n "$howManyLines" -u jormungandr.service | grep -i -E 'cannot|stuck|exit|unavailable'
}

## are there any issues in the last $howManyLines lines of the current logs?
function issuesInLogs() {
    if [ -n "$1" ]; then
        howManyLines="$1"
        if ! [[ "$howManyLines" =~ ^[0-9]+$ ]]; then
            echo "Sorry integers only"
            exit 1
        fi
    else
        echo "you must provide how many lines you want to go far back in the logs, as one paramenter"
        echo "e.g: $SCRIPTNAME --issues 500"
        exit 2
    fi

    journalctl --no-pager -n "$howManyLines" -u jormungandr.service | grep -E "WARN|ERRO"
}

