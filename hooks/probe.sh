#!/bin/sh
# The benchmark's one shell call. Prints the app's /health and its HTTP status; succeeds only when the app
# answered and reached Postgres, and says what it saw otherwise so a failure explains itself.
if ! answer=$(curl -s -w '\n%{http_code}' http://127.0.0.1:3000/health 2>&1); then
  echo "no answer on :3000: $answer"
  exit 1
fi
echo "$answer"
case "$answer" in
  *'"db":"ok"'*) exit 0 ;;
  *) exit 1 ;;
esac
