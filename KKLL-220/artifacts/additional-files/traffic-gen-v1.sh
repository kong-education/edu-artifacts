#!/bin/bash

# Configuration
LOGFILE="api_test_$(date +%Y%m%d_%H%M%S).log"
MAX_CONCURRENT=10  # Limit concurrent requests to avoid overwhelming the server

# Initialize counters
declare -A request_counts=(
    ["flights_standard"]=0
    ["flights_premium"]=0
    ["flights_anonymous"]=0
    ["routes_anonymous"]=0
)

declare -A error_counts=(
    ["flights_standard"]=0
    ["flights_premium"]=0
    ["flights_anonymous"]=0
    ["routes_anonymous"]=0
)

# Logging function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# Function to make HTTP request with logging
make_request() {
    local endpoint="$1"
    local auth_header="$2"
    local request_type="$3"
    local request_num="$4"
    
    if [[ -n "$auth_header" ]]; then
        response=$(http GET "$PROXY_URL/$endpoint" "$auth_header" 2>&1)
    else
        response=$(http GET "$PROXY_URL/$endpoint" 2>&1)
    fi
    
    if [[ $? -eq 0 ]]; then
        ((request_counts[$request_type]++))
        log_message "SUCCESS: $request_type #$request_num - Total: ${request_counts[$request_type]}"
    else
        ((error_counts[$request_type]++))
        log_message "ERROR: $request_type #$request_num - $response - Total errors: ${error_counts[$request_type]}"
    fi
}

# Function to run requests for a specific type
run_requests() {
    local endpoint="$1"
    local auth_header="$2"
    local request_type="$3"
    local count=$(shuf -i 1-100 -n 1)
    
    log_message "Starting $count requests for $request_type"
    
    for ((i=1; i<=count; i++)); do
        # Use a semaphore-like approach to limit concurrency
        while [[ $(jobs -r | wc -l) -ge $MAX_CONCURRENT ]]; do
            sleep 0.1
        done
        
        make_request "$endpoint" "$auth_header" "$request_type" "$i" &
    done
    
    # Wait for all requests of this type to complete
    wait
    log_message "Completed all $count requests for $request_type"
}

# Main execution
log_message "Starting API load test with PID: $$"
log_message "Log file: $LOGFILE"
log_message "Max concurrent requests: $MAX_CONCURRENT"

# Check if PROXY_URL is set
if [[ -z "$PROXY_URL" ]]; then
    log_message "ERROR: PROXY_URL environment variable is not set"
    exit 1
fi

# Run all request types in parallel
run_requests "flights" "apikey: standardConsumerKey" "flights_standard" &
run_requests "flights" "apikey: premiumConsumerKey" "flights_premium" &
run_requests "flights" "" "flights_anonymous" &
run_requests "routes" "" "routes_anonymous" &

# Wait for all background processes to complete
wait

# Final summary
log_message "=== FINAL SUMMARY ==="
log_message "Request counts:"
for type in "${!request_counts[@]}"; do
    log_message "  $type: ${request_counts[$type]} successful, ${error_counts[$type]} errors"
done

total_requests=$((${request_counts[flights_standard]} + ${request_counts[flights_premium]} + ${request_counts[flights_anonymous]} + ${request_counts[routes_anonymous]}))
total_errors=$((${error_counts[flights_standard]} + ${error_counts[flights_premium]} + ${error_counts[flights_anonymous]} + ${error_counts[routes_anonymous]}))

log_message "Total requests: $total_requests"
log_message "Total errors: $total_errors"
log_message "Success rate: $(( total_requests * 100 / (total_requests + total_errors) ))%"
log_message "Test completed successfully"