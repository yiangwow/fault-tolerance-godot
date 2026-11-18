# Review Request: M13 Inertial Reference Cage
- **Author**: Codex
- **Repository**: <https://github.com/yiangwow/fault-tolerance-godot>
- **Branch**: `feature/m13-inertial-reference-cage`
- **Base**: `main` @ `936618638097f2f74696f5958445c466a819d710`
- **Implementation head**: `301e80ec7e73e23ea02436cbd471f6ccbcaef848`
- **PR**: <private archive PR #9> — OPEN
- **Risk level**: 1
- **Scope**: Add deterministic Shift 14 / WO-019 inertial-cage gameplay,
  presentation, tests, captures, and reference documentation; do not add
  persistence, networking, plugins, deployment changes, or mutations to
  historical M1-M12 facts.
- **Source of truth**: The owner's instruction to continue the campaign after
  merged `m12`, preserving the established systems-horror premise and
  deterministic milestone/review workflow.
- **Risk rationale**: This is internal Godot gameplay state and custom rendering
  with no public API, schema, security, deployment, saved-data, or external
  consumer impact.

## Acceptance criteria

1. Only a completed M12 summary enters M13; both clean and torn M12 outcomes
   qualify.
2. M13 starts four eight-detent rings at `0/5/2/7`, targets `2/4/5/0`, nine
   settle detents, and two index pins.
3. `1` rotates counter-clockwise, `2` rotates clockwise, and both wrap
   `0 <-> 7`. Invalid directions and the unused third shared control are inert
   and create no timestamp.
4. `Space` latches only the active ring. A correct datum advances once and
   records one habitat-load event; a wrong datum spends one pin without
   advancing.
5. The seven-movement shortest route leaves two settle detents, records exactly
   four load events, adds four bounded integrity, and costs three bounded
   coherence.
6. The second bad latch, or zero settle with an unreachable active datum,
   auto-closes degraded once, leaves integrity unchanged, and costs seven
   bounded coherence.
7. Landing exactly on a datum with the final settle remains latchable; clean
   completion is not lost to an off-by-one boundary.
8. M13 never mutates M1-M12 historical arrays, dictionaries, crew facts,
   service state, walkback state, or splice state.
9. Completed direct, keyboard, and shared-button input is inert. Reset clears
   every M13 field and restores the station map.
10. Low coherence changes attribution copy and the violet load trace only; it
    never changes headings, controls, budgets, pins, arithmetic, or outcomes.
11. `GyroDisplay` is presentation-only, deep-copies incoming arrays, and
    renders a legible four-ring mechanical cage at 1280×720.
12. Clean copy correlates stabilization latches with nominally occupied
    suspension-line loads without resolving whether occupancy is current,
    stale, simulated, mislabeled, or inherited. Degraded copy retains only a
    partial causal ordering.
13. Existing gameplay remains green, documentation describes WO-019, and
    deterministic captures cover active, rejected-index, and clean-ledger
    states.

## What changed

- `src/main.gd` — M13 phases, state machine, controls, resource outcomes,
  campaign routing, load record, ledgers, reset, and shared UI integration.
- `src/gyro_display.gd` and `.uid` — resolution-independent nested mechanical
  gimbal and load-trace renderer.
- `tests/verify.gd` — deterministic M13 coverage plus the deferred M12
  six-segments-before-stamp regression.
- `tests/capture.gd` — active, rejected-index, and clean-ledger M13 captures.
- `README.md` and `CLAUDE.md` — play instructions, architecture, and invariants.

## How to verify

```sh
rtk godot --headless --path . --editor --quit
rtk godot --headless --path . --script res://tests/verify.gd
rtk godot --path . --resolution 1280x720 --script res://tests/capture.gd
rtk git diff --check 936618638097f2f74696f5958445c466a819d710..301e80ec7e73e23ea02436cbd471f6ccbcaef848
```

Expected:

- Import exits without parse/import errors.
- `VERIFY PASS: 264 deterministic gameplay checks`.
- Capture exits with the inertial-cage frame summary. The environment may emit
  the known unsupported V-Sync warning.
- `git diff --check` exits 0 with no output.

Inspect:

- `captures/23-gyro-active.png`
- `captures/24-gyro-index-rejected.png`
- `captures/25-gyro-ledger.png`

## Author verification evidence

1. Tests: exit 0 — `VERIFY PASS: 264 deterministic gameplay checks`.
2. Build/import and capture: both exit 0. Import reports no parse/import error;
   graphical capture reports all frames written, with only the known V-Sync
   warning.
3. Status before request: clean implementation tree on
   `feature/m13-inertial-reference-cage`; both remotes contain
   `301e80ec7e73e23ea02436cbd471f6ccbcaef848`.
4. Self-review: reviewed the staged seven-file diff end to end, inspected all
   three M13 frames at native 1280×720, corrected detent-angle and latch-index
   rendering, moved overlapping labels, and focused the shortest visible
   rotation. A separate read-only integration pass found no remaining blocker
   or major.
5. Scope: `git diff --name-status
   936618638097f2f74696f5958445c466a819d710..301e80ec7e73e23ea02436cbd471f6ccbcaef848`
   contains only the seven files listed under "What changed".
6. Authorship:
   the owner's git identity; commit has no `Co-Authored-By` trailer.
7. Documentation: `README.md` and `CLAUDE.md` were updated in the implementation
   commit. No `ADR.md` or `CONTRIBUTING.md` exists; no architectural decision
   beyond the established presentation-module pattern requires an ADR.
8. Cycle allocation: immediate `.peer-review/` children were scanned; `012`
   was the highest numeric prefix, so non-colliding cycle `013` was created.

## Known limitations / open questions

- The UI and capture matrix intentionally target 1280×720 only.
- The campaign currently ends at M13; there is no save/load or general
  persistence.
- Captures are ignored generated artifacts and are not committed.
- GitHub reports no configured CI checks (`statusCheckRollup: null`); local
  import, deterministic verification, capture, and peer review are the
  delivery gates.
- The active-ring pulse is cosmetic and uses wall-clock presentation time; all
  gameplay and recorded state remain deterministic.
