#!/bin/sh
# Build a deterministic, manifest-verified Forever addon QA ZIP.
# "release" is intentionally blocked without owner sign-off and licensing.
set -eu

cd "$(dirname "$0")/.."
mode=${1:-candidate}
case "$mode" in candidate|release) ;; *)
    echo 'Usage: sh scripts/package.sh [candidate|release]' >&2
    exit 2 ;;
esac

for tool in awk sed tr sort diff zip unzip mktemp cp mkdir; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Missing packaging tool: $tool" >&2
        exit 127
    fi
done
fail() { echo "PACKAGE BLOCKED: $*" >&2; exit 1; }

test -f GoldWise.toc || fail 'GoldWise.toc missing'
test -f README.md || fail 'README.md missing'
test -f CHANGELOG.md || fail 'CHANGELOG.md missing'
test -f PRIVACY.md || fail 'PRIVACY.md missing'

version=$(sed -n 's/^## Version: //p' GoldWise.toc)
bootstrap_version=$(sed -n 's/^addon.version = "\([^"]*\)"$/\1/p' adapters/Bootstrap.lua)
interface=$(sed -n 's/^## Interface: //p' GoldWise.toc)
title=$(sed -n 's/^## Title: //p' GoldWise.toc)
sv=$(sed -n 's/^## SavedVariables: //p' GoldWise.toc)
case "$version" in ''|*[!A-Za-z0-9._-]*) fail 'invalid TOC version' ;; esac
[ "$version" = "$bootstrap_version" ] || fail 'TOC / Bootstrap.lua version mismatch'
[ "$interface" = '16001' ] || fail 'unverified interface number'
[ "$title" = 'GoldWise' ] || fail 'unexpected addon title'
[ "$sv" = 'GoldWiseDB, GoldWiseGuideDB' ] || fail 'unexpected SavedVariables declaration'
test "$(grep -c '^## Version: ' GoldWise.toc)" -eq 1 || fail 'duplicate TOC version'

if [ "$mode" = release ]; then
    test -s LICENSE || fail 'LICENSE missing: owner must select and approve open-source license'
    test -s docs/release/OWNER_RELEASE_APPROVAL.md ||
        fail 'owner-signed client QA and release approval not recorded'
    case "$version" in *-test*|*-dev*|*candidate*) fail 'release version still a test candidate' ;; esac
    if grep -Eq 'TBD|PENDING|NOT RUN' docs/release/OWNER_RELEASE_APPROVAL.md; then
        fail 'owner release approval is incomplete'
    fi
    if grep -Eq 'TBD|PENDING|NOT RUN' LICENSE; then
        fail 'license is incomplete'
    fi
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work/GoldWise"

# Only explicitly listed Lua/XML addon paths are packaged. No optional scripts,
# probe addons, debug fixtures, account data, git metadata or external assets.
awk '/^[^#[:space:]]/ {print}' GoldWise.toc > "$work/entries"
[ -s "$work/entries" ] || fail 'empty TOC'
: > "$work/seen"
while IFS= read -r original; do
    path=$(printf '%s' "$original" | tr '\\' '/')
    case "$path" in
        adapters/*|data/*|domain/*|ui/*) ;;
        *) fail "unrecognized TOC path: $path" ;;
    esac
    case "$path" in
        *..*|/*|*' '*|*'//'*) fail "unsafe TOC path: $path" ;;
    esac
    case "$path" in *.lua|*.xml) ;; *) fail "invalid addon source: $path" ;; esac
    test -f "$path" || fail "missing TOC source file: $path"
    # Never copy arbitrary bytes through symlinks, including linked addon
    # directory roots. All packaged sources must be repository-owned files.
    test ! -L "$path" || fail "symlink TOC source forbidden: $path"
    test ! -L "${path%%/*}" || fail "symlink addon source directory forbidden: $path"
    if grep -Fqx "$path" "$work/seen"; then fail "duplicate TOC source: $path"; fi
    printf '%s\n' "$path" >> "$work/seen"
    mkdir -p "$work/GoldWise/$(dirname "$path")"
    cp "$path" "$work/GoldWise/$path"
done < "$work/entries"

# A release may include the approved license. A QA candidate instead
# includes an explicit NOTICE so it is not mistaken for a public release.
cp GoldWise.toc README.md CHANGELOG.md PRIVACY.md "$work/GoldWise/"
if [ "$mode" = release ]; then
    cp LICENSE "$work/GoldWise/"
else
    cat > "$work/GoldWise/QA_CANDIDATE_NOT_FOR_PUBLIC_RELEASE.txt" <<'NOTICE'
GoldWise QA test candidate only. Not a public or production release.
There is no approved redistribution license yet; install only for owner QA.
Forever game-client E2E and release approval are pending.
The developer does not claim Blizzard endorsement or compatibility on
untested builds. Do not share your SavedVariables or character data.
NOTICE
fi

mkdir -p dist
output="$(pwd)/dist/GoldWise-$version-$mode.zip"
(cd "$work" && find GoldWise -type f | LC_ALL=C sort > "$work/expected")
(cd "$work" && zip -q -X "$output" -@ < "$work/expected")
unzip -tq "$output" >/dev/null || fail 'ZIP failed integrity check'
unzip -Z -1 "$output" | LC_ALL=C sort > "$work/actual"
diff -u "$work/expected" "$work/actual" >/dev/null || fail 'ZIP contains unexpected or missing files'
printf 'PASS %s ZIP validated: %s (%s addon files)\n' "$mode" "$output" "$(wc -l < "$work/expected" | tr -d ' ')"
