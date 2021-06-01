#!/usr/bin/env bash

CONNECTOR_ENDPOINT=${1:-"http://localhost:8083"}
CONNECTOR_NAME=${2:-"radar-fitbit-source"}

if [[ -z ${1} ]]; then
  echo "usage: bash get_status.sh <kafka_connect_url> <connector_name>"
  exit 1
fi

curl -X GET \
  -H "Content-Type: application/json" \
  "${CONNECTOR_ENDPOINT}/connectors/${CONNECTOR_NAME}/status" | jq .
