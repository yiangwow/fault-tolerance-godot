# Review Request: M5 timed AUX-4 seal brace
- **Author**: Codex
- **Repository**: /home/unix/tmp/fault-tolerance-godot-origin.git
- **Branch**: feature/m5-aux4-seal-brace
- **Base**: main @ 9677b227b69fa0cf79c8c808df872302c2ff7417
- **Implementation head**: 5bb1d4cc34118de0ae220ab73c69cc0230b944be
- **PR**: N/A — this local-only Godot repository has no hosted forge or CI service
- **Risk level**: 1
- **Scope**: Add one optional, deterministic, one-minute AUX-4 seal-brace intervention inside WO-011 and carry its bounded integrity effect through the existing campaign; do not add another work order, resource, persistence layer, random event, audio system, plugin, or network behavior.
- **Source of truth**: User directed continued Godot development toward embodied engineering under time pressure and explicitly allowed mature external imports when useful. This milestone's fixed brief is a state-derived T+06 deformation alarm, a one-time field repair, a visible physical map transformation, fully disclosed route-specific effects, normal deadline semantics, and immutable campaign history.
- **Risk rationale**: This changes internal deterministic gameplay, generated UI, custom map drawing, tests, captures, and documentation only. It adds no public API, save schema, service, deployment, security boundary, plugin, network call, or external-consumer contract.

## Acceptance criteria

1. WO-011 remains the same twelve-minute deterministic repair and all M4 outcomes, WO-012 dispositions, and WO-013 rules remain available on their prior routes.
2. The existing AUX-4 deformation event occurs at T+06 and exposes one visible `[6] BRACE INNER SEAL` field action only during unresolved WO-011.
3. Bracing is unavailable before T+06, costs exactly one normal WO-011 minute, applies the normal integrity/coherence time cost, and can complete only once.
4. Keyboard `6` and the visible button reach the same action; early or repeated requests change no state or time.
5. The field-action copy discloses `-01m`, `+08` integrity on local routes, and no purge benefit before commitment.
6. The station map shows a deforming AUX-4 seal after T+06, visible clamp struts after a completed brace, and a lost state if a later rupture destroys a completed brace.
7. A completed brace changes only the fixed local-route integrity baselines: bypass `43 -> 51` and isolation `52 -> 60`, bounded at 100. Purge remains 87 and rupture remains 0.
8. A legal public-action isolation route can investigate to T+06, brace to T+07, and complete isolation exactly at T+12.
9. A legal route that also spends three minutes supporting Jae after bracing overruns isolation, ruptures at T+12, and records `BRACED / LOST WITH AUX-4`.
10. Immediate WO-011 outcome ledgers disclose whether the brace applied, had no purge benefit, or was lost.
11. Brace state, its integrity result, and an `M1 / SEAL` history row carry through WO-012, the WO-013 decision, and the final ledger without changing disposition costs, responder rules, repair choices, or WO-013 effects.
12. Unbraced purge, bypass, and isolation routes preserve their legacy fixed values and downstream behavior.
13. The 1280×720 active brace and braced final-ledger captures are legible and unclipped; surrounding milestone captures remain visually intact.
14. Non-goals: no new order/overlay, general campaign engine, save/load, real-time ticking, randomness, additional resource meter, audio, imported plugin, network behavior, or definitive rogue-AI/supernatural explanation.

## What changed

- `src/main.gd`
  - Adds the T+06 seal-deformation gate, one-time timed brace action, keyboard/button input, route-specific integrity buffer, explicit outcome/campaign history, and state-derived field-action UI.
- `src/station_map.gd`
  - Adds deforming, braced, and lost AUX-4 seal rendering using the existing resolution-independent schematic.
- `tests/verify.gd`
  - Adds public-action coverage for gating, keyboard/button parity, one-minute cost, irreversibility, route baselines, exact-deadline success, time-pressure rupture, ledger disclosure, and WO-012/WO-013 carryover.
- `tests/capture.gd`
  - Adds a real-action braced-seal frame and changes the final-ledger frame to the legal braced-isolation route.
