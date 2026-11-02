#!/bin/sh
# Real work on the box, timed per phase and run twice: clone fastify at a pinned tag, npm install with a cold cache
# (fastify ships no lockfile, so npm ci cannot run), eslint (one core), then the unit suite (every core). Pass 1 runs
# right after the sandbox was handed over, pass 2 on the same box minutes later, so a box still hydrating after a
# take is told apart from its steady state. Prints "WORK total Ns" last so a poller knows it finished.
set -eu
TAG="${WORK_TAG:-v5.12.7}"
now() { date +%s%N; }
secs() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.1f", (b - a) / 1e9 }'; }
steal() { awk '/^cpu /{s=0; for (i=2;i<=NF;i++) s+=$i; print $9 " of " s}' /proc/stat; }
echo "--- host"
grep -m1 'model name' /proc/cpuinfo; nproc; free -g | sed -n 2p
echo "node $(node --version) npm $(npm --version)"
T0=$(now)
for pass in 1 2; do
  rm -rf /tmp/work && mkdir -p /tmp/work && cd /tmp/work
  git -c advice.detachedHead=false clone -q --depth 1 --branch "$TAG" https://github.com/fastify/fastify.git
  cd fastify
  export npm_config_cache=/tmp/work/npmcache
  echo "pass $pass fastify $(git rev-parse --short HEAD) steal $(steal)"
  t0=$(now)
  npm install --no-audit --no-fund > /tmp/work-install.log 2>&1
  t1=$(now); echo "pass $pass install $(secs "$t0" "$t1")s"
  npm run lint > /tmp/work-lint.log 2>&1
  t2=$(now); echo "pass $pass lint $(secs "$t1" "$t2")s"
  # the dev stack holds :3000, so two listen tests fail on every product; the suite's time still counts
  npm run unit > /tmp/work-unit.log 2>&1 || true
  t3=$(now); echo "pass $pass unit $(secs "$t2" "$t3")s $(grep -oE '(tests|pass|fail) [0-9]+' /tmp/work-unit.log | tail -3 | tr '\n' ' ')"
  echo "pass $pass steal $(steal)"
done
echo "WORK total $(secs "$T0" "$(now)")s"
