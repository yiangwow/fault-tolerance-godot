# Review Request: M7 hands-on AUX-4 seal brace rig
- **Author**: Codex
- **Repository**: https://github.com/yiangwow/fault-tolerance-godot
- **Branch**: feature/m7-brace-rig
- **Base**: main @ ace34abb5bd7887a2b9d11c326a158e29fc9aba6
- **Implementation head**: 58aae5a7cc3e9d5fb33fb85619b3fc7daa378a58
- **PR**: private archive PR #3 — OPEN
- **Risk level**: 1
- **Scope**: Replace the player-facing one-click AUX-4 brace with one compact deterministic torque-balancing rig while preserving the existing one-minute completion cost and every M5–M6 route, resource, outcome, and ledger effect; do not add a phase, resource, random event, persistence, service, plugin, network behavior, or narrative answer.
- **Source of truth**: After playing was made available, the user asked whether the project contained something genuinely good to do, then directed work on the next milestone. The agreed response was to prioritize hands-on engineering over another lore or presentation layer. This milestone's fixed brief is: key/button `6` opens the existing T+06 field action without spending campaign time; `7` and `8` tension port/starboard shoes from zero to two under a one-detent shear interlock; `9` cross-locks only at two/two and invokes the existing one-minute brace completion.
- **Risk rationale**: This changes internal deterministic gameplay, generated Control UI, tests, captures, and project documentation only. It adds no public API, schema, service, deployment behavior, security boundary, plugin, network call, save format, or external-consumer contract.

## Acceptance criteria

1. Before the T+06 seal-deformation event, the brace rig cannot open, tension, lock, spend time, or alter state.
2. At T+06, the existing field-action panel discloses the local `+08` integrity effect, purge non-benefit, and that the one-minute cost occurs on lock.
3. Key/button `6` opens the rig without changing elapsed time, integrity, coherence, crew state, evidence, repair availability, or any outcome; repeated open requests are inert.
4. Port and starboard tension are monotonic integers from zero through two. An accepted tension step spends no campaign time or resource.
5. A side already leading by one detent cannot be advanced again; the rejected attempt changes no tension, time, integrity, or coherence, and the opposite shoe remains visibly actionable.
6. The cross-lock is unavailable until both shoes reach two/two. An early lock changes no brace state or campaign time.
7. Locking at two/two calls the existing completion path exactly once: it spends one normal WO-011 minute, applies normal integrity/coherence time cost, records the existing brace log/map state, and cannot repeat.
8. Top-row keyboard, numeric keypad, and visible mouse controls reach equivalent open, tension, and lock behavior.
9. Reset clears open/tension state. Abandoning a partial rig and committing a repair remains legal and carries no transient rig state into an outcome or later order.
10. Existing brace economics and campaign routes remain unchanged: purge and rupture baselines receive no buffer; bypass remains `43 -> 51`; isolation remains `52 -> 60`; exact-deadline, WO-012, WO-013, final-ledger, and sealed-packet behavior remain available.
11. The open-rig and completed-brace states fit the existing map-side field panel at 1280×720 without clipping, expose all controls/costs, and preserve the surrounding deck, crew, work-order, log, and decision regions.
12. Non-goals: no real-time ticking, failure penalty for an interlock rejection, randomized sequence, reusable minigame framework, new work order, new resource, persistence, audio, imported plugin, network behavior, or definitive rogue-AI/supernatural/hallucination explanation.

## What changed

- `src/main.gd`
  - Adds transient brace-rig state, compact port/starboard/lock controls, zero-cost open/tension actions, the one-detent shear interlock, two/two completion guard, keyboard/keypad input, outcome/reset cleanup, and state-derived control copy.
- `tests/verify.gd`
  - Covers pre-event rejection, zero-cost open/tension, early-lock rejection, skew interlock, top-row/keypad/mouse parity, one-minute completion, one-shot behavior, reset, abandonment, and all downstream M5–M6 invariants.
- `tests/capture.gd`
  - Adds an open-rig frame reached through legal player actions and updates completed-brace campaign paths to use the new rig.
- `README.md` and `CLAUDE.md`
  - Document the hands-on interaction, controls, architecture, and deterministic invariants.

