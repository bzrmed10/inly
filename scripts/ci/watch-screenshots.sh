#!/usr/bin/env bash
# Builds the watch app for the simulator and saves App Store screenshots of it (demo data) in 4 languages.
set -uo pipefail
OUT="${1:-build/screenshots}"
mkdir -p "$OUT"

UDID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
data = json.load(sys.stdin)["devices"]
best = []
for runtime, devices in data.items():
    if "watchOS" not in runtime:
        continue
    for d in devices:
        n = d["name"]
        if n.startswith("Apple Watch"):
            score = (runtime, "Ultra" in n, "46mm" in n or "49mm" in n, n)
            best.append((score, d["udid"]))
best.sort()
print(best[-1][1] if best else "")
')
if [ -z "$UDID" ]; then echo "::warning::No watch simulator"; exit 0; fi
echo "Watch simulator: $UDID"

xcodebuild build -project Inly.xcodeproj -target InlyWatch -configuration Debug \
  -sdk watchsimulator -derivedDataPath build/watchDD SYMROOT="$PWD/build/watchSym" \
  CODE_SIGNING_ALLOWED=NO -quiet || { echo "::warning::Watch build failed"; exit 0; }
APP=$(find build/watchSym -name "InlyWatch.app" -path "*watchsimulator*" | head -1)
[ -z "$APP" ] && APP=$(find build -name "InlyWatch.app" -path "*watchsimulator*" | head -1)
if [ -z "$APP" ]; then echo "::warning::Watch app not found"; exit 0; fi

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || sleep 20
xcrun simctl status_bar "$UDID" override --time 9:41 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"
BID=com.bzrmed.inly.watchkitapp

for lang in en fr es ar; do
  for state in in out; do
    args=(-demoData -appLanguage "$lang")
    [ "$state" = out ] && args+=(-demoOut)
    xcrun simctl terminate "$UDID" "$BID" 2>/dev/null || true
    xcrun simctl launch "$UDID" "$BID" "${args[@]}" >/dev/null
    sleep 5
    xcrun simctl io "$UDID" screenshot "$OUT/watch-$lang-$state.png" >/dev/null 2>&1 || true
  done
done
ls -la "$OUT" | grep watch || true
