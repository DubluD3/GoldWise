# Working with Codex: one story at a time

## Start each task
1. Read `AGENTS.md`, `BACKLOG.md`, target GW story, and impacted ADR/policy/API records.
2. Confirm dependencies and current status; classify uncertainty explicitly.
3. State scope, assumptions, files, tests and stop conditions. Never expand silently.
4. Create a `feature/GW-###-short-name` branch from latest main (after documentation PR merges).

## Discovery first
For API-related tasks:
- Find source symbols in the current client API docs; record exact signatures and build in `API_EVIDENCE.md`.
- User manually runs safe probes in client when required; capture sanitized proof.
- Mark `UNVERIFIED` until actual client behavior confirmed.
- If unknown, implement a mockable adapter interface and stop before runtime integration.

## Implement
- Pure domain logic before game integration; integer copper and explicit time/source.
- Keep diffs scoped to one story; avoid speculative extensions.
- Add normal, boundary, missing-data, corruption and regression cases.
- Add data migration when schema changes.
- No build script, CI or automated action should launch/control WoW.

## Review and handoff

Update the current progress table in `docs/planning/BACKLOG.md` when a story starts, gets blocked, gains verification evidence, enters review, or merges. Record the status, evidence link, next action, and update date in the same change or an immediate follow-up. Check the backlog before every story handoff, including documentation-only and verification work.

Provide in each PR:
- GW ID, dependency status, outcome, acceptance criteria evidence.
- API evidence ID/source/build and whether live verified.
- Commands actually executed with PASS/FAIL/NOT RUN.
- In-game test procedure + real result or `NOT RUN`.
- Policy checklist, privacy & license impact, performance, migration impact.
- Outstanding risks and rollback procedure.

## PR lifecycle
Codex may draft implementation and PR but does not self-approve live API behavior, policy ambiguity, or shipping. Owner must verify in-game acceptance and approve merge. One integration change at a time until test harness stable.

## Issue taxonomy
Capabilities and features are tracked by stable IDs in `BACKLOG.md`; GitHub issues represent stories. Use `GW-###` in titles and PRs. Suggested labels: `type:story`, `priority:p0/p1`, `phase:g0-g7`, `area:...`, `status:blocked`, `needs:in-game-validation`. Do not invent label existence; create via repo settings or leave unlabelled.
