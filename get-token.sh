#!/usr/bin/env bash

set -eu

tps_url="$1"
hcloud_token="$2"

log() {
  echo >&2 "$*"
}

# do_request [<args>...]
do_request() {
  curl \
    --fail-with-body \
    --retry 2 \
    --silent \
    --user-agent "tps-action/unknown" \
    "$@"
}

# get_gha_token
get_gha_token() {
  log "Requesting Github Action token"

  if [[ -z "$ACTIONS_ID_TOKEN_REQUEST_URL" ]]; then
    log "::error::ACTIONS_ID_TOKEN_REQUEST_URL is empty"
    exit 1
  fi
  if [[ -z "$ACTIONS_ID_TOKEN_REQUEST_TOKEN" ]]; then
    log "::error::ACTIONS_ID_TOKEN_REQUEST_TOKEN is empty"
    exit 1
  fi

  do_request \
    --header "Authorization: Bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
    "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=tps" |
    jq -r .value
}

# get_hcloud_token <gha_token>
get_hcloud_token() {
  log "Requesting HCloud token"
  do_request --request POST \
    --header "Authorization: Bearer $1" \
    "$tps_url"
}

if [[ -z "$hcloud_token" ]]; then
  # Static HCLOUD_TOKEN not provided, fetch a token from TPS.
  gha_token=$(get_gha_token)

  hcloud_token="$(get_hcloud_token "$gha_token")"
fi

if [[ "${hcloud_token:-}" == "" ]]; then
  log "::error::Couldn't determine HCLOUD_TOKEN. Are repository secrets correctly set?"
  exit 1
fi

echo "::add-mask::$hcloud_token"
echo "HCLOUD_TOKEN=$hcloud_token" >> "$GITHUB_ENV"
