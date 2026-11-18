# Review Request: M3 playable WO-012 disposition
- **Author**: Codex
- **Repository**: /home/unix/tmp/fault-tolerance-godot-origin.git
- **Branch**: feature/m3-wo012-disposition
- **Base**: main @ b69677ab73f99b1cd7a3f78ce70df37371e9207b
- **Implementation head**: eb83bbc7fb52eea95d9b6bdc188acf0614d620f3
- **PR**: N/A — this local-only Godot repository has no GitHub remote or CI service
- **Risk level**: 1
- **Scope**: Make the existing WO-012 teaser a deterministic, playable two-choice consequence that carries WO-011 state forward; do not add campaign persistence, procedural systems, or another repair loop.
- **Source of truth**: User-approved M3 brief: surviving WO-011 outcomes enter a two-disposition WO-012; sterilize adds nine endurance days at responder/coherence cost, quarantine spends four days while retaining responders; rupture remains terminal; prior crew and station consequences remain visible.
- **Risk rationale**: This changes internal deterministic gameplay and generated UI only, with no public API, schema, deployment, network, save-data, or external-consumer impact.

## Acceptance criteria

1. Purge, bypass, and isolation outcomes can open a distinct playable WO-012 phase; rupture cannot.
2. WO-012 carries Mina, Jae, integrity, coherence, and an outcome-specific deterministic endurance baseline.
3. WO-012 exposes exactly two irreversible, readable dispositions: sterilize (`+09d`) and quarantine (`-04d`).
4. Sterilization adds nine endurance days, costs fourteen coherence, and records lost responding signals.
5. Quarantine removes four endurance days, restores four bounded coherence, and records retained responders.
6. Purge makes the next order's source the impossible `MINA.SOLANO`; bypass and isolation use `VENN.CREDENTIAL`.
7. The campaign summary retains WO-011 crew and station consequences alongside WO-012's result.
8. Low coherence may add bounded signal interference to narrative text but may not obscure either action or cost.
9. Keyboard and visible-button paths both resolve the new choice, and rendered follow-up/summary frames fit the 1280×720 target without clipping.
10. Non-goals: no third repair, campaign map, procedural generation, save/load, inventory, randomness, WO-011 retcon, or definitive supernatural explanation.

## What changed

- `src/main.gd`
  - Adds follow-up and campaign-summary phases, deterministic carryover, two disposition controls, input handling, endurance/coherence consequences, and terminal rupture gating.
- `tests/verify.gd`
  - Exercises all three surviving entry routes, both dispositions, impossible-signer/carryover state, low-coherence interference, visible controls, keyboard input, and terminal rupture.
- `tests/capture.gd`
  - Captures the playable WO-012 decision and final campaign ledger.
- `README.md`
  - Documents the second decision and its keyboard controls.
- `CLAUDE.md`
  - Records the new architecture boundary and deterministic scenario invariants.

## How to verify

1. `godot --headless --path . --script res://tests/verify.gd`
   - Expected: exit 0 and `VERIFY PASS: 62 deterministic gameplay checks`.
2. `godot --headless --path . --editor --quit`
   - Expected: exit 0 with scripts registered and no parse/build error.
3. `godot --path . --resolution 1280x720 --script res://tests/capture.gd`
   - Expected: exit 0 and `CAPTURE PASS: boot, active, order-review, purge, follow-up, and campaign-summary frames written to res://captures`.
4. Inspect `captures/04-follow-up-decision.png` and `captures/05-campaign-summary.png`.
   - Expected: both choices and costs are legible in the decision frame; the summary ledger has no clipping and carries WO-011 state.
5. `git diff --check b69677ab73f99b1cd7a3f78ce70df37371e9207b..eb83bbc7fb52eea95d9b6bdc188acf0614d620f3`
   - Expected: exit 0 with no output.

## Author verification evidence

1. Tests: `godot --headless --path . --script res://tests/verify.gd` exited 0 at the implementation head: `VERIFY PASS: 62 deterministic gameplay checks`.
2. Build/lint: `godot --headless --path . --editor --quit` exited 0 and registered `main.gd`, `capture.gd`, and `verify.gd` without errors. Serena diagnostics for `src/main.gd` at warning-or-higher returned `{}`.
3. Clean status: after the implementation commit, `git status --short --branch` exited 0 with only `## feature/m3-wo012-disposition`.
4. Self-review: reviewed the full `main..HEAD` diff end to end; `git diff --check main..HEAD` exited 0 with no output.
5. Scope: `git diff --name-only main..HEAD` listed only `CLAUDE.md`, `README.md`, `src/main.gd`, `tests/capture.gd`, and `tests/verify.gd`. Godot-generated `project.godot` churn was explicitly removed.
6. Authorship: `git show -s --format=%an%n%ae%n%B HEAD` reported `yiangwow`, `<removed>`, and no `Co-Authored-By` trailer.
7. Project docs: `README.md` and the mandatory `CLAUDE.md` were updated in the implementation commit. No `ADR.md`, `docs/adr/`, `CONTRIBUTING.md`, services, ports, or deployment workflow exist; no ADR is needed for this bounded Level 1 extension.
8. Cycle allocation: immediate numbered directories were `001-aux4-godot-slice` and `002-m2-inspectable-work-order`; `003-m3-wo012-disposition` was created without collision.

## Known limitations / open questions

- The follow-up is intentionally one deterministic consequence rather than a general campaign/save system.
- Render captures are ignored local evidence and are not included in the implementation diff.
- This repository uses a local bare remote, so there is no PR or hosted CI to inspect.
