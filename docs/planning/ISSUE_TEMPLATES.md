# GitHub issue taxonomy and examples
Stable identifiers `CAP-##` → `F-##` → `GW-###` in `BACKLOG.md`. GitHub issue number is secondary.

## Standard story body
```markdown
Capability: CAP-## | Feature: F-## | Story: GW-###
Priority: P0/P1/P2 | Gate: G0..G7 | Status: PROPOSED
Dependencies: GW-### or none

### User story
As a <persona>, I want <outcome> so that <value>.

### Scope
...

### Acceptance criteria
- [ ] Verified behavior ... 
- [ ] Missing-data / failure behavior ...
- [ ] Safety/compliance criterion ...

### Evidence
API_EVIDENCE rows, policy source, data/license source. UNKNOWN until proven.

### Tests
Offline: ... | Manual game: ... | Status: NOT RUN

### Definition of done
Follow docs/planning/DEFINITION_OF_DONE.md; link PR and test outputs.
```

## Priority
P0 = MVP blocker, P1 = next release, P2 = enhancement. Block stories on missing live API evidence. Do not mark status READY from an AI-generated claim.
