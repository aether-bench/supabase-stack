#!/bin/sh
# Real work on the box, timed per phase: clone fastify at a pinned tag, npm ci with a cold cache, eslint (one core),
# then the unit suite (every core). Prints "WORK total Ns" last so a poller knows it finished.
set -eu
TAG="${WORK_TAG:-v5.12.7}"
now() { date +%s%N; }
secs() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.1f", (b - a) / 1e9 }'; }
rm -rf /tmp/work && mkdir -p /tmp/work && cd /tmp/work
git clone -q --depth 1 --branch "$TAG" https://github.com/fastify/fastify.git
cd fastify
echo "fastify $(git rev-parse --short HEAD) node $(node --version) npm $(npm --version)"
export npm_config_cache=/tmp/work/npmcache
t0=$(now)
npm ci --no-audit --no-fund > /tmp/work-install.log 2>&1
t1=$(now); echo "install $(secs "$t0" "$t1")s"
npm run lint > /tmp/work-lint.log 2>&1
t2=$(now); echo "lint $(secs "$t1" "$t2")s"
npm run unit > /tmp/work-unit.log 2>&1
t3=$(now); echo "unit $(secs "$t2" "$t3")s"
grep -E '^# (tests|pass|fail)' /tmp/work-unit.log | head -3 || true
echo "--- host"
grep -m1 'model name' /proc/cpuinfo; nproc; free -g | sed -n 2p
echo "steal jiffies $(awk '/^cpu /{print $9}' /proc/stat) of $(awk '/^cpu /{s=0; for (i=2;i<=NF;i++) s+=$i; print s}' /proc/stat)"
echo "WORK total $(secs "$t0" "$t3")s"
