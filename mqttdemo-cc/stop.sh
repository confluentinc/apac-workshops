#!/bin/bash

docker-compose down

source ./ccloud_library.sh
. delta_configs/env.delta
ccloud::destroy_ccloud_stack $SERVICE_ACCOUNT_ID
rm -rf delta_configs
rm -rf stack-configs
rm mqtt-source.json
