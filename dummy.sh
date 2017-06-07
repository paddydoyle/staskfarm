#!/bin/bash
# a simple dummy script as a test case for the taskfarm
# script: it takes some arguments and writes them to stdout
dummy=$@
echo $dummy ':' $@
echo ${##dummy[@]}

if [[  ${##@[@]} -eq 0 ]]; then
    echo none
fi
