#!/bin/sh
# Starts the Supabase stack and the app. Idempotent: re-running it on a machine where both are up is a no-op.
set -eu
cd "$(dirname "$0")/.."
npx supabase start
if ! curl -sf http://127.0.0.1:3000/health >/dev/null 2>&1; then
  nohup npm run dev > /tmp/supabase-stack-app.log 2>&1 &
fi
for _ in $(seq 1 60); do
  if curl -sf http://127.0.0.1:3000/health >/dev/null 2>&1; then exit 0; fi
  sleep 1
done
echo "the app never answered on :3000; see /tmp/supabase-stack-app.log" >&2
exit 1
