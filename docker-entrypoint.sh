#!/bin/bash

RDB_CLUSTER_RETRY_COUNT="${RDB_CLUSTER_RETRY_COUNT:-3}"
RDB_CLUSTER_RETRY_INTERVAL="${RDB_CLUSTER_RETRY_INTERVAL:-5}"

if which "$1" &> /dev/null; then
  exec "$@"
fi

set -- rethinkdb --bind all "$@"

RETRY=0
if [ ! -z "$RDB_CLUSTER_SRV_ADDRESS" ]; then
  for RETRY in $(seq 1 $RDB_CLUSTER_RETRY_COUNT); do
    NODES="$(host -t SRV $RDB_CLUSTER_SRV_ADDRESS)"
    if echo "$NODES" | grep NXDOMAIN &> /dev/null; then
      echo "could not determine resolve '${RDB_CLUSTER_SRV_ADDRESS}', waiting $RDB_CLUSTER_RETRY_INTERVAL seconds" >&2

      if [ $RETRY -eq $RDB_CLUSTER_RETRY_COUNT ]; then
        echo 'aborting'
        exit 1
      fi

      sleep $RDB_CLUSTER_RETRY_INTERVAL && continue
    fi

    NODES="$(echo "$NODES" | shuf | grep -v "$HOST")"

    while read LINE; do
      RDB_HOST="$(echo $LINE| awk '{print $8}' | head -c -2)"
      RDB_PORT="$(echo $LINE | awk '{print $7}')"

      set -- "$@" --join "$RDB_HOST:$RDB_PORT"
    done < <(echo "$NODES")

    break
  done
fi

echo "$@"
exec "$@"
