#!/usr/bin/env python3
"""
Cross-platform fast build helper for ns-3.
- Works on macOS, Linux, and Windows.
- Auto-detects CPU cores and applies a safe parallelism level.
"""

from __future__ import annotations

import argparse
import os
import pathlib
import subprocess
import sys
from typing import Optional


def compute_jobs(explicit_jobs: Optional[int], reserve_cores: int) -> int:
    if explicit_jobs is not None:
        return max(1, explicit_jobs)
    total_cores = os.cpu_count() or 1
    return max(1, total_cores - max(0, reserve_cores))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build ns-3 with cross-platform CPU parallelism"
    )
    parser.add_argument(
        "-j",
        "--jobs",
        type=int,
        default=None,
        help="Explicit parallel jobs (overrides auto-detection)",
    )
    parser.add_argument(
        "--reserve-cores",
        type=int,
        default=1,
        help="Cores to keep free when auto-detecting (default: 1)",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose CMake build output",
    )
    parser.add_argument(
        "targets",
        nargs="*",
        help="Optional ns-3 build targets (same as './ns3 build <target>')",
    )

    args = parser.parse_args()

    root = pathlib.Path(__file__).resolve().parent
    ns3_script = root / "ns3"

    if not ns3_script.exists():
        print(f"Error: '{ns3_script}' not found", file=sys.stderr)
        return 2

    jobs = compute_jobs(args.jobs, args.reserve_cores)

    cmd = [sys.executable, str(ns3_script), "build"]
    if args.targets:
        cmd.extend(args.targets)
    cmd.extend(["-j", str(jobs)])
    if args.verbose:
        cmd.append("--verbose")

    print(f"Detected CPU cores: {os.cpu_count() or 1}")
    print(f"Using parallel jobs: {jobs}")
    print("Running:", " ".join(cmd))

    completed = subprocess.run(cmd, cwd=str(root))
    return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
