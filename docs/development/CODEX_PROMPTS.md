# Codex prompts and reusable operating patterns

## First-run prompt
```text
Read AGENTS.md and all docs referenced by it. Do not write addon logic yet.
Audit API_EVIDENCE.md, BLIZZARD_POLICY.md, ARCHITECTURE.md and BACKLOG.md.
Report contradictions, unknowns and blockers with links. Propose G0 story order.
Do not invent APIs, game behavior, test results or launch dates.
```

## Story implementation prompt
```text
Implement only GW-### from docs/planning/BACKLOG.md and the matching GitHub issue.
Before coding: give acceptance criteria, dependencies, exact API evidence IDs,
risk classification, file changes and tests. Unknown APIs => mock interfaces,
no guessed runtime calls. Keep all gameplay behavior strictly read-only/advisory.
After coding, run available offline tests and report exact results; in-game
verification must be marked NOT RUN until performed by the owner.
Update relevant docs, source provenance and PR checklist.
```

## API audit prompt
```text
For GW-### identify every Blizzard API symbol. Cross-check official and
client-extracted documentation, recording exact signature, URL, version/build,
event flow, nil behavior and evidence class in API_EVIDENCE.md. Distinguish
documented from tested in our live Forever client. Produce a safe, manual
in-game probe plan without automated queries or protected actions.
```

## Adversarial review prompt
```text
Review this PR assuming game APIs and market assumptions may be wrong.
Look for guessed signatures, unsafe player actions, unbounded AH requests,
misleading sale odds, scope leakage, stale data claims, integer errors,
SavedVariables corruption, licensing/terms concerns and missing failure tests.
Provide severity, location and reproducible evidence; do not auto-merge.
```

## Release audit prompt
```text
Read release checklist, API_EVIDENCE, policy and all P0 stories.
Classify each as PROVEN / INFERRED / UNVERIFIED / BLOCKED and give actual test
commands/results. Reject release if any blocking rule lacks verified evidence.
```
