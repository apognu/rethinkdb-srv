#!/bin/bash

if [ "${1:0:1}" = '-' ]; then
	set -- rethinkdb --bind all "$@"
fi

RETRY=0
if [ ! -z "$RDB_CLUSTER_SRV_ADDRESS" ]; then
  while true; do
    DNS="$(host -t SRV $RDB_CLUSTER_SRV_ADDRESS)"
    if echo "$DNS" | grep NXDOMAIN &> /dev/null; then
      echo "could not determine resolve '${RDB_CLUSTER_SRV_ADDRESS}', waiting 5 seconds" >&2

      if [ "$RETRY" == "1" ]; then
        echo 'aborting'
        exit 1
      fi

      RETRY=1
      sleep 5 && continue
    fi

    SELECTED="$(echo $DNS | shuf | head -1)"
    HOST="$(echo $SELECTED | awk '{print $8}' | head -c -2)"
    PORT="$(echo $SELECTED | awk '{print $7}')"

    set -- "$@" --join $HOST:$PORT
    break
  done
fi

exec "$@"
