#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
mode=${1:-all}
case "$mode" in
    syntax)
        lua_compiler=${GOLDWISE_LUAC:-luac5.1}
        if ! command -v "$lua_compiler" >/dev/null 2>&1; then
            printf '%s\n' 'Lua 5.1 compiler is required. Install lua5.1 or set GOLDWISE_LUAC to its path.' >&2
            exit 127
        fi
        case "$("$lua_compiler" -v 2>&1)" in
            'Lua 5.1.'*|'Lua 5.1 '*) ;;
            *)
                printf '%s\n' 'GoldWise syntax checks require a Lua 5.1 compiler.' >&2
                exit 1
                ;;
        esac
        sh -n scripts/test.sh
        find adapters data domain tests -type f -name '*.lua' -exec "$lua_compiler" -p {} +
        printf '%s\n' 'PASS Lua 5.1 and shell syntax'
        exit 0
        ;;
    all|unit|contract) ;;
    *)
        printf '%s\n' 'Usage: sh scripts/test.sh [all|syntax|unit|contract]' >&2
        exit 2
        ;;
esac

lua_bin=${GOLDWISE_LUA:-lua5.1}
if ! command -v "$lua_bin" >/dev/null 2>&1; then
    printf '%s\n' 'Lua 5.1 is required. Install lua5.1 or set GOLDWISE_LUA to its path.' >&2
    exit 127
fi

"$lua_bin" -e 'assert(_VERSION == "Lua 5.1", "GoldWise tests require Lua 5.1")'
export LC_ALL=C
ran_suite=false
for suite in tests/*.lua; do
    case "${suite#tests/}" in
        auction_observation.lua|character_snapshot.lua|inventory_snapshot.lua|item_choices.lua|material_review.lua|equipment_advisor.lua|goals.lua|goal_commands.lua|profession_goal_review.lua|craft_capacity.lua|ledger.lua|market_history.lua|material_reservations.lua|reservation_integrity.lua|scan_guide.lua|\
        profession_snapshot.lua|profession_companion_summary.lua|inventory_companion_summary.lua|recipe_catalog.lua|recipe_materials.lua|storage.lua)
            group=unit
            ;;
        *_probe.lua|bootstrap.lua|character_capture.lua|ledger_capture.lua|saved_variables.lua)
            group=contract
            ;;
        *)
            printf 'Unclassified test suite: %s\n' "$suite" >&2
            exit 1
            ;;
    esac
    if [ "$mode" != all ] && [ "$mode" != "$group" ]; then
        continue
    fi
    printf '\n%s\n' "$suite"
    "$lua_bin" "$suite"
    ran_suite=true
done
if [ "$ran_suite" = false ]; then
    printf 'No test suites for mode: %s\n' "$mode" >&2
    exit 1
fi
