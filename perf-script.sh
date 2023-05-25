#!/bin/bash

# set -Eeou pipefail

if [[ ("$1" != "dev") && ("$1" != "qa") && ("$1" != "prod") ]]; then
  echo 'ERROR: Must provide an argument for the environment: "dev", "qa", or "prod"'
  exit 1
fi

ENV=$1

# "urls": "https://www.breadoliveoilsalt.com/\nhttps://www.example.com/\n"
data_to_send_to_github() {
  cat << EOF
{
  "ref": "lighthouseTesting",
  "inputs": {
    "env": "$ENV",
    "urls": "https://www.breadoliveoilsalt.com"
  }
}
EOF
}


# data_to_send_to_github() {
#   cat << EOF
# {
#   "ref": "lighthouseTesting"
# }
# EOF
# }

LOG_FILE="curl_log.tmp"

# This works with workflow_dispatch
curl -iLSs \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $2" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/breadoliveoilsalt/githubActionsTests/actions/workflows/lighthouse-test-2.yml/dispatches" \
  -d "$(data_to_send_to_github)" \
  | tee "$LOG_FILE"

OK_STATUS_CODE_RESPONSE="204"

if grep -q "$OK_STATUS_CODE_RESPONSE" <(cat "$LOG_FILE" | head -1); then
  echo "Data uploaded to Github"
  rm "$LOG_FILE"
  exit 0
else
  echo "::error::perf-script.sh failed"
  rm "$LOG_FILE"
  exit 1
fi
