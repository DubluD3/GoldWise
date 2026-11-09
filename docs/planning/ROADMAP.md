# Roadmap (dependencies, not promises)
Baseline: 2026-11-09. Work is **not started** except documentation scaffolding.

| Gate | Objective | Target effort (indicative) | Required exit |
|---|---|---|---|
| G0 Research | live API + policy + data license validation | 1 week | evidenced symbols; forbidden actions list; go/no-go |
| G1 Foundation | local addon skeleton + character/inventory persistence | 1-2 weeks | client loads; reload & restart QA; pure domain tests |
| G2 Market | manual scan, timestamps, valuations | 1-2 weeks | correct scan event lifecycle; no uncontrolled polling |
| G3 Professions | recipes, skills, progression + reservations | 2-3 weeks | skill/rank/recipe gating validated; no double-count |
| G4 Advice | compare options and explain outcomes | 1-2 weeks | evidence-backed, reproducible recommendations or abstention |
| G5 Goals | gold ledger, goal planner, alt snapshots | 2 weeks | reconciliation + source confidence |
| G6 Stabilization | integration, accessibility, performance, docs | 1-2 weeks | zero blockers; QA and policy review |
| G7 Beta | opt-in user testing + publish | 1 week | release checklist approved |

**Critical path:** G0 → G1 → G2/G3 → G4 → G5 → G6 → G7. If AH data unavailable, ship inventory/profession-only beta rather than fabricate live value.

No phase is 'complete' until evidence and acceptance criteria exist. Re-estimate after G0. Use GitHub issues for execution; the canonical ID mapping remains in `BACKLOG.md`.