## How to verify

1. `godot --headless --path . --editor --quit`
   - Expected: exit 0 and all scripts register without parser or resource errors.
2. `godot --headless --path . --script res://tests/verify.gd`
   - Expected: exit 0 and `VERIFY PASS: 141 deterministic gameplay checks`.
3. `godot --path . --resolution 1280x720 --script res://tests/capture.gd`
   - Expected: exit 0 and eleven milestone frames, including open-rig and completed-brace states, are written to `res://captures`.
4. Inspect `captures/02c-brace-rig.png` and `captures/02c-braced-inner-seal.png`.
   - Expected: the open rig shows port `1/2`, starboard `0/2`, explicit opposite-shoe guidance, disabled leading/lock controls, and no time spent; the completed state shows the existing braced map/ledger state at T+07. Neither frame clips at 1280×720.
5. `git diff --check ace34abb5bd7887a2b9d11c326a158e29fc9aba6..58aae5a7cc3e9d5fb33fb85619b3fc7daa378a58`
   - Expected: exit 0 with no output.

## Author verification evidence

1. Tests: after recording the pre-implementation failure (`Invalid access to property or key 'brace_rig_open'`), the final `godot --headless --path . --script res://tests/verify.gd` run exited 0 with `VERIFY PASS: 141 deterministic gameplay checks`.
2. Build/import: `godot --headless --path . --editor --quit` exited 0 and registered all project scripts without parser or resource errors.
3. Captures: `godot --path . --resolution 1280x720 --script res://tests/capture.gd` exited 0 with the expected capture summary. The open-rig and completed-brace PNGs were inspected at original 1280×720 resolution; controls, status, deck map, crew list, work order, log, and footer remained legible and unclipped.
4. Clean status: after the implementation commit, `git status --short --branch` exited 0 with only `## feature/m7-brace-rig`.
5. Self-review: reviewed the complete `main..HEAD` diff end to end. A first proposed M7 service-spine animation was rejected before commit because the WO-013 overlay obscured it and it did not materially improve play; that prototype is preserved only in a local stash and is absent from this branch.
6. Independent audit: a read-only explorer found no contract-blocking issue and identified only missing keypad coverage. Top-row, keypad, and mouse completion paths are now all asserted in the passing 141-check suite.
7. Scope: `git diff --name-only main..HEAD` lists only `CLAUDE.md`, `README.md`, `src/main.gd`, `tests/capture.gd`, and `tests/verify.gd`. `project.godot` and `src/station_map.gd` are unchanged.
8. Authorship: `git show -s --format=%an%n%ae%n%B HEAD` reported `yiangwow`, `<removed>`, and no `Co-Authored-By` trailer.
9. Project docs: mandatory `CLAUDE.md` and `README.md` were updated in the same commit. No service, port, deployment workflow, public API, schema, or architectural boundary changed; no ADR is needed for this bounded Level 1 interaction.
10. Delivery: implementation head `58aae5a7cc3e9d5fb33fb85619b3fc7daa378a58` is pushed to both configured remotes. GitHub PR #3 is OPEN, non-draft, MERGEABLE, and CLEAN with exactly the five intended files and one implementation commit.
11. CI: no workflow or required checks are configured (`statusCheckRollup: null`). Local import, deterministic verification, rendered capture generation, visual inspection, and the independent read-only audit provide the available verification evidence.
12. Cycle allocation: immediate numbered directories were `001-aux4-godot-slice` through `006-m6-sealed-audit-packet`; `007-m7-brace-rig` was created only after confirming no collision.

## Known limitations / open questions

- The rig is one authored maintenance interaction, not a reusable minigame framework.
- The shear interlock guides the player by disabling an unsafe leading step; rejected keyboard attempts have no campaign penalty.
- Tension is deterministic and discrete rather than analog, physics-based, or real-time.
- No audio, haptics, controller-specific bindings, or standalone Windows export is included in this milestone.
- Rendering was verified at the 1280×720 target on Linux/WSL2 with Godot 4.4.1, not across other platforms, renderers, display scales, or window sizes.
- No CI workflow exists on the private GitHub repository.
