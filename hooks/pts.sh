#!/bin/sh
# boat.dev's CPU benchmark, reproduced: Phoronix Test Suite 10.8.4 running pts/node-web-tooling-1.0.1 in batch mode
# with PTS's own run-count convergence, the way github.com/AnicetNgrt/hpc-sandbox-benchmarks (lib/bench.sh, cpu-node)
# does it. Prints the wall time and PTS's result lines; the metric is Runs Per Second.
set -eu
PTS_VERSION=10.8.4
RELEASES="https://github.com/phoronix-test-suite/phoronix-test-suite/releases/download/v${PTS_VERSION}"
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -qq >/dev/null
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq php-cli php-xml curl unzip procps >/dev/null
  curl -fsSL -o /tmp/pts.deb "${RELEASES}/phoronix-test-suite_${PTS_VERSION}_all.deb"
  sudo dpkg -i /tmp/pts.deb >/dev/null
else
  sudo dnf install -y -q php-cli php-xml unzip procps-ng tar >/dev/null
  curl -fsSL -o /tmp/pts.tar.gz "${RELEASES}/phoronix-test-suite-${PTS_VERSION}.tar.gz"
  tar -xzf /tmp/pts.tar.gz -C /tmp
  (cd /tmp/phoronix-test-suite && sudo ./install-sh >/dev/null)
fi
export TEST_EXECUTION_SORT=none TEST_RESULTS_DESCRIPTION=ci TEST_RESULTS_IDENTIFIER=ci TEST_RESULTS_NAME=node-web-tooling
unset MONITOR PERFORMANCE_PER_WATT FORCE_TIMES_TO_RUN || true
printf 'y\nn\nn\nn\nn\nn\ny\n' | phoronix-test-suite batch-setup >/dev/null 2>&1 || true
phoronix-test-suite batch-install pts/node-web-tooling-1.0.1 > /tmp/pts-install.log 2>&1
start=$(date +%s)
phoronix-test-suite batch-run pts/node-web-tooling-1.0.1 > /tmp/pts-run.log 2>&1
end=$(date +%s)
echo "PTS node-web-tooling wall $((end - start))s"
grep -E 'Average|Deviation|Runs Per Second|Test Run|Result' /tmp/pts-run.log | head -20
echo "--- host"
grep -m1 'model name' /proc/cpuinfo; nproc; free -g | sed -n 2p
