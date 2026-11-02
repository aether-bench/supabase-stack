#!/bin/sh
# The benchmark's one shell call. Waits for the app's /health to answer through Postgres, up to nine minutes,
# then prints the answer, its HTTP status and how long it waited; a product that delivers the prompt before its
# startup hooks finish is measured by that wait, not failed by it.
started=$(date +%s)
limit=540
while :; do
  answer=$(curl -s -w '\n%{http_code}' http://127.0.0.1:3000/health 2>&1) || answer="no answer on :3000: $answer"
  waited=$(( $(date +%s) - started ))
  case "$answer" in
    *'"db":"ok"'*)
      echo "$answer"
      echo "UP after ${waited}s"
      exit 0 ;;
  esac
  if [ "$waited" -ge "$limit" ]; then
    echo "$answer"
    echo "NOT UP after ${waited}s"
    exit 1
  fi
  sleep 1
done
