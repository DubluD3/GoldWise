# Codex / AI agent operating contract

**Read before ANY change.** Applies repository-wide, including subagents. Hierarchy: user task → this file → story acceptance criteria → architecture/ADRs → verified API evidence. If conflict, stop and report it; do not quietly bypass this contract.

## Context and scope
- Project: GoldWise, free, open-source, privacy-preserving WoW Forever economic/professions advisor.
- Current story status lives in `docs/planning/BACKLOG.md` and reflects the current branch, merged implementation, and test evidence. NEVER claim code is implemented or API behavior verified without inspecting current code and actual tests.
- Primary docs: `docs/product/PRODUCT.md`, `docs/planning/BACKLOG.md`, `docs/research/API_EVIDENCE.md`, `docs/compliance/BLIZZARD_POLICY.md`, `docs/architecture/ARCHITECTURE.md`.
- Read the complete story before touching files. One focused story/PR. Do not implement future phases speculatively.

## Anti-hallucination protocol (REQUIRED)
1. Classify every relevant assertion: `OFFICIAL`, `CLIENT-EXTRACTED`, `COMMUNITY-REPORTED`, `OBSERVED-IN-GAME`, `INFERRED`, or `UNKNOWN`. Client-extracted does NOT mean verified in the live client.
2. Before using any WoW API, add/update `docs/research/API_EVIDENCE.md`: exact symbol, parameters/returns, build, URL/file and date, observation/test proof, fallback and status. Never invent namespace, signature, events, item IDs, skill thresholds, NPCs, recipes, prices, fees, AH limits, or EULA permissions.
3. If evidence is unavailable, create a typed adapter interface and mock data; mark implementation `BLOCKED-API-VERIFICATION`. DO NOT invent a runtime call.
4. Prefer official Blizzard docs/policy and in-client API documentation. Community extract is a hypothesis. Cite URLs and retrieval dates. Revalidate on each client patch.
5. Never claim a scan's asking prices prove demand or sale probability. Unknown is a valid recommendation output.
6. No invented tests: only report commands executed and their actual outputs. If cannot run, say `NOT RUN`.
7. Never use generated code to evade client protection or restrictions.

## Safety hard prohibitions
- No automated buying, selling, posting, cancelling, bidding, crafting, gathering, movement, macro loops, click/key simulation or AFK gameplay.
- No process memory access, packet interception, injection, protected-function bypass, anti-cheat circumvention, stealth or abusive query loops.
- No cloud upload, tracking, account linking, companion-agent control or unapproved external dependencies.
- No ads, premium addon features, soliciting donations in the addon, obfuscated Lua or proprietary asset/code copying.
- Do not ship unclear compliance behaviors: document them and seek human review.

## Implementation discipline
- Domain engines must be pure Lua (no WoW globals), deterministic and offline-testable.
- Blizzard calls only in adapter layer; mock them in tests. Treat nil/stale/partial results as first-class.
- Use integer copper for money, stable item identifiers with realm/faction scope, explicit timestamps and source provenance.
- Preserve saved-data backward compatibility via schema version + migrations; no silent deletion.
- Bound scan retries/collection size, SavedVariables retention and per-frame work.
- Do not execute economic transactions in V1; UI explains choices and lets player decide.
- Respect data licenses; vendor libraries only after explicit approval and review.

## UI/UX design rules (REQUIRED for UI stories)
- Read [docs/design/DESIGN_SYSTEM.md](docs/design/DESIGN_SYSTEM.md) before creating or changing any screen, component, tooltip, theme or navigation behavior.
- Direction: a **Warcraft-native, game-integrated interface**: familiar framed panels, muted stone/leather/parchment surfaces, restrained bronze/gold trim, WoW item quality cues and readable Blizzard-style controls. Target **70% modern WoW usability / 30% classic fantasy**; avoid a banking SaaS dashboard, copied Blizzard assets, excessive ornament or spreadsheet-first layout.
- Use the documented token palette, spacing, type hierarchy and repeatable components as design targets, adapting to **verified WoW UI capabilities**. Do not assume CSS/web rendering, fonts, animation, frame templates, or resize APIs exist.
- Prefer **Overview / Inventory / Professions / Market / My Plan** navigation. Give each recommendation a short action, transparent “Why?”, alternatives, data source/time and uncertainty.
- Keep item rarity colors recognizable; supplement every color-coded status with words or icons. Do not represent asking prices as guaranteed sale proceeds.
- Include empty, loading, stale, partial, unsupported and error states; never fill gaps with fictional live data.
- Every interactive UI element must have a real, supported action, not a dead button. No automatic trade/craft controls or misleading labels.
- Verify screen fit at relevant UI scales and resolutions, focus/readability/contrast, performance, and no taint/protected UI behavior. Record manual client QA honestly.
- Prefer scope-limited UI changes; do not redesign existing working screens opportunistically unless the assigned story explicitly calls for it.
- If a UI design conflicts with game restrictions or evidence, documented client behavior and safety requirements win.

## Blizzard UI/security/privacy rules for design
- Read [docs/design/BLIZZARD_UI_COMPLIANCE.md](docs/design/BLIZZARD_UI_COMPLIANCE.md) before editing any WoW frame, overlay, tooltip, secure interaction, data capture, or visual asset.
- Distinguish Blizzard's **official addon policy** from community secure-frame/taint documentation and GoldWise's own accessibility/privacy standards. Never present our preferences as Blizzard mandates.
- Use standalone non-protected informational UI by default; no protected-frame/secure-action manipulation, secret-value inspection, combat-lockdown workarounds, or taint-inducing global modifications.
- No disruptive popups, repeated animations, expensive per-frame work or hidden background AH queries. Capture performance and combat UI behavior in manual test evidence.
- Never collect credentials or unrelated private data; no implicit upload, analytics or telemetry. No paid features, ads, donation prompts or unlicensed art.
- Competitor screenshots are **references only**, not permission to copy code, visuals, icons, or datasets. Recheck addons and source licenses before integrating.
- Include addon-interoperability and client-version checks in UI QA; do not claim compatibility until manually verified.

## Required story sequence
1. Read `docs/development/WORKFLOW.md` and referenced `GW-###` entry.
2. Record evidence/unknowns; propose smallest change and rollback.
3. Implement only accepted scope; add failure-path and normal-path tests.
4. Run checks from `docs/development/TEST_STRATEGY.md`; disclose missing tooling.
5. Update the backlog before every story handoff using `docs/development/WORKFLOW.md`. Update the relevant docs, changelog, and evidence register, and map the acceptance criteria to their proof.
6. In PR response provide: scope, facts/evidence, files, tests + output, blocked items, policy impact, data/migration impact, risks and follow-up stories.

## Stop-the-line triggers
Any ambiguous policy concern; unverified protected action; API signature guessed; destructive migration; license ambiguity; unexpected data upload; automation; unreliable market inference shown as certainty. STOP, mark blocked and ask for owner review. Do not 'work around' protection.

## Definition of done
All acceptance criteria demonstrated; no unsupported API assertions; offline tests pass (or explicitly blocked); in-game tests recorded when required; performance and persistence reviewed; policy/privacy/ADR/docs updated; owner approval where required. **A passing mock test never proves live game compatibility.**
