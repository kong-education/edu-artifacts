#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
# Check that PROXY_URL is set; exit if not.
: "${PROXY_URL:?Error: PROXY_URL environment variable is not set}"

# Define the endpoint paths and headers separately for clarity.
declare -a ENDPOINT_PATHS=(
  "authmock/status/200"
  "authmock/status/200"
  "authmock/status/200"
)
declare -a ENDPOINT_HEADERS=(
  "Authorization: Bearer INVALIDTOKEN"
  "Authorization: Basic aW52YWxpZHVzZXI6aW52YWxpZHB3"
  "" # Empty string for no headers
)
declare -a WEIGHTS=(33 33 34) # Percentages must sum to 100.
SLEEP_DURATION=1 # Seconds to sleep between requests.

# --- Functions ---
# Chooses an endpoint index based on a weighted distribution.
choose_endpoint() {
  local rand=$((RANDOM % 100))
  local sum=0
  for i in "${!ENDPOINT_PATHS[@]}"; do
    sum=$((sum + WEIGHTS[i]))
    if (( rand < sum )); then
      echo "$i"
      return
    fi
  done
}

# --- Main Loop ---
main() {
  local count=1
  while true; do
    local index=$(choose_endpoint)
    local path="${ENDPOINT_PATHS[index]}"
    local header_value="${ENDPOINT_HEADERS[index]}"
    local full_url="$PROXY_URL/$path"

    echo "[$count] Requesting: $full_url with header: $header_value"

    # Build the curl command arguments dynamically.
    local curl_args=(-s -o /dev/null -w "Status: %{http_code}\n")
    if [[ -n "$header_value" ]]; then
      curl_args+=(-H "$header_value")
    fi

    # The '|| true' handles non-zero exit codes from curl,
    # ensuring the script continues thanks to 'set -e'.
    set +e
    curl "${curl_args[@]}" "$full_url" || true
    set -e
    ((count++))
    sleep "$SLEEP_DURATION"
  done
}

main "$@"
