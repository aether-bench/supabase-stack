#!/bin/sh
# The benchmark's one shell call: succeeds only when the app answers and the app reached Postgres.
curl -sf http://127.0.0.1:3000/health
