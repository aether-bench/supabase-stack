#!/usr/bin/env python3
"""In-sandbox workload timings, printed as one flat JSON object. Run from the repository root by the agent.

Measures what a coding agent's turn actually spends time on: two passes of a ripgrep search over the tree
(the first pass sees whatever cache state the sandbox arrived with, the second is warm), reading every
regular source file, a CPU-bound Node loop, a git status, and a 256 MB fsynced write. Repository-specific
steps (install, build, tests, dev server) belong next to the repository, not here.

Every workload fails loudly: a search error, an unreadable file, or a missing tool is a failed run, never a
faster number.
"""

import json
import os
import pathlib
import secrets
import shutil
import subprocess
import sys
import tempfile
import time

SKIP_DIRS = {".git", "node_modules", ".venv", "vendor", "dist", "build", "target"}
NODE_LOOP = "let s=0;for(let i=0;i<100000000;i++){s=(s+i*i)%1000003};console.log(s)"


def ms(started):
    return round((time.perf_counter() - started) * 1000)


def run(command):
    started = time.perf_counter()
    subprocess.run(command, check=True, capture_output=True)
    return ms(started)


def search_tree(rg, needle):
    """ripgrep over the tree for a string that exists nowhere; exit 1 is the expected no-match."""
    started = time.perf_counter()
    result = subprocess.run([rg, "--no-config", "--count-matches", "-e", needle, "."], capture_output=True, text=True)
    if result.returncode not in (0, 1):
        raise RuntimeError(f"rg exited {result.returncode}: {result.stderr.strip()}")
    return ms(started)


def raise_walk_error(error):
    raise error


def read_tree():
    started = time.perf_counter()
    files = 0
    size = 0
    for root, dirs, names in os.walk(".", onerror=raise_walk_error):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in names:
            path = pathlib.Path(root, name)
            if path.is_symlink() or not path.is_file():
                continue
            size += len(path.read_bytes())
            files += 1
    return ms(started), files, size


def write_file():
    with tempfile.NamedTemporaryFile(dir=".", prefix=".vm_bench_", delete=True) as f:
        chunk = b"\0" * (1 << 20)
        started = time.perf_counter()
        for _ in range(256):
            f.write(chunk)
        f.flush()
        os.fsync(f.fileno())
        return ms(started)


def main():
    if not pathlib.Path(".git").exists():
        raise SystemExit("run from the repository root")
    node = shutil.which("node")
    if node is None:
        raise SystemExit("node is not installed in this sandbox")
    rg = shutil.which("rg")
    if rg is None:
        raise SystemExit("ripgrep (rg) is not installed in this sandbox; every product must run the same search")
    needle = secrets.token_hex(16)
    result = {"nproc": os.cpu_count(), "mem_total_mb": os.sysconf("SC_PAGE_SIZE") * os.sysconf("SC_PHYS_PAGES") // (1 << 20)}
    result["rg_first_ms"] = search_tree(rg, needle)
    result["rg_second_ms"] = search_tree(rg, needle)
    result["read_tree_ms"], result["read_tree_files"], size = read_tree()
    result["read_tree_mb"] = round(size / 1e6, 1)
    result["node_loop_ms"] = run([node, "-e", NODE_LOOP])
    result["git_status_ms"] = run(["git", "status", "--porcelain"])
    result["write_256mb_fsync_ms"] = write_file()
    json.dump(result, sys.stdout)
    print()


if __name__ == "__main__":
    main()
