#!/bin/bash

# URLs and headers
URLS=(
  "$PROXY_URL/flights apikey:standardConsumerKey"
  "$PROXY_URL/flights apikey:premiumConsumerKey"
  "$PROXY_URL/routes"
  "$PROXY_URL/flights"
)

MAX_REQUESTS=20

# Loop over each URL and send random number of requests
for entry in "${URLS[@]}"; do
  # Split URL and header
  URL=$(echo "$entry" | awk '{print $1}')
  HEADER=$(echo "$entry" | awk '{print $2}')

  # Random number of requests between 1 and 100
  REQ_COUNT=$(shuf -i 1-$MAX_REQUESTS -n 1)

  echo "Sending $REQ_COUNT requests to $URL $HEADER"

(
  for ((i=1; i<=REQ_COUNT; i++)); do
    if [[ -n "$HEADER" ]]; then
      http GET "$URL" "$HEADER" > /dev/null 2>&1
    else
      http GET "$URL" > /dev/null 2>&1
    fi
  done
) & disown

done

# wait
