#!/usr/bin/env bash
if [[ ! -z $NOTIFY_RPC ]]; then
  blocknotify $NOTIFY_RPC $NOTIFY_COINID $NOTIFY_PASSWORD "$@" 2>/var/log/notify.log
fi
