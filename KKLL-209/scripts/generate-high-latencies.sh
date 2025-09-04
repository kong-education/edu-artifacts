#!/usr/bin/env bash
set -euo pipefail

# Check that PROXY_URL is set; exit if not.
: "${PROXY_URL:?Error: PROXY_URL environment variable is not set}"

# --- Configuration ---
# Latencies and weights
declare -a ENDPOINTS=(
  "latencymock/status/200"
  "latencymock/delay/1000"
  "latencymock/delay/5000"
  "latencymock/delay/30000"
)

declare -a WEIGHTS=(70 18 10 2) # percentages
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
   count=1
   while true; do
     endpoint=$(choose_endpoint)
     url="$PROXY_URL"
     [[ -n "$endpoint" ]] && url="$url/$endpoint"

     echo "[$count] Requesting: $url"
     curl -s -o /dev/null -w "Status: %{http_code}\n" "$url"
     ((count++))
  
     # Optional: Sleep to avoid spamming too fast
     sleep 1
   done
}

main "$@"