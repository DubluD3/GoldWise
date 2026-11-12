#!/bin/sh
# Regression tests run only in disposable directories; never produce public release.
set -eu
cd "$(dirname "$0")/.."
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work/base"
cp -R GoldWise.toc README.md CHANGELOG.md PRIVACY.md adapters data domain ui scripts "$work/base/"
case_number=0
fresh_case() {
    case_number=$((case_number + 1))
    case_dir="$work/case-$case_number"
    cp -R "$work/base" "$case_dir"
}
reject_candidate() {
    if (cd "$case_dir" && sh scripts/package.sh candidate >/dev/null 2>&1); then
        echo "FAIL candidate packaging accepted invalid fixture $case_number" >&2
        exit 1
    fi
}
fresh_case
(cd "$case_dir" && sh scripts/package.sh candidate >/dev/null)
archive="$case_dir/dist/GoldWise-0.2.0-test2-candidate.zip"
test -s "$archive"
unzip -tq "$archive" >/dev/null
unzip -Z -1 "$archive" | grep -Fqx 'GoldWise/QA_CANDIDATE_NOT_FOR_PUBLIC_RELEASE.txt'
unzip -Z -1 "$archive" | grep -Fqx 'GoldWise/QA_INSTALL_AND_TEST.txt'
unzip -p "$archive" GoldWise/QA_INSTALL_AND_TEST.txt | grep -Fq 'PASS in automated CI does NOT mean PASS in the actual game client.'
unzip -p "$archive" GoldWise/QA_INSTALL_AND_TEST.txt | grep -Fq 'Only version 1.60.1 build 70862 or 70888'
unzip -p "$archive" GoldWise/QA_INSTALL_AND_TEST.txt | grep -Fq 'no public release'

if unzip -Z -1 "$archive" | grep -Eq '(^|/)(tests|scripts|WTF|\.git)/'; then
    echo 'FAIL QA candidate includes non-addon files' >&2
    exit 1
fi
if (cd "$case_dir" && sh scripts/package.sh release >/dev/null 2>&1); then
    echo 'FAIL public release passed without license and owner approval' >&2
    exit 1
fi
printf '%s\n' 'PASS candidate integrity/notice and denied release'
fresh_case
sed 's/## Interface: 16001/## Interface: 16002/' "$case_dir/GoldWise.toc" > "$case_dir/GoldWise.toc.tmp"
mv "$case_dir/GoldWise.toc.tmp" "$case_dir/GoldWise.toc"
reject_candidate
fresh_case
printf '%s\n' 'adapters\Bootstrap.lua' >> "$case_dir/GoldWise.toc"
reject_candidate
fresh_case
rm "$case_dir/domain/Goals.lua"
reject_candidate
fresh_case
printf '%s\n' 'adapters\..\README.lua' >> "$case_dir/GoldWise.toc"
reject_candidate
fresh_case
rm "$case_dir/adapters/Bootstrap.lua"
ln -s "$work/base/adapters/Bootstrap.lua" "$case_dir/adapters/Bootstrap.lua"
reject_candidate
fresh_case
mv "$case_dir/data" "$case_dir/original-data"
ln -s original-data "$case_dir/data"
reject_candidate
fresh_case
mkdir -p "$case_dir/data/nested-real"
cp "$case_dir/data/Ledger.lua" "$case_dir/data/nested-real/Check.lua"
ln -s nested-real "$case_dir/data/nested-link"
printf '%s\n' 'data\nested-link\Check.lua' >> "$case_dir/GoldWise.toc"
reject_candidate
printf '%s\n' 'PASS invalid interface, duplicate/unsafe/missing manifest sources and nested symlinks all blocked'
