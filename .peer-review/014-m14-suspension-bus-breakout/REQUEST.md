# Review Request: M14 Suspension Bus Breakout
- **Author**: Codex
- **Repository**: <https://github.com/yiangwow/fault-tolerance-godot>
- **Branch**: `feature/m14-suspension-bus-breakout`
- **Base**: `main` @ `89ada04e75e20003343af2a891df87a2d15ae592`
- **Implementation head**: `e524c9e1c99ef8ae943d2f6876e96c319885eb44`
- **PR**: <private archive PR #10> — OPEN
- **Risk level**: 1
- **Scope**: Add deterministic Shift 15 / WO-020 suspension-bus breakout
  gameplay, presentation, tests, captures, and reference documentation; do not
  add persistence, networking, plugins, deployment changes, or mutations to
  historical M1-M13 facts.
- **Source of truth**: The owner's instruction to continue the campaign after
  merged `m13`, preserving the established systems-horror premise and
  deterministic milestone/review workflow.
- **Risk rationale**: This is additive internal Godot gameplay state and custom
  rendering with no public API, schema, security, deployment, saved-data, or
  external-consumer impact.

## Acceptance criteria

1. Only a completed M13 summary enters M14; both clean and slipped M13 outcomes
   qualify.
2. M14 starts three closed copper commoning bars and presents three ordered
   printed proof topologies: `O/C/C`, `O/C/O`, then `O/O/O`.
3. `1`, `2`, and `3` toggle the corresponding bar; `Space` injects the active
   proof. Shared maintenance controls mirror those paths.
4. A correct topology records exactly one proof event, advances once, and
   consumes no arc fuse. An incorrect topology stays on the same stage,
   records one rejection, and consumes one of two fuses.
5. Three correct proofs close clean with four persistent accepted-load labels,
   add three bounded integrity, and cost two bounded coherence.
6. A second rejected proof auto-closes degraded exactly once, leaves integrity
   unchanged, and costs six bounded coherence.
7. Degraded summary copy is truthful: zero accepted proofs reports no valid
   breakout proof, while partial completion reports the accepted proof count.
8. M14 never mutates M1-M13 historical arrays, dictionaries, crew facts,
   service state, walkback state, splice state, or gyro state.
9. Completed direct, keyboard, and shared-button input is inert. Reset clears
   every M14 field and restores the station map.
10. Low coherence changes source-attribution copy and the violet trace
    presentation only; it never changes headings, controls, topology, budgets,
    arithmetic, or outcomes.
11. `BusDisplay` is presentation-only, deep-copies incoming arrays, and renders
    four load conductors, three legible knife switches, proof/fuse readout, and
    a violet load trace at 1280x720.
12. After accepted breakout proofs, the load trace and all four labels persist
    across visibly open local bars. Copy locates the labels upstream of those
    local conductors without resolving whether they are current, stale,
    replayed, remote, simulated, mislabeled, or inherited.
13. Clean, partial-failure, and zero-proof ledgers remain internally truthful;
    the eight-row clean ledger is fully visible.
14. Existing gameplay remains green, documentation describes WO-020, and
    deterministic captures cover active, rejected-arc, and clean-ledger states.

## What changed

- `src/main.gd` — M14 phases, state machine, controls, proof/rejection events,
  resource outcomes, campaign routing, truthful ledgers, reset, and shared UI
  integration.
- `src/bus_display.gd` and `.uid` — resolution-independent suspension-bus,
  knife-switch, proof-budget, and persistent-load renderer.
- `tests/verify.gd` — deterministic M14 coverage, historical-state guards,
  completed-input guards, and ledger-truth regressions.
- `tests/capture.gd` — active, rejected-arc, and clean-ledger M14 captures plus
  a visible-line guard.
- `README.md` and `CLAUDE.md` — play instructions, architecture, and invariants.

## How to verify

```sh
rtk godot --headless --path . --editor --quit
rtk godot --headless --path . --script res://tests/verify.gd
rtk godot --path . --resolution 1280x720 --script res://tests/capture.gd
rtk git diff --check 89ada04e75e20003343af2a891df87a2d15ae592..e524c9e1c99ef8ae943d2f6876e96c319885eb44
```

Expected:

- Import exits without parse/import errors.
- `VERIFY PASS: 279 deterministic gameplay checks`.
- Capture exits with the suspension-bus frame summary. The environment may emit
  the known unsupported V-Sync warning.
- `git diff --check` exits 0 with no output.

Inspect:

- `captures/26-bus-active.png`
- `captures/27-bus-arc-rejected.png`
- `captures/28-bus-ledger.png`

## Author verification evidence

1. Tests: exit 0 — `VERIFY PASS: 279 deterministic gameplay checks`.
2. Build/import and capture: both exit 0. Import reports no parse/import error;
   graphical capture reports all frames written, with only the known V-Sync
   warning.
3. Status before request: clean implementation tree on
   `feature/m14-suspension-bus-breakout`; both remotes contain
   `e524c9e1c99ef8ae943d2f6876e96c319885eb44`.
4. PR verification: PR #10 is OPEN, targets `main`, has implementation head
   `e524c9e1c99ef8ae943d2f6876e96c319885eb44`, is MERGEABLE/CLEAN, and contains
   exactly the one implementation commit.
5. Self-review: reviewed the seven-file diff, inspected all three M14 frames at
   native 1280x720, shortened a clipped proof-readout heading, and corrected
   degraded zero-proof/partial-proof ledger claims. A separate focused
   read-only code review found no remaining blocker or major after that fix.
6. Scope: `git diff --name-status
   89ada04e75e20003343af2a891df87a2d15ae592..e524c9e1c99ef8ae943d2f6876e96c319885eb44`
   contains only the seven files listed under "What changed".
7. Authorship:
   the owner's git identity; commit has no `Co-Authored-By` trailer.
8. Documentation: `README.md` and `CLAUDE.md` were updated in the implementation
   commit. No `ADR.md` or `CONTRIBUTING.md` exists; this additive mechanic
   follows the established presentation-module pattern and needs no new ADR.
9. Cycle allocation: immediate `.peer-review/` children were scanned; `013`
   was the highest numeric prefix, so non-colliding cycle `014` was created.

## Known limitations / open questions

- The UI and capture matrix intentionally target 1280x720 only.
- The campaign currently ends at M14; there is no save/load or general
  persistence.
- Captures are ignored generated artifacts and are not committed.
- GitHub reports no configured CI checks (`statusCheckRollup: null`); local
  import, deterministic verification, capture, and peer review are the
  delivery gates.
- The violet trace flicker is cosmetic and presentation-only; all gameplay and
  recorded state remain deterministic.
