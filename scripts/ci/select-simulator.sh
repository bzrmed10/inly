#!/usr/bin/env bash
# Prints the UDID of an available iPhone simulator (prefers "Pro" models).
set -euo pipefail

xcrun simctl list devices available -j | python3 -c '
import json, sys
data = json.load(sys.stdin)["devices"]
phones = []
for runtime, devices in data.items():
    if "iOS" not in runtime:
        continue
    for d in devices:
        if d["name"].startswith("iPhone") and d.get("isAvailable", True):
            phones.append((runtime, d["name"], d["udid"]))
if not phones:
    sys.exit("no iPhone simulator available")
phones.sort(key=lambda p: (p[0], "Pro" in p[1] and "Max" not in p[1], p[1]))
print(phones[-1][2])
'
