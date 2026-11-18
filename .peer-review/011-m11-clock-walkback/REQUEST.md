# Review Request: M11 Local Clock Walkback
- **Author**: Codex
- **Repository**: git@github.com:yiangwow/fault-tolerance-godot.git
- **Branch**: feature/m11-clock-walkback
- **Base**: main @ 9eecb36e5eb67e41303751c2668cc6dbc5a33c64
- **Implementation head**: 8f01d97094f2b0e123a9ab9626f9a19936d894d5
- **PR**: private archive PR #7 (OPEN)
- **Risk level**: 1
- **Scope**: Add deterministic Shift 12 / WO-017 spatial clock-walkback gameplay after M10; do not add persistence, dependencies, network access, API/schema changes, or deployment behavior.
- **Source of truth**: The owner's requests in this thread to merge M10, continue to the next milestone, preserve serious systems-horror direction, and perform the established Claude review cycle, refined into the independently testable M11 contract below.
- **Risk rationale**: This changes internal deterministic gameplay, generated UI, and custom map rendering without changing an external API, schema, service, security posture, or delivery mechanism.

## Acceptance criteria

1. Only a completed WO-016 summary can enter WO-017. Entry preserves prior crew, responder, watch, carrier, M9, M10, and campaign resource state.
2. WO-017 starts at CORE with nine suit-seal units on the fixed graph CORE-MED-2, MED-2-AUX-4, AUX-4-CORE, AUX-4-AIRLOCK, AIRLOCK-BRIDGE, and BRIDGE-CORE.
3. CORE-MED-2, AUX-4-AIRLOCK, and BRIDGE-CORE inherit damage from the matching reserve, loop, and carrier routes. An M9 scar or M10 loss adds one seal to that edge; overlapping history remains one deduplicated surcharge.
4. Each accepted move spends its displayed cost and appends one tether waypoint. Invalid, nonexistent, or unaffordable movement spends no seal and records no path or log timestamp.
5. MED-2, AUX-4, and BRIDGE each provide one mechanical witness. The first read costs one seal; repeated reads and rooms without clocks spend nothing and record no timestamp.
6. Returning two witnesses to CORE permits a lock for bounded integrity +3 and coherence -1. Returning all three permits a stronger lock for bounded integrity +6 and coherence -4.
7. When no accepted move, unread clock, or valid CORE lock remains, tether recovery completes once for bounded integrity -8 and coherence -6.
8. Direct calls, keyboard events, and visible mouse-button input are inert after completion. Reset clears all M11 state and hides the map overlay.
9. Low coherence changes copy only, never graph topology, costs, witness availability, controls, resource effects, or completion.
10. The active map displays the room graph, inherited red corridor hazards, unread/read witness markers, current location, and numbered amber tether breadcrumbs.
11. The final ledger preserves the carrier and crew ambiguity while revealing that local badge-arrival records precede CORE's operator-departure record; the recovery ending instead records two tether returns and one suit-camera return.
12. Existing campaign behavior remains covered. Non-goals: no randomness, save/load, plugin or asset dependency, network call, deployment workflow, or continuation past the WO-017 ledger.

## What changed

- `src/main.gd`: adds the M11 phase/state, entry gate, graph traversal, history-derived costs, one-time witnesses, success/recovery outcomes, shared keyboard/mouse dispatch, active console, and final ledger.
- `src/station_map.gd`: adds the clock-walkback graph, damaged-corridor marks, numbered tether path, witness markers, and current-location pulse.
- `tests/verify.gd`: adds gating, state preservation, input, arithmetic, deduplication, rejection, recovery, reset, low-coherence, map, and idempotence checks.
- `tests/capture.gd`: adds active, mid-route, and three-witness final-ledger target-resolution frames.
- `README.md` and `CLAUDE.md`: document player-facing controls and the M11 invariants.

## How to verify

1. `rtk godot --headless --path . --editor --quit`
   - Expected: exit 0 with no script parse/import errors.
2. `rtk godot --headless --path . --script res://tests/verify.gd`
   - Expected: `VERIFY PASS: 235 deterministic gameplay checks`.
3. `rtk godot --path . --resolution 1280x720 --script res://tests/capture.gd`
   - Expected: exit 0 and `CAPTURE PASS`; the environment may emit its known V-Sync warning.
4. `rtk git diff --check 9eecb36e5eb67e41303751c2668cc6dbc5a33c64..8f01d97094f2b0e123a9ab9626f9a19936d894d5`
   - Expected: exit 0 and no output.
5. Inspect `captures/17-walkback-active.png`, `captures/18-walkback-mid-route.png`, and `captures/19-walkback-three-witness-ledger.png` at 1280x720.

## Author verification evidence

1. Tests: `rtk godot --headless --path . --script res://tests/verify.gd` exited 0 with `VERIFY PASS: 235 deterministic gameplay checks`.
2. Build/lint: Godot editor import/parse exited 0; real-render capture exited 0 with `CAPTURE PASS`; `rtk git diff --check` exited 0 with no output.
3. Clean status: `rtk git status --short --branch` showed only the clean branch/tracking header after the implementation commit.
4. End-to-end diff review: completed. A focused read-only pass found two minor test gaps for overlapping hazards and rejected-action timestamps; both were covered before the implementation head was frozen, and no implementation defect remained.
5. Scope: `rtk git diff --name-status 9eecb36e5eb67e41303751c2668cc6dbc5a33c64..8f01d97094f2b0e123a9ab9626f9a19936d894d5` listed only the six files under **What changed**.
6. Authorship: implementation head is authored and committed by the owner's git identity; the exact commit message contains no `Co-Authored-By` trailer.
7. Project references: `README.md` and required root `CLAUDE.md` were updated. `AGENTS.md`, services, ports, and architecture decision records are unaffected; no ADR is needed for this bounded gameplay extension.
8. Cycle allocation: immediate numbered children were `001` through `010`; the next non-colliding directory was created as `011-m11-clock-walkback`.

## Known limitations / open questions

- The UI is intentionally targeted and visually checked at 1280x720; non-target aspect ratios receive Godot stretch behavior but no screenshot matrix.
- The campaign deliberately ends at the WO-017 ledger and has no save/load.
- Render captures are ignored artifacts rather than committed binary files; the reviewer should regenerate them locally.
- This private repository has no configured GitHub status checks (`statusCheckRollup` is null); the reproducible local import, deterministic suite, capture pass, and diff check are the delivery gates.
