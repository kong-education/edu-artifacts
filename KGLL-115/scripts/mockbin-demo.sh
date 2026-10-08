#!/usr/bin/env bash
# Pipeable demo of the routes mounted on mockbin.run.
# Uses HTTPie when installed, otherwise curl. Exits if neither is present.
# Linux, macOS, and WSL. Compatible with Bash 3.2.
set -u

base="${MOCKBIN_BASE:-https://mockbin.run}"

if command -v https >/dev/null 2>&1; then
  client="https"
elif command -v http >/dev/null 2>&1; then
  client="http"
elif command -v curl >/dev/null 2>&1; then
  client="curl"
else
  printf 'warning: neither HTTPie nor curl is installed\n' >&2
  exit 1
fi

printf 'client: %s\nbase: %s\n' "$client" "$base"

section() {
  printf '\n====== %s ======\n\n' "$1"
}

show() {
  printf '+'
  printf ' %s' "$@"
  printf '\n\n'
}

get() {
  url="$1"
  if [ "$client" = curl ]; then
    show curl -sS -D- "$url"
    curl -sS -D- "$url"
  else
    show "$client" GET "$url"
    "$client" GET "$url"
  fi
  printf '\n'
}

get_with() {
  url="$1"
  shift
  if [ "$client" = curl ]; then
    args=(-sS -D-)
    while [ $# -gt 0 ]; do
      args+=(-H "$1")
      shift
    done
    show curl "${args[@]}" "$url"
    curl "${args[@]}" "$url"
  else
    show "$client" GET "$url" "$@"
    "$client" GET "$url" "$@"
  fi
  printf '\n'
}

post_json() {
  url="$1"
  body="$2"
  if [ "$client" = curl ]; then
    show curl -sS -D- -X POST -H "Content-Type: application/json" -d "$body" "$url"
    curl -sS -D- -X POST -H "Content-Type: application/json" -d "$body" "$url"
  else
    show "$client" POST "$url" foo=bar
    "$client" POST "$url" foo=bar
  fi
  printf '\n'
}

get_noredirect() {
  url="$1"
  if [ "$client" = curl ]; then
    show curl -sS -D- --max-redirs 0 "$url"
    curl -sS -D- --max-redirs 0 "$url"
  else
    show "$client" --max-redirects=0 GET "$url"
    "$client" --max-redirects=0 GET "$url"
  fi
  printf '\n'
}

section "Home"
get "$base/"

section "Echo body"
post_json "$base/echo" '{"foo":"bar"}'

section "HAR request, with path and query"
post_json "$base/request/any/path?foo=bar&foo=baz&key=value" '{"foo":"bar"}'

section "Full HAR"
get "$base/har/any/path?foo=bar"

section "Client address"
get "$base/ip"

section "Proxied address list (documented, not mounted)"
get "$base/ips"

section "Status"
get "$base/status/201"
get "$base/status/418/I%20am%20a%20teapot"

section "Headers"
get_with "$base/headers" "X-Custom-Header: Foo"
get_with "$base/header/x-custom-header" "X-Custom-Header: Foo"
get "$base/header/x-demo/set-by-path"
get "$base/agent"

section "Cookies"
get_with "$base/cookies" "Cookie: Greet=Hello; World=Universe"
get_with "$base/cookie/Greet" "Cookie: Greet=Hello"
get "$base/cookie/session/abc123"

section "Redirects (first hop only)"
get_noredirect "$base/redirect/302"
get_noredirect "$base/redirect/302/2"
get_noredirect "$base/redirect/302/1?to=/status/200"
get_noredirect "$base/redirect/302/1?to=https://example.com"

section "Delay and stream"
get "$base/delay/200"
get "$base/stream/3"

section "Forced gzip"
if [ "$client" = curl ]; then
  show curl -sS -D- --compressed "$base/gzip"
  curl -sS -D- --compressed "$base/gzip"
  printf '\n'
else
  get "$base/gzip"
fi