- `README.md` and `CLAUDE.md`
  - Document the new field action, control, architecture, and deterministic invariants.

## How to verify

1. `godot --headless --path . --editor --quit`
   - Expected: exit 0, scripts register, and the bundled display font imports without parser/resource errors.
2. `godot --headless --path . --script res://tests/verify.gd`
   - Expected: exit 0 and `VERIFY PASS: 122 deterministic gameplay checks`.
3. `godot --path . --resolution 1280x720 --script res://tests/capture.gd`
   - Expected: exit 0 and `CAPTURE PASS: boot, active, braced-seal, order-review, purge, follow-up, campaign-summary, WO-013, and final-ledger frames written to res://captures`.
4. Inspect `captures/02c-braced-inner-seal.png`, `captures/06-wo013-repair.png`, and `captures/07-campaign-ledger.png`.
   - Expected: the field action, clamp marks, effect disclosure, footer shortcut, WO-013 controls, and seven-row final ledger fit at 1280×720 without clipping.
5. `git diff --check 9677b227b69fa0cf79c8c808df872302c2ff7417..5bb1d4cc34118de0ae220ab73c69cc0230b944be`
   - Expected: exit 0 with no output.

## Author verification evidence

1. Tests: the working checkout and a newly created detached worktree at the implementation head each exited 0 with `VERIFY PASS: 122 deterministic gameplay checks`.
2. Build/import: both checkouts ran `godot --headless --path . --editor --quit` successfully. The detached checkout began without `.godot/`, imported `Kenney Future Narrow.ttf`, and registered all four scripts without parser/resource errors.
3. Captures: both checkouts regenerated all nine expected frames. The working captures were visually inspected; independent visual audit found the field card, clamp marks, evidence scrollbar, footer, WO-013 controls, and final seven-row ledger legible and unclipped.
4. Diagnostics: Serena warning-or-higher diagnostics returned `{}` for `src/main.gd`, `src/station_map.gd`, `tests/verify.gd`, and `tests/capture.gd`.
5. Clean status: after the implementation commit, `git status --short --branch` exited 0 with only `## feature/m5-aux4-seal-brace`.
6. Self-review: reviewed the complete `main..HEAD` diff end to end and commissioned independent read-only logic and visual audits. The first design made braced isolation unreachable at T+07; the alarm was moved to T+06 and the test was converted to a legal exact-deadline player route. Synthetic setup paths and missing later-ledger history were also replaced before this request.
7. Scope: `git diff --name-only main..HEAD` lists only `CLAUDE.md`, `README.md`, `src/main.gd`, `src/station_map.gd`, `tests/capture.gd`, and `tests/verify.gd`. Godot-generated `project.godot` churn was explicitly removed.
8. Authorship: `git show -s --format=%an%n%ae%n%B HEAD` reported `yiangwow`, `<removed>`, and no `Co-Authored-By` trailer.
9. Project docs: mandatory `CLAUDE.md` and `README.md` were updated. No `ADR.md`, `docs/adr/`, `CONTRIBUTING.md`, service, port, deployment workflow, or public architectural contract exists; no ADR is needed for this bounded Level 1 change.
10. Cycle allocation: immediate numbered directories were `001-aux4-godot-slice`, `002-m2-inspectable-work-order`, `003-m3-wo012-disposition`, and `004-m4-wo013-manual-handoff`; `005-m5-aux4-seal-brace` was created without collision.

## Known limitations / open questions

- The brace is one authored field intervention, not a reusable maintenance-action framework.
- The T+06 trigger is action-time based; the slice still has no real-time clock.
- The brace affects integrity only after a local repair outcome; its one-minute immediate cost still lowers the live pre-commit integrity/coherence meters normally.
- Rendering was verified at the 1280×720 target on Linux/WSL2 with Godot 4.4.1, not across other platforms, renderers, or window sizes.
- Audio remains intentionally separate so imported cues can be auditioned and mute/volume behavior can be treated coherently.
