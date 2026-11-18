# Review Request: M4 timed WO-013 manual handoff
- **Author**: Codex
- **Repository**: /home/unix/tmp/fault-tolerance-godot-origin.git
- **Branch**: feature/m4-wo013-manual-handoff
- **Base**: main @ c485a44464c0451e0fa4ac1432f7e21526e8379c
- **Implementation head**: bbb28c34c1f3d9b778699b8731c6a26ed6f6d538
- **PR**: N/A — this local-only Godot repository has no GitHub remote or CI service
- **Risk level**: 1
- **Scope**: Add one deterministic six-minute WO-013 repair after WO-012 and bundle one CC0 display font; do not add a campaign framework, persistence, procedural content, audio, or another work order.
- **Source of truth**: User directed continued development toward repeated repairs and explicitly authorized mature external imports rather than rebuilding commodity assets. M4's fixed brief is one optional two-minute signal trace, a four-minute remote vent, a five-minute manual handoff, exact-deadline success, handoff overrun rupture, prior-state carryover, bounded low-coherence attribution, and fully disclosed irreversible costs.
- **Risk rationale**: This changes internal deterministic gameplay, generated UI, tests, captures, and one bundled font only. It adds no public API, schema, save data, service, deployment, plugin, network behavior, or external consumer contract.

## Acceptance criteria

1. All three surviving WO-011 routes and both WO-012 dispositions can enter one distinct WO-013 repair phase; WO-011 rupture remains terminal.
2. WO-013 carries Mina, Jae, integrity, coherence, endurance, WO-012 disposition, and historical responder state without reviving or rewriting prior losses.
3. The repair starts with six minutes and exposes three readable, enabled controls under every coherence state: optional signal trace, remote vent, and manual handoff.
4. Signal trace costs two minutes once, changes attribution evidence only, and never gates or changes either repair outcome.
5. Remote vent costs four minutes, adds three endurance days and twelve bounded integrity, costs ten bounded coherence, and loses the manual responder signal.
6. Manual handoff costs five minutes, spends two bounded endurance days, adds five bounded integrity and three bounded coherence, and retains a responder only when WO-012 quarantine retained one.
7. Trace followed by remote vent succeeds exactly at minute six; trace followed by manual handoff overruns, clamps at six, ruptures the service spine, damages the ledger, and loses the signal.
8. Both repair buttons disclose time, endurance, integrity, coherence, and signal consequences before commitment; a sterilization path never promises that handoff will preserve an already-lost responder.
9. Low coherence may duplicate or destabilize signal attribution text but cannot hide, disable, rename, or alter any action, cost, or deterministic outcome.
10. The final ledger visibly retains the WO-011, WO-012, and WO-013 chain and its historical/current responder distinction.
11. Keyboard and visible-button paths reach WO-013, trace, remote vent, and manual handoff; resolved choices are irreversible.
12. The 1280×720 WO-013 decision and final-ledger captures render without clipped rows or controls.
13. The display face is bundled from Kenney's official CC0 font pack, its exact file/hash/license are recorded, and a fresh checkout imports and runs without system-font dependence.
14. Non-goals: no save/load, general campaign state machine, procedural repairs, map expansion, inventory, randomness, audio, plugin, network call, or definitive rogue-AI/supernatural explanation.

## What changed

- `src/main.gd`
  - Adds WO-013 repair/final phases, deterministic carryover and timing, optional signal trace, remote/handoff/rupture resolution, explicit effect labels, bounded low-coherence attribution, and keyboard flow.
  - Uses the bundled Kenney display font while retaining the existing mono system fallback for dense operational text.
- `tests/verify.gd`
  - Adds all six prior-route/disposition entries plus optional/untraced repair, exact deadline, overrun, bounded effects, responder-history, full-label, low-coherence, keyboard/button, and irreversibility coverage.
- `tests/capture.gd`
  - Adds a low-coherence/source-absent WO-013 decision frame and a responder-retained final campaign ledger.
- `assets/fonts/Kenney Future Narrow.ttf` and `.import`
  - Add the unmodified CC0 display font and Godot import metadata.
