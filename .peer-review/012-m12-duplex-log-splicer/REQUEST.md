# Review Request: M12 Duplex Log Splicer
- **Author**: Codex
- **Repository**: git@github.com:yiangwow/fault-tolerance-godot.git
- **Branch**: feature/m12-duplex-log-splicer
- **Base**: main @ 6be28e2237282519154396b0b38148363b13b1e3
- **Implementation head**: 39223e1cd6766b908863fba330d9d8ba00d1d16e
- **PR**: private archive PR #8 (OPEN)
- **Risk level**: 1
- **Scope**: Add deterministic Shift 13 / WO-018 physical tape-splicing gameplay after M11; do not add persistence, dependencies, network access, API/schema changes, or deployment behavior.
- **Source of truth**: The owner's instruction to continue the merged playable campaign with serious, mechanically distinct systems-horror gameplay and the established incremental Claude review cycle, refined into the independently testable M12 contract below.
- **Risk rationale**: This changes internal deterministic gameplay, generated UI, and a presentation-only custom renderer without changing an external API, schema, service, security posture, or delivery mechanism.

## Acceptance criteria

1. Only a completed WO-017 summary can enter WO-018. Entry preserves all campaign resources and M8-M11 crew, responder, carrier, maintenance, service, walkback, witness, hazard, and outcome state.
2. WO-018 exposes six fixed three-bit gate targets and one CORE, TETHER, and BADGE feed candidate per row. Exactly one candidate matches each target, in fixed TETHER, CORE, BADGE, TETHER, BADGE, CORE order.
3. Keyboard `1`/`2`/`3` and the three visible feed buttons directly attempt CORE/TETHER/BADGE respectively. A matching feed appends once, advances exactly one row, and records one timestamp.
4. A mismatched feed does not append or advance; it consumes one of two tape-tension units and records one misfeed timestamp. The second mismatch finishes once through the degraded automatic-splice path.
5. Invalid feed names, a premature keyboard or mouse-button cross-stamp, and feed input after all six segments consume nothing, change no state, and record no timestamp.
6. Six correct segments enable one manual Space/button cross-stamp. It adds three bounded integrity, costs two bounded coherence, and completes once.
7. A degraded automatic splice changes no integrity, costs six bounded coherence, and completes once.
8. Completed direct method, keyboard, and shared-button input is inert. Reset clears every M12 field and restores the station map while hiding the recorder.
9. Low coherence changes only attribution copy and the older-impression rendering; it does not change target/candidate punches, controls, tension, resource arithmetic, or completion.
10. The presentation-only recorder defensively copies state and draws three perforated tapes, six gate targets, current-row emphasis, completed splice lines, older violet impressions, and restrained red damage at 1280x720.
11. A clean final reel states that its older pressure impression contains the same six feed choices before the current repair. A torn reel retains an unauthenticated partial comparison. Neither names a duplicate, forgery, loop, simulation, or cause.
12. Existing campaign behavior remains covered. Non-goals: no randomness, save/load, plugin or asset dependency, network call, deployment workflow, or continuation past the WO-018 ledger.

## What changed

- `src/main.gd`: adds M12 phases/state, M11 continuation gate, feed matching, tension/misfeed accounting, clean/degraded outcomes, shared keyboard/mouse dispatch, console, reset, and ledgers.
- `src/splice_display.gd` and its Godot UID: add the presentation-only physical recorder, perforated tapes, target gate, completed lines, older impression, and tear marks.
- `tests/verify.gd`: adds M12 gate, unique mapping, input, no-timestamp, exact accounting, bounds, immutability, low-coherence, reset, and idempotence coverage.
- `tests/capture.gd`: adds active, one-misfeed, and clean final-ledger target-resolution frames.
- `README.md` and `CLAUDE.md`: document player-facing controls, architecture, and the M12 invariants.

## How to verify

1. `rtk godot --headless --path . --editor --quit`
   - Expected: exit 0 with no script parse/import errors.
2. `rtk godot --headless --path . --script res://tests/verify.gd`
   - Expected: `VERIFY PASS: 246 deterministic gameplay checks`.
3. `rtk godot --path . --resolution 1280x720 --script res://tests/capture.gd`
   - Expected: exit 0 and `CAPTURE PASS`; the environment may emit its known V-Sync warning.
4. `rtk git diff --check 6be28e2237282519154396b0b38148363b13b1e3..39223e1cd6766b908863fba330d9d8ba00d1d16e`
   - Expected: exit 0 and no output.
5. Inspect `captures/20-splicer-active.png`, `captures/21-splicer-misfeed.png`, and `captures/22-splicer-ledger.png` at 1280x720.

## Author verification evidence

1. Tests: `rtk godot --headless --path . --script res://tests/verify.gd` exited 0 with `VERIFY PASS: 246 deterministic gameplay checks`.
2. Build/lint: Godot editor import/parse exited 0; real-render capture exited 0 with `CAPTURE PASS`; `rtk git diff --check` exited 0 with no output.
3. Clean status: `rtk git status --short --branch` showed only the clean branch/tracking header after the implementation commit.
4. End-to-end diff review: completed. The renderer pass corrected initial tension/damage semantics before freeze. A focused read-only review found only three cheap coverage gaps—unique punch mapping, premature shared-button stamp, and post-outcome M11 immutability—which were all added before the implementation head was frozen; no implementation defect remained.
5. Scope: `rtk git diff --name-status 6be28e2237282519154396b0b38148363b13b1e3..39223e1cd6766b908863fba330d9d8ba00d1d16e` listed only the seven files under **What changed**.
6. Authorship: implementation head is authored and committed by the owner's git identity; its commit message contains no `Co-Authored-By` trailer.
7. Project references: `README.md` and required root `CLAUDE.md` were updated. `AGENTS.md`, services, ports, and architecture decision records are unaffected; no ADR is needed for this bounded gameplay extension.
8. Cycle allocation: immediate numbered children were `001` through `011`; the next non-colliding directory was created as `012-m12-duplex-log-splicer`.

## Known limitations / open questions

- The UI is intentionally targeted and visually checked at 1280x720; non-target aspect ratios receive Godot stretch behavior but no screenshot matrix.
- The punch patterns are fully visible by design: this is a physical observation/assembly repair, not a hidden-answer puzzle.
- The campaign deliberately ends at the WO-018 ledger and has no save/load.
- Render captures are ignored artifacts rather than committed binary files; the reviewer should regenerate them locally.
- This private repository has no configured GitHub status checks (`statusCheckRollup` is null); the reproducible local import, deterministic suite, capture pass, and diff check are the delivery gates.
