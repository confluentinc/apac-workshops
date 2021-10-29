#!/bin/bash

retry() {
    local -r -i max_wait="$1"; shift
    local -r cmd="$@"

    local -i sleep_interval=5
    local -i curr_wait=0

    until $cmd
    do
        if (( curr_wait >= max_wait ))
        then
            echo "ERROR: Failed after $curr_wait seconds. Please troubleshoot and run again. For troubleshooting instructions see https://docs.confluent.io/platform/current/tutorials/cp-demo/docs/troubleshooting.html"
            return 1
        else
            printf "."
            curr_wait=$((curr_wait+sleep_interval))
            sleep $sleep_interval
        fi
    done

    PRETTY_PASS="\e[32m✔ \e[0m"
    printf "${PRETTY_PASS}%s\n\n"
}