- `THIRD_PARTY.md`
  - Records official source, archive member, SHA-256, and CC0 license.
- `README.md` and `CLAUDE.md`
  - Document the second timed repair, phase-specific controls, clean import command, asset provenance, architecture, and deterministic invariants.

## How to verify

1. `godot --headless --path . --editor --quit`
   - Expected: exit 0, scripts register, and `Kenney Future Narrow.ttf` imports without parser/resource errors.
2. `godot --headless --path . --script res://tests/verify.gd`
   - Expected: exit 0 and `VERIFY PASS: 107 deterministic gameplay checks`.
3. `godot --path . --resolution 1280x720 --script res://tests/capture.gd`
   - Expected: exit 0 and `CAPTURE PASS: boot, active, order-review, purge, follow-up, campaign-summary, WO-013, and final-ledger frames written to res://captures`.
4. Inspect `captures/01-boot.png`, `captures/02-active-investigation.png`, `captures/06-wo013-repair.png`, and `captures/07-campaign-ledger.png`.
   - Expected: the bundled display face renders consistently; both WO-013 repair choices disclose all effects and fit; the source-absent trace and six-row final ledger are fully visible.
5. `sha256sum "assets/fonts/Kenney Future Narrow.ttf"`
   - Expected: `572a3fc36adedf951365f77fa37011115363c7e8a537a308e563abdb299d7477`.
6. `git diff --check c485a44464c0451e0fa4ac1432f7e21526e8379c..bbb28c34c1f3d9b778699b8731c6a26ed6f6d538`
   - Expected: exit 0 with no output.

## Author verification evidence

1. Tests: both the working checkout and a newly created detached worktree at the implementation head ran `godot --headless --path . --script res://tests/verify.gd` after import; each exited 0 with `VERIFY PASS: 107 deterministic gameplay checks`.
2. Build/lint: the fresh detached worktree ran `godot --headless --path . --editor --quit`; it exited 0, registered all four scripts, and imported `Kenney Future Narrow.ttf`. Serena warning-or-higher diagnostics returned `{}` for `src/main.gd`, `tests/verify.gd`, and `tests/capture.gd`.
3. Clean status: after the implementation commit, `git status --short --branch` exited 0 with only `## feature/m4-wo013-manual-handoff`.
4. Self-review: reviewed the complete `main..HEAD` diff end to end and commissioned a separate read-only logic audit. Its misleading-handoff and incomplete-effect-label findings were reproduced and fixed before this request. `git diff --cached --check` and `git diff --check` exited 0 with no output.
5. Scope: `git diff --name-only main..HEAD` lists only `CLAUDE.md`, `README.md`, `THIRD_PARTY.md`, the font and import metadata, `src/main.gd`, `tests/capture.gd`, and `tests/verify.gd`. Godot-generated `project.godot` churn was explicitly removed.
6. Authorship: `git show -s --format=%an%n%ae%n%B HEAD` reported `yiangwow`, `<removed>`, and no `Co-Authored-By` trailer.
7. Project docs: `README.md`, mandatory `CLAUDE.md`, and `THIRD_PARTY.md` were updated in the implementation commit. No `ADR.md`, `docs/adr/`, `CONTRIBUTING.md`, service, port, deployment workflow, or public architectural contract exists; no ADR is needed for this bounded Level 1 extension.
8. Cycle allocation: immediate numbered directories were `001-aux4-godot-slice`, `002-m2-inspectable-work-order`, and `003-m3-wo012-disposition`; `004-m4-wo013-manual-handoff` was created without collision.

## Known limitations / open questions

- WO-013 is one authored repair, not a reusable campaign/order engine; restart still reloads the whole slice.
- The optional trace changes evidence and time pressure, not numeric repair effects.
- The mono face remains a system-font fallback chain; only the distinctive display face is bundled.
- Audio was deliberately deferred until cues can be auditioned and volume/mute semantics can be treated as their own coherent milestone.
- Captures are ignored local verification artifacts and are not part of the implementation commit.
