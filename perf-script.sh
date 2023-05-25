#!/bin/bash

# set -Eeou pipefail

ENV=$1
TOKEN=$2
URLS=""

if [[ ("$ENV" != "dev") && ("$ENV" != "qa") && ("$ENV" != "prod") ]]; then
  echo 'ERROR: Must provide an argument for the environment: "dev", "qa", or "prod"'
  exit 1
fi

function generate_urls {
  while read -r line; do URLS+="$line"'\n'; done < pathnames.txt
}

generate_urls
echo "URLS"
echo "$URLS"

# "urls": "https://www.breadoliveoilsalt.com/\nhttps://www.example.com/\n"
function data_to_send_to_github {
  cat << EOF
{
  "ref": "lighthouseTesting",
  "inputs": {
    "env": "$ENV",
    "urls": "$URLS"
  }
}
EOF
}

echo "data: $(data_to_send_to_github)"

LOG_FILE="curl_log.tmp"

# This works with workflow_dispatch
curl -iLSs \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
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
