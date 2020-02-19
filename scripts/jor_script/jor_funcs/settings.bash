#!/bin/bash

## self-explanatory
function settings() {
    $JCLI rest v0 settings get -h "$JORMUNGANDR_RESTAPI_URL"
}

