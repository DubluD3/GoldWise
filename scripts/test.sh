#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
lua_bin=${GOLDWISE_LUA:-lua5.1}
if ! command -v "$lua_bin" >/dev/null 2>&1; then
    printf '%s\n' 'Lua 5.1 is required. Install lua5.1 or set GOLDWISE_LUA to its path.' >&2
    exit 127
fi

"$lua_bin" -e 'assert(_VERSION == "Lua 5.1", "GoldWise tests require Lua 5.1")'
export LC_ALL=C
for suite in tests/*.lua; do
    printf '\n%s\n' "$suite"
    "$lua_bin" "$suite"
done
