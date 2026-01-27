#!/usr/bin/env python3
"""
verify_and_run.py

Modern, strict build verification script for CI.
Configures, builds, scans for warnings/errors, and runs the target executable.
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path
from typing import List, Tuple

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build, Verify, and Run")
    parser.add_argument("--source", type=Path, required=True, help="Path to source directory")
    parser.add_argument("--build", type=Path, required=True, help="Path to build directory")
    parser.add_argument("--exe", type=Path, required=True, help="Relative or absolute path to the executable")
    parser.add_argument("--config", default="Release", help="Build configuration (Release/Debug)")
    return parser.parse_args()

def run_command(cmd: List[str], cwd: Path, capture_patterns: bool = False) -> Tuple[int, str]:
    """
    Runs a command, streams output to stdout, and optionally captures output for inspection.
    Returns (return_code, full_output_log).
    """
    print(f"\n[CMD] {' '.join(str(c) for c in cmd)}")
    print(f"[CWD] {cwd}")
    
    # We merge stdout and stderr to capture everything in order
    process = subprocess.Popen(
        cmd,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding='utf-8',
        errors='replace'
    )

    full_log = []
    
    # Stream output line by line
    if process.stdout:
        pass  # Just for type checker, we know it's not None due to PIPE
        
    while True:
        line = process.stdout.readline()
        if not line and process.poll() is not None:
            break
        if line:
            # Print to CI console immediately
            sys.stdout.write(line)
            sys.stdout.flush()
            if capture_patterns:
                full_log.append(line)

    rc = process.poll()
    return (rc if rc is not None else -1), "".join(full_log)

def check_for_issues(log_content: str) -> bool:
    """
    Scans the log for 'warning' or 'error'. 
    Returns True if issues found.
    """
    # Regex for whole word warning/error, case insensitive
    # We exclude specific "CMake Warning" that might be harmless if you want, 
    # but the user requested "any cmake error or warning".
    pattern = re.compile(r"\b(warning|error)\b", re.IGNORECASE)
    
    found_issues = False
    for line in log_content.splitlines():
        if pattern.search(line):
            print(f"!! [FAILURE TRIGGER] Found issue: {line.strip()}")
            found_issues = True
            
    return found_issues

def main() -> int:
    args = parse_args()
    
    source_dir = args.source.resolve()
    build_dir = args.build.resolve()
    
    # ensure build directory exists
    build_dir.mkdir(parents=True, exist_ok=True)

    # 1. CONFIGURE
    # Note: Using --preset default as requested previously
    cmd_config = ["cmake", "--preset", "default", "-S", str(source_dir), "-B", str(build_dir)]
    rc, log_config = run_command(cmd_config, cwd=source_dir, capture_patterns=True)
    
    if rc != 0:
        print("\n[ERROR] CMake Configuration failed.")
        return rc
    
    if check_for_issues(log_config):
        print("\n[ERROR] Warnings or errors detected during Configuration.")
        return 1

    # 2. BUILD
    cmd_build = ["cmake", "--build", str(build_dir), "--config", args.config, "--parallel"]
    rc, log_build = run_command(cmd_build, cwd=build_dir, capture_patterns=True)

    if rc != 0:
        print("\n[ERROR] Build failed.")
        return rc

    if check_for_issues(log_build):
        print("\n[ERROR] Warnings or errors detected during Build.")
        return 1

    # Resolve executable path AFTER build
    exe_path = args.exe
    if not exe_path.is_absolute():
        # Heuristic search for executable
        candidates = [
            build_dir / exe_path,
            build_dir / args.config / exe_path,
            build_dir / args.config / exe_path.name
        ]
        
        detected_path = None
        for c in candidates:
            if c.exists() and c.is_file():
                detected_path = c
                break
                
        if not detected_path:
            # Recursive search if standard locations fail
            print(f"[INFO] Strict path check failed. Searching for '{exe_path.name}' in '{build_dir}'...")
            matches = list(build_dir.rglob(exe_path.name))
            if matches:
                matches.sort(key=lambda p: p.stat().st_mtime, reverse=True)
                detected_path = matches[0]
                print(f"[INFO] Found: {detected_path}")
        
        if detected_path:
            exe_path = detected_path

    # 3. RUN EXECUTABLE
    if not exe_path.exists():
        print(f"\n[ERROR] Executable not found at: {exe_path}")
        return 1

    print(f"\n[RUN] Executing: {exe_path}")
    # We don't necessarily fail on warnings inside the app runtime output, just return code.
    # But we can capture it if needed. For now, let's just stream it.
    rc, _ = run_command([str(exe_path)], cwd=build_dir, capture_patterns=False)

    if rc != 0:
        print(f"\n[ERROR] Executable returned non-zero exit code: {rc}")
        return rc

    print("\n--------------------------")
    print("... passing")
    print("--------------------------")
    return 0

if __name__ == "__main__":
    sys.exit(main())
