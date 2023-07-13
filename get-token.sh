#!/usr/bin/env bash

set -eu

TPS_URL="$1"
TOKEN="$2"

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

# get_ci_token
get_ci_token() {
  log "Requesting CI token"

  if [[ -z "$ACTIONS_ID_TOKEN_REQUEST_URL" ]]; then
    log "ACTIONS_ID_TOKEN_REQUEST_URL is empty"
    exit 1
  fi
  if [[ -z "$ACTIONS_ID_TOKEN_REQUEST_TOKEN" ]]; then
    log "ACTIONS_ID_TOKEN_REQUEST_TOKEN is empty"
    exit 1
  fi

  do_request \
    --header "Authorization: Bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
    "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=tps" |
    jq -r .value
}

# get_token <ci_token>
get_token() {
  log "Requesting token"
  do_request --request POST \
    --header "Authorization: Bearer $1" \
    "$TPS_URL"
}

if [[ -z "$TOKEN" ]]; then
  # Static HCLOUD_TOKEN not provided, fetch a token from TPS.
  CI_TOKEN=$(get_ci_token)

  TOKEN="$(get_token "$CI_TOKEN")"
fi

if [[ "${TOKEN:-}" == "" ]]; then
  echo "::error ::Couldn't determine HCLOUD_TOKEN. Are repository secrets correctly set?"
  exit 1
fi

echo "::add-mask::$TOKEN"
echo "HCLOUD_TOKEN=$TOKEN" >> "$GITHUB_ENV"
