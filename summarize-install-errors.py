"""Expose only package installation diagnostics in public check annotations."""
from pathlib import Path
import re

matches = []
pattern = re.compile(r"error[: ]|fatal error|undefined symbols|library not loaded|"
                     r"cannot find|not found|ERROR:|make.*Error|symbol not found|"
                     r"unable to load|Reason:", re.I)
for file in sorted(Path("dependency-install-logs").glob("*.out")):
    lines = file.read_text(errors="replace").splitlines()
    selected = set()
    for i, line in enumerate(lines):
        if pattern.search(line):
            selected.update(range(max(0, i - 1), min(len(lines), i + 3)))
    if selected:
        matches.append(f"--- {file.name} ---")
        matches.extend(lines[i] for i in sorted(selected))
namespaces = Path("dependency-namespace-errors.txt")
if namespaces.exists():
    matches.extend(namespaces.read_text(errors="replace").splitlines())
if not matches:
    log = Path("dependency-install-complete.log")
    if log.exists():
        matches = log.read_text(errors="replace").splitlines()[-60:]
if not matches:
    matches = ["The dependency command returned nonzero without a captured transcript."]
text = "\n".join(matches)[-18000:]
Path("dependency-error-summary.txt").write_text(text)
if text:
    encoded = text.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
    print("::error title=Dependency compiler and load diagnostics::" + encoded)
