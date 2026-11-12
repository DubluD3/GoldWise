# Release gate
- [ ] Blizzard policy rechecked against official source on release date.
- [ ] Current client build/interface and exact addon TOC verified.
- [ ] Runtime API evidence in current build attached.
- [ ] No automatic trade, crafting, movement, simulated input or circumventing restrictions.
- [ ] Manual AH scan rate/cooldown behavior proven.
- [ ] No ads, in-addon donation solicitation, paywalls, opaque Lua.
- [ ] All bundled code/assets/data licenses reviewed.
- [ ] No required accounts/network/telemetry; privacy disclosures match actual behavior.
- [ ] Installation, reload, logout, restart and migration manual QA passed.
- [ ] Safe degraded behavior if prices/recipes/APIs unavailable.
- [ ] Domain and adapter offline tests passed.
- [ ] Accessible UI, low-data mode and performance measurements recorded.
- [ ] Documentation and changelog updated; owner signed off.

## Automated packaging gate (GW-025; 2026-11-12)
- [x] Script checks TOC/interface, internal version match, listed file existence, duplicate/unsafe source paths, symlinked files/directories (including nested paths), required docs and ZIP integrity/layout (candidate path). The CI packaging job runs isolated negative fixtures for these cases and verifies candidate-only notices and release denial.
- [x] Candidate ZIP is explicitly marked **NOT FOR PUBLIC RELEASE**.
- [ ] Owner selects and approves an open-source `LICENSE` compatible with third-party content and Blizzard policy. **No license is presently granted by a missing LICENSE file.**
- [ ] Owner provides actual build-specific Forever QA evidence and an independently signed `docs/release/OWNER_RELEASE_APPROVAL.md`. Never auto-generate approval.
- [ ] Replace test version; verify rights, security/privacy, release provenance, all E2E failures closed; then run `sh scripts/package.sh release` on approved commit.
- [ ] Confirm all parent PRs integrated safely and rerun CI on release commit. CI mocks do not stand in for a real client.
- [ ] Publish public releases only after complete human approval, not directly from CI candidate artifacts.

## Actual Forever acceptance record
Use [OWNER_E2E_QA.md](../development/OWNER_E2E_QA.md) (E01-E20). Owner test outputs remain **NOT RUN** as of 2026-11-12; release is **BLOCKED**. After QA, create the signed owner record *only* from actual evidenced results and explicit authorization.

## Packaging negative-regression evidence (2026-11-12)
The CI packaging job now runs `sh scripts/package_regression.sh` in a disposable copy of the project before uploading a candidate ZIP. It must **reject** deliberately invalid interface numbers, duplicate/unsafe manifest paths, missing source files, symlinked source files, symlinked top-level and nested directories, and public release packaging without the required owner license/approval. A passing candidate test **does not** authorize public distribution, certify a human license signature, or substitute for real in-game QA. After changes, only a successful run for the latest exact PR head is valid evidence.
