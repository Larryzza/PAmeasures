#!/usr/bin/env python3
"""Reject R session files in reachable history without reading file contents."""
import subprocess
import sys

blocked = (".rdata", ".rhistory")
objects = subprocess.check_output(
    ["git", "rev-list", "--objects", "--all"], text=True
).splitlines()
found = sorted({
    line.split(" ", 1)[1]
    for line in objects
    if " " in line
    and line.split(" ", 1)[1].rsplit("/", 1)[-1].lower().startswith(blocked)
})
if found:
    print("R session files remain in reachable Git history:")
    for path in found:
        print(" - " + path)
    print("Use a clean clone; do not merge pre-cleanup history.")
    sys.exit(1)
print("No R workspaces or R command histories in reachable Git history.")
