# Review Request: M10 Reactive Service Run
- **Author**: Codex
- **Repository**: git@github.com:yiangwow/fault-tolerance-godot.git
- **Branch**: feature/m10-service-run
- **Base**: main @ 84ae96177f0a18a6bfccb25ecfa1fa33b93c36d8
- **Implementation head**: 33ee09882f7a79315a72b09a35f061b7f7d23a53
- **PR**: private archive PR #6 (OPEN)
- **Risk level**: 1
- **Scope**: Add deterministic Shift 11 / WO-016 reactive route servicing after M9; do not add persistence, dependencies, network access, API/schema changes, or deployment behavior.
- **Source of truth**: The owner's requests in this thread to continue to the next milestone and then "merge and continue", refined into the independently testable M10 contract below.
- **Risk rationale**: This changes internal deterministic gameplay, generated UI, and custom map rendering without changing an external API, schema, service, security posture, or delivery mechanism.

## Acceptance criteria

1. Only a completed WO-015 summary can enter WO-016; entry preserves M8/M9 watch, carrier, repair, roster-use, and scar history.
2. Every M9 failed route remains visibly scarred. One route is overhauled by fixed `loop`, `reserve`, `carrier` priority among failures, falling back to LOOP-C when none exists.
3. The overhauled route starts at condition 4 and the other two at 3. A valid action adds 2 to the selected route up to 4 and subtracts 1 from each other route down to 0.
4. All three resulting conditions and any first-zero consequence are shown before commit. A full or invalid selection applies no action, transfer, loss, history entry, or timestamp.
5. Nine accepted actions complete once. Direct calls, keyboard events, and visible mouse-button input are inert after completion.
6. The first WO-016 zero per route posts one bounded loss: LOOP-C `-4 integrity`, nutrient reserve `-1 endurance`, carrier link `-3 coherence`. Repair and re-zero cannot post it twice.
7. Carrier loss creates an M10-only silent state only if a historical carrier survived; it never mutates Mina, WO-013 responder history, roster uses, crew count, or watch history.
8. Low coherence changes copy only, never controls, projection, arithmetic, loss, or completion.
9. The final ledger correlates command and service-wear timestamps while explicitly leaving the physical timebase and cause unresolved.
10. Keyboard and mouse controls both operate the active M9 and M10 interaction. Existing campaign behavior remains covered.
11. Non-goals: no randomness, persistence, save/load, plugin/asset dependency, network call, deployment workflow, or continuation past the WO-016 ledger.

## What changed

- `src/main.gd`: adds M10 phase/state, entry gate, route-transfer rules, one-time consequences, shared keyboard/mouse dispatch, active console, and final ledger.
- `src/station_map.gd`: adds four-condition route display and persistent M9 scar marks.
- `tests/verify.gd`: adds M10 state, arithmetic, bounds, history, reset, low-coherence, input, mouse-signal, and idempotence checks.
- `tests/capture.gd`: adds active, carrier-silence, and final-ledger target-resolution frames.
- `README.md` and `CLAUDE.md`: document player-facing controls and the M10 invariants.

## How to verify

1. `rtk godot --headless --path . --editor --quit`
   - Expected: exit 0 with no script parse/import errors.
2. `rtk godot --headless --path . --script res://tests/verify.gd`
   - Expected: `VERIFY PASS: 215 deterministic gameplay checks`.
3. `rtk godot --path . --resolution 1280x720 --script res://tests/capture.gd`
   - Expected: exit 0 and `CAPTURE PASS`; the environment may emit its known V-Sync warning.
4. `rtk git diff --check 84ae96177f0a18a6bfccb25ecfa1fa33b93c36d8..33ee09882f7a79315a72b09a35f061b7f7d23a53`
   - Expected: exit 0 and no output.
5. Inspect `captures/14-service-run-active.png`, `captures/15-service-carrier-silence.png`, and `captures/16-service-ledger.png` at 1280x720.

## Author verification evidence

1. Tests: `rtk godot --headless --path . --script res://tests/verify.gd` exited 0 with `VERIFY PASS: 215 deterministic gameplay checks`.
2. Build/lint: Godot editor import/parse exited 0; real-render capture exited 0 with `CAPTURE PASS`; `rtk git diff --check` exited 0 with no output.
3. Clean status: `rtk git status --porcelain=v1` returned no output after implementation commit.
4. End-to-end diff review: completed. The first read-only pass found that shared mouse buttons still dispatched to M9 handlers; this was fixed before the implementation head was frozen. A second read-only pass found no remaining concrete findings.
5. Scope: `rtk git diff --name-only main..HEAD` listed only the six files under **What changed**.
6. Authorship: implementation head is authored and committed by the owner's git identity; `rtk git log --format=%B main..HEAD` contains no `Co-Authored-By` trailer.
7. Project references: `README.md` and required root `CLAUDE.md` were updated. `AGENTS.md`, services, ports, and architecture decision records are unaffected; no ADR is needed for this bounded gameplay extension.
8. Cycle allocation: immediate numbered children were `001` through `009`; the next non-colliding directory is `010-m10-service-run`.

## Known limitations / open questions

- The UI is intentionally targeted and visually checked at 1280x720; non-target aspect ratios receive Godot stretch behavior but no screenshot matrix.
- The campaign deliberately ends at the WO-016 ledger and has no save/load.
- Render captures are ignored artifacts rather than committed binary files; the reviewer should regenerate them locally.
