#!/bin/sh
# Reliable SSH to Contabo: pin host key + retry until the real VPS answers (not the stray :22 on same IP).
set -eu

SSH_HOST="${DEPLOY_SSH_HOST:-contabo}"
MAX_TRIES="${SSH_MAX_TRIES:-25}"
SLEEP_SEC="${SSH_RETRY_SLEEP:-1}"

SSH_OPTS="${SSH_OPTS:--o BatchMode=yes -o ConnectTimeout=20}"

ssh_contabo() {
  n=1
  while [ "$n" -le "$MAX_TRIES" ]; do
    if ssh $SSH_OPTS "$SSH_HOST" "$@"; then
      return 0
    fi
    n=$((n + 1))
    sleep "$SLEEP_SEC"
  done
  echo "ssh: gave up after ${MAX_TRIES} tries ($SSH_HOST)" >&2
  return 1
}

if [ "${1:-}" = "--exec" ]; then
  shift
  ssh_contabo "$@"
fi
