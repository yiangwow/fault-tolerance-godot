# Review Request: M8 recovered watch roster
- **Author**: Codex
- **Repository**: https://github.com/yiangwow/fault-tolerance-godot
- **Branch**: feature/m8-recovered-watch-roster
- **Base**: main @ 3c8775687b7251f6f65fea961fc0a70bf3150125
- **Implementation head**: dd79bd27809631688dc56447a94ddc8d122e7747
- **PR**: private archive PR #4 / OPEN / non-draft / MERGEABLE / CLEAN
- **Risk level**: 1
- **Scope**: Add one deterministic three-day WO-014 recovery-watch loop after non-rupture WO-013 conclusions; do not change prior repair outcomes, the sealed packet's historical behavior, persistence, resources, plugins, project settings, map rendering, networking, or deployment.
- **Source of truth**: The owner's original game direction: "your purpose is to endure and keep repairing the ship over time" while crew and operator sanity fall, with the possibility that the player's actions worsen the crew; latest instruction: "continue" after the explicit M7 merge/tag and M8-start gate.
- **Risk rationale**: Internal gameplay state and generated Control UI change with no API, schema, persistence, security, performance-sensitive, deployment, or external-consumer impact.

## Acceptance criteria

1. Only WO-013 remote-vent and manual-handoff conclusions may enter WO-014; service-spine rupture remains terminal.
2. Every M1 route and WO-012 disposition can reach the same deterministic watch from a non-rupture WO-013 conclusion without changing its earlier values or outcome copy.
3. WO-014 begins at day zero, snapshots endurance/integrity/coherence, exposes exactly two phase-local actions, and discloses every numeric effect before selection.
4. Manual watch advances exactly one day, spends one bounded endurance day, adds two bounded integrity, adds one bounded coherence, and preserves carrier condition.
5. Accepting the recovered roster advances exactly one day, adds one endurance day and three bounded integrity, costs six bounded coherence, and irreversibly increments roster use.
6. Exactly three actions complete the watch. Direct calls, mouse signals, or keys after completion cannot mutate any campaign state.
7. `H` maps to manual watch and `E` maps to recovered roster only during WO-014; direct, mouse, and keyboard paths produce the same effects.
8. A surviving carrier is `RESPONDING` before roster use, `ECHOING` after one roster use, and `COMPLIANT` after two or more. Later manual watches cannot restore it.
9. A route with neither a surviving Mina nor a retained WO-013 responder remains `NO CERTIFIED CARRIER`; accepting the roster still applies disclosed station effects but never revives a person.
10. The optional sealed packet remains one-time, phase-neutral, and resource-neutral before WO-014. Entering WO-014 hides it without rewriting its historical contents.
11. Normal and low coherence may change roster-attribution text, but never action visibility, availability, or effects. The recovered roster identifies the AUX-4 operator key and predates the first recorded fault without resolving authorship.
12. The active watch and final ledger fit the 1280x720 target with costs, three-day action history, carrier state, resource deltas, credential, and discrepancy legible without clipping.
13. Non-goals: no persistence/save system, randomness, general campaign framework, new resource or meter, map mutation, scene split, asset/plugin import, audio/gamepad work, or explanation of whether the roster is AI, hallucination, forgery, or the operator's prior work.

## What changed

- `src/main.gd`: adds WO-014 phase/state cleanup, recovered-roster UI, three-day resolution logic, bounded effects, derived carrier state, attribution/ledger copy, phase-local input, crew feedback, and completed summary.
- `tests/verify.gd`: adds six M1/WO-012 entry checks plus rupture gating, archive/snapshot/reset invariants, exact effects and bounds, carrier deterioration/no-revival, low-coherence copy, input parity, all-manual completion, and post-completion immutability.
- `tests/capture.gd`: adds deterministic day-two roster and completed-ledger frames.
- `README.md`: documents the playable loop and phase-scoped controls.
- `CLAUDE.md`: records WO-014 architecture and invariants.

## How to verify

Run from a clean detached worktree at implementation head `dd79bd27809631688dc56447a94ddc8d122e7747`:

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/verify.gd
godot --path . --resolution 1280x720 --script res://tests/capture.gd
git diff --check 3c8775687b7251f6f65fea961fc0a70bf3150125..dd79bd27809631688dc56447a94ddc8d122e7747
git diff --name-only 3c8775687b7251f6f65fea961fc0a70bf3150125..dd79bd27809631688dc56447a94ddc8d122e7747
```

Expected: import exits 0; `VERIFY PASS: 168 deterministic gameplay checks`; capture exits 0 and writes all prior frames plus `09-watch-roster-day-2.png` and `10-watch-summary-ledger.png`; diff check is empty; changed files are exactly the five listed above. Visually inspect both new PNGs at 1280x720.

## Author verification evidence

1. Tests: `godot --headless --path . --script res://tests/verify.gd` exited 0 with `VERIFY PASS: 168 deterministic gameplay checks`.
2. Build/import and render: `godot --headless --path . --editor --quit` exited 0 without parser/resource errors. The real-render capture command exited 0 with `CAPTURE PASS`; both new files are 1280x720 RGBA PNGs and were visually inspected without clipping. A visual pass found and fixed stale day-count decision-support copy before this request.
3. Clean state: after commit, `git status --short --branch` reported only `## feature/m8-recovered-watch-roster`.
4. End-to-end self-review: read the complete implementation/test/docs diff, verified action arithmetic, phase guards, archive isolation, survivor derivation, reset paths, input routing, and both rendered states.
5. Scope: `git diff --name-only main..HEAD` reports exactly `CLAUDE.md`, `README.md`, `src/main.gd`, `tests/capture.gd`, and `tests/verify.gd`; `project.godot` and `src/station_map.gd` are untouched. `git diff --check main..HEAD` exits 0 with no output.
6. Authorship: implementation commit `dd79bd27809631688dc56447a94ddc8d122e7747` is the owner's git identity and contains no `Co-Authored-By` trailer.
7. Project reference: `CLAUDE.md` and `README.md` are updated in the implementation commit. No ADR is required because this extends the existing single-scene deterministic campaign architecture without a new architectural decision.
8. Cycle allocation: immediate `.peer-review/` child directories had numeric prefixes `001` through `007`; `008-m8-recovered-watch-roster` was created only after that scan and did not collide.
9. Delivery: implementation head is pushed to both `github` and the local `origin` mirror. PR #4 was refreshed as OPEN, non-draft, MERGEABLE, and CLEAN at exact head `dd79bd27809631688dc56447a94ddc8d122e7747`; GitHub reports no configured CI checks (`statusCheckRollup: null`).

## Known limitations / open questions

- Rendering was verified on Linux/WSL2 with Godot 4.4.1 GL Compatibility and Mesa/D3D12 at the 1280x720 target, not other platforms, renderers, window sizes, or display scales.
- Input verification uses direct method calls, synthesized top-row key events, and button signals; it does not cover physical keyboard focus behavior, key repeat, IME, gamepad, or accessibility tooling.
- There is no CI configured on the private repository, so local author/reviewer verification is the delivery gate.
- The roster is intentionally an offline recovered record rather than active CONTINUITY. Its origin and the operator's authorship remain unresolved.
