#!/usr/bin/env bash
set -euo pipefail

# Check that PROXY_URL is set; exit if not.
: "${PROXY_URL:?Error: PROXY_URL environment variable is not set}"

# --- Configuration ---
# Status codes and weights
declare -a ENDPOINTS=(
  "mock/status/200"
  "mock/status/404"
  "mock/status/503"
  "mock/status/400"
  "nonexistentpath"               # for https://PROXY_URL/
)
declare -a WEIGHTS=(70 10 10 8 2) # percentages must sum to 100.
SLEEP_DURATION=1 # Seconds to sleep between requests.

# --- Functions ---
# Chooses an endpoint index based on a weighted distribution.
choose_endpoint() {
  local rand=$((RANDOM % 100))
  local sum=0
  for i in "${!ENDPOINTS[@]}"; do
    sum=$((sum + WEIGHTS[i]))
    if (( rand < sum )); then
      echo "${ENDPOINTS[i]}"
      return
    fi
  done
}

# --- Main Loop ---
main() {
   local count=1
   while true; do
     endpoint=$(choose_endpoint)
     url="$PROXY_URL"
     [[ -n "$endpoint" ]] && url="$url/$endpoint"

     echo "[$count] Requesting: $url"
     set +e
     curl -s -o /dev/null -w "Status: %{http_code}\n" "$url"
     ((count++))
  
     # Optional: Sleep to avoid spamming too fast
     sleep "$SLEEP_DURATION"
   done
}

main "$@"
