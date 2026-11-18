# Review Request: M9 maintenance rotation
- **Author**: Codex
- **Repository**: https://github.com/yiangwow/fault-tolerance-godot
- **Branch**: feature/m9-maintenance-rotation
- **Base**: main @ c8f78e44950ef7ab9e4a829c1bcda3f30d23a6f8
- **Implementation head**: aa05924ea58c90ce3d7b4156c70e4b88701212e7
- **PR**: private archive PR #5 / OPEN / non-draft / MERGEABLE / CLEAN
- **Risk level**: 1
- **Scope**: Add one deterministic three-pulse WO-015 maintenance rotation after the completed WO-014 watch; do not change prior repair/watch effects, persistence, project settings, plugins, networking, deployment, or public interfaces.
- **Source of truth**: The owner's game direction: the engineer must endure and keep repairing the ship while the crew and operator deteriorate, with the possibility that the player's own accepted orders worsen the situation; latest instruction: "continue" after the explicit M8 merge/tag and M9-start gate.
- **Risk rationale**: Internal deterministic gameplay state, generated Control UI, and custom map rendering change with no API, schema, persistence, security, performance-sensitive, deployment, or external-consumer impact.

## Acceptance criteria

1. Only a completed `WATCH_SUMMARY` may enter WO-015 through `N`/the next-order button; an incomplete watch or direct call from another phase is inert.
2. WO-015 preserves `watch_actions`, `watch_roster_uses`, and `_watch_survivor_state()` as immutable history and never revives a dead/lost crew member.
3. LOOP-C, nutrient reserve, and carrier link begin at condition `3/3/3`; entry immediately applies pulse one wear `2/1/1`, followed by pulses `1/2/1` and `1/1/2`.
4. Each pulse permits exactly two accepted repair strokes. A valid stroke adds one condition to the selected route, capped at three; the second accepted stroke automatically lands the next pulse or finishes after pulse three.
5. Invalid selections and attempts to repair a route already at condition three consume no stroke. Direct calls, buttons, and phase-local keyboard input remain deterministic and guarded.
6. The first time LOOP-C reaches zero posts a bounded six-integrity loss; the first nutrient-reserve zero posts two bounded endurance days; the first carrier-link zero posts `4 + 2 * min(watch_roster_uses, 2)` bounded coherence.
7. Each route may post its contained-failure penalty at most once. Repairing a failed route and later reaching zero again cannot repeat the penalty, and a repair never erases the posted loss.
8. Six accepted strokes complete WO-015 exactly once. Direct calls, button signals, or keys after completion cannot mutate conditions, allocations, resources, or phase.
9. The three allocation policies that protect the same two routes each pulse deterministically leave exactly the intended third route as the sole contained failure.
10. `1`/`2`/`3` select LOOP-C/nutrient reserve/carrier link and `Space` applies a stroke only during WO-015; mouse buttons expose identical selection and repair paths.
11. The active main-deck console exposes all three conditions, the landed and next surge forecast, the exact two-stroke rule, route selection, and every failure consequence without a hidden solution or walkthrough.
12. The station map renders three condition-derived service routes, emphasizes the selected route, and adds a violet carrier trace when the recovered roster was used. Earlier map rendering is unchanged while WO-015 is inactive.
13. Low coherence may change carrier copy only; it never changes the controls, wear schedule, repair effects, failure arithmetic, or route availability.
14. The final ledger records all six allocations, each route's final condition/disposition, endurance/integrity/coherence deltas, and the fact that six strokes were scheduled against twelve wear units.
15. Active pulse, contained-failure, and final-ledger states fit the 1280x720 target and remain legible without clipping.
16. Non-goals: no save/load or general campaign persistence, randomness, new global resource, scene split, asset/plugin import, audio/gamepad work, deployment, or resolution of whether CONTINUITY is an AI, hallucination, adversarial model, or prior operator manifestation.

## What changed

- `src/main.gd`: adds WO-015 phases/state cleanup, entry gating, three-pulse wear and repair logic, one-time bounded failures, map/work/action presentation, exact forecast and consequence copy, phase-local input, and final campaign ledger.
- `src/station_map.gd`: adds state-derived condition routes for LOOP-C, nutrient reserve, and carrier link while preserving inactive rendering.
- `tests/verify.gd`: adds entry/guard, wear, allocation-policy, penalty/bounds, repeat-failure, history, input/button, map/UI, reset, and completion-idempotence coverage.
- `tests/capture.gd`: adds deterministic active-pulse, contained-failure, and completed-ledger frames.
- `README.md`: documents the playable WO-015 loop and phase-scoped controls.
- `CLAUDE.md`: records WO-015 architecture and deterministic invariants.

