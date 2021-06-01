#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

CONNECTOR_ENDPOINT=${1:-"http://localhost:8083"}

if [[ -z ${1} ]]; then
  echo "usage: bash start_connect_tasks.sh <kafka_connect_url>"
  exit 1
fi

curl -X PUT \
  -H "Content-Type: application/json" \
  --data @etc/connector-config/source-fitbit-config.json \
  ${1} | jq .
