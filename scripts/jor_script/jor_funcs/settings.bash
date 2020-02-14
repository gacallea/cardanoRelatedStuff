#!/bin/bash

### DO NOT CHANGE THIS
SCRIPTNAME="${0##*/}"

## self-explanatory
function settings() {
    $JCLI rest v0 settings get -h "$JORMUNGANDR_RESTAPI_URL"
}

