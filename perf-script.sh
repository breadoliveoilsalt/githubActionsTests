#!/bin/bash

set -eo pipefail

ENV=$1
TOKEN=$2
BRANCH="lighthouseTesting"
DEV="dev"
QA="qa"
PROD="prod"
ORIGIN=""
URLS=""
LOG_FILE="curl_log.tmp"
OK_STATUS_CODE_RESPONSE="204"

function validate_args {
  if [[ ("$ENV" != "$DEV") && ("$ENV" != "$QA") && ("$ENV" != "$PROD") ]]; then
    echo 'ERROR: Must provide an argument for the environment: "dev", "qa", or "prod"'
    exit 1
  fi
}

function set_origin {
  case "$ENV" in
    "$DEV") ORIGIN="http://www.owasp.org"
      ;;
    "$QA") ORIGIN="https://owasp.org"
      ;;
    "$PROD") ORIGIN="https://www.owasp.org"
      ;;
    *) echo "Invalid environment"; exit 1;
      ;;
  esac
}

function generate_urls {
  while read -r LINE; do URLS+=${ORIGIN}${LINE}'\n'; done < pathnames.txt
}

function data_to_send_to_github {
  cat << EOF
{
  "ref": "$BRANCH",
  "inputs": {
    "env": "$ENV",
    "urls": "$URLS"
  }
}
EOF
}

function trigger_github_action {
  curl -iLSs \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/breadoliveoilsalt/githubActionsTests/actions/workflows/lighthouse-test.yml/dispatches" \
    -d "$(data_to_send_to_github)" \
    | tee "$LOG_FILE"
}

function check_trigger_succeded {
  if grep -q "$OK_STATUS_CODE_RESPONSE" <(cat "$LOG_FILE" | head -1); then
    echo "Data uploaded to Github"
    rm "$LOG_FILE"
    exit 0
  else
    echo "::error::perf-script.sh failed"
    rm "$LOG_FILE"
    exit 1
  fi
}

validate_args
set_origin
generate_urls
trigger_github_action
check_trigger_succeded
