# Codex / AI agent operating contract

**Read before ANY change.** Applies repository-wide, including subagents. Hierarchy: user task → this file → story acceptance criteria → architecture/ADRs → verified API evidence. If conflict, stop and report it; do not quietly bypass this contract.

## Context and scope
- Project: GoldWise, free, open-source, privacy-preserving WoW Forever economic/professions advisor.
- Status: planning only. NEVER say code is implemented or API behavior verified until tested.
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

## Required story sequence
1. Read `docs/development/WORKFLOW.md` and referenced `GW-###` entry.
2. Record evidence/unknowns; propose smallest change and rollback.
3. Implement only accepted scope; add failure-path and normal-path tests.
4. Run checks from `docs/development/TEST_STRATEGY.md`; disclose missing tooling.
5. Update appropriate docs, changelog, and evidence register; make acceptance mapping explicit.
6. In PR response provide: scope, facts/evidence, files, tests + output, blocked items, policy impact, data/migration impact, risks and follow-up stories.

## Stop-the-line triggers
Any ambiguous policy concern; unverified protected action; API signature guessed; destructive migration; license ambiguity; unexpected data upload; automation; unreliable market inference shown as certainty. STOP, mark blocked and ask for owner review. Do not 'work around' protection.

## Definition of done
All acceptance criteria demonstrated; no unsupported API assertions; offline tests pass (or explicitly blocked); in-game tests recorded when required; performance and persistence reviewed; policy/privacy/ADR/docs updated; owner approval where required. **A passing mock test never proves live game compatibility.**
