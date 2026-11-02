#!/bin/sh
# boat.dev's CPU benchmark, reproduced: Phoronix Test Suite 10.8.4 running pts/node-web-tooling-1.0.1 in batch mode
# with PTS's own run-count convergence, the way github.com/AnicetNgrt/hpc-sandbox-benchmarks (lib/bench.sh, cpu-node)
# does it. Prints the wall time and PTS's result lines; the metric is Runs Per Second.
# A C/C++ toolchain is installed because pts/compress-7zip builds 7-Zip from source.
set -eu
# PTS_TEST picks the profile; the default is the single-box Node tooling suite, pts/compress-7zip is the all-core one.
TEST="${PTS_TEST:-pts/node-web-tooling-1.0.1}"
PTS_VERSION=10.8.4
RELEASES="https://github.com/phoronix-test-suite/phoronix-test-suite/releases/download/v${PTS_VERSION}"
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -qq >/dev/null
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq php-cli php-xml curl unzip procps build-essential >/dev/null
  curl -fsSL -o /tmp/pts.deb "${RELEASES}/phoronix-test-suite_${PTS_VERSION}_all.deb"
  sudo dpkg -i /tmp/pts.deb >/dev/null
else
  sudo dnf install -y -q php-cli php-xml unzip procps-ng tar make gcc gcc-c++ >/dev/null
  curl -fsSL -o /tmp/pts.tar.gz "${RELEASES}/phoronix-test-suite-${PTS_VERSION}.tar.gz"
  tar -xzf /tmp/pts.tar.gz -C /tmp
  (cd /tmp/phoronix-test-suite && sudo ./install-sh >/dev/null)
fi
export TEST_EXECUTION_SORT=none TEST_RESULTS_DESCRIPTION=ci TEST_RESULTS_IDENTIFIER=ci TEST_RESULTS_NAME=bench
unset MONITOR PERFORMANCE_PER_WATT FORCE_TIMES_TO_RUN || true
printf 'y\nn\nn\nn\nn\nn\ny\n' | phoronix-test-suite batch-setup >/dev/null 2>&1 || true
phoronix-test-suite batch-install "$TEST" > /tmp/pts-install.log 2>&1
start=$(date +%s)
phoronix-test-suite batch-run "$TEST" > /tmp/pts-run.log 2>&1
end=$(date +%s)
echo "PTS node-web-tooling wall $((end - start))s ($TEST)"
grep -E 'Average|Deviation|Runs Per Second|MIPS|Test Run|Result|Test:|Compression|Decompression' /tmp/pts-run.log | head -30
echo "--- host"
grep -m1 'model name' /proc/cpuinfo; nproc; free -g | sed -n 2p
lscpu | grep -E '^(Thread|Core|Socket)'
echo "steal jiffies $(awk '/^cpu /{print $9}' /proc/stat) of $(awk '/^cpu /{s=0; for (i=2;i<=NF;i++) s+=$i; print s}' /proc/stat)"
cat /sys/fs/cgroup/cpu.max 2>/dev/null; grep -E 'nr_throttled|throttled_usec' /sys/fs/cgroup/cpu.stat 2>/dev/null
