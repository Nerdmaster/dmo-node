#!/usr/bin/env bash
set -eo pipefail

# If there's no command, we just run the server
if [[ "${1:0:1}" == '' ]]; then
  set -- "-rpcuser=$RPC_USER" "-rpcpassword=$RPC_PASS" "-datadir=/dynamo/data" "-conf=/dynamo/dynamo.conf" "-nodebuglogfile" "$@"
fi

# If the command starts with a hyphen, prepend dynamo-core
if [ "${1:0:1}" = '-' ]; then
  set -- dynamo-core "$@"
fi

echo "Executing $@"
exec $@