## How to verify

Run from a clean detached worktree at implementation head `aa05924ea58c90ce3d7b4156c70e4b88701212e7`:

```sh
rtk godot --headless --path . --editor --quit
rtk godot --headless --path . --script res://tests/verify.gd
rtk godot --path . --resolution 1280x720 --script res://tests/capture.gd
rtk git diff --check c8f78e44950ef7ab9e4a829c1bcda3f30d23a6f8..aa05924ea58c90ce3d7b4156c70e4b88701212e7
rtk git diff --name-only c8f78e44950ef7ab9e4a829c1bcda3f30d23a6f8..aa05924ea58c90ce3d7b4156c70e4b88701212e7
```

Expected: import exits 0; `VERIFY PASS: 194 deterministic gameplay checks`; capture exits 0 and writes all prior frames plus `11-maintenance-active.png`, `12-maintenance-contained-failure.png`, and `13-maintenance-ledger.png`; diff check is empty; changed files are exactly the six listed above. Visually inspect all three new PNGs at 1280x720.

## Author verification evidence

1. Tests: `rtk godot --headless --path . --script res://tests/verify.gd` exited 0 with `VERIFY PASS: 194 deterministic gameplay checks`.
2. Build/import and render: `rtk godot --headless --path . --editor --quit` exited 0 without parser/resource errors. The real-render capture command exited 0 with `CAPTURE PASS`; all three new files are 1280x720 RGBA PNGs and were visually inspected without clipping. The active footer was corrected to show the phase-local `1-3`/`Space` controls before the final render pass.
3. Clean state: after the implementation commit, `rtk git status --short --branch` reported only `## feature/m9-maintenance-rotation...origin/feature/m9-maintenance-rotation`.
4. End-to-end self-review: read the complete implementation/test/docs diff, recomputed all three protection policies, checked one-time zero handling and bounds, reviewed phase/input guards, and inspected the three rendered states. An independent read-only agent review reported no findings.
5. Scope: `rtk git diff --name-only <base>..<head>` reports exactly `CLAUDE.md`, `README.md`, `src/main.gd`, `src/station_map.gd`, `tests/capture.gd`, and `tests/verify.gd`; `project.godot` is untouched. `rtk git diff --check <base>..<head>` exits 0 with no output.
6. Authorship: implementation commit `aa05924ea58c90ce3d7b4156c70e4b88701212e7` is the owner's git identity and contains no `Co-Authored-By` trailer.
7. Project reference: `CLAUDE.md` and `README.md` are updated in the implementation commit. No ADR is required because this extends the existing single-scene deterministic campaign architecture without introducing a new architectural decision.
8. Cycle allocation: immediate `.peer-review/` child directories had numeric prefixes `001` through `008`; `009-m9-maintenance-rotation` was created only after that scan and did not collide.
9. Delivery: implementation head is pushed to both `github` and the local `origin` mirror. PR #5 was refreshed as OPEN, non-draft, MERGEABLE, and CLEAN at exact implementation head `aa05924ea58c90ce3d7b4156c70e4b88701212e7`; GitHub reports no configured CI checks (`statusCheckRollup: null`).

## Known limitations / open questions

- Rendering was verified on Linux/WSL2 with Godot 4.4.1 GL Compatibility and Mesa/D3D12 at the 1280x720 target, not other platforms, renderers, window sizes, or display scales.
- Input verification uses direct method calls, synthesized key events, and button signals; it does not cover physical keyboard focus traversal, key repeat, IME, gamepad, accessibility tooling, or a complete input-only campaign playthrough.
- Tests assert forecast/state visibility but not every exact displayed forecast string; the three target screenshots were inspected manually.
- There is no CI configured on the private repository, so local author/reviewer verification is the delivery gate.
- The forced tradeoff is intentional: six repair strokes cannot absorb twelve scheduled wear units. The final copy identifies this arithmetic without resolving who authored the rotation.
