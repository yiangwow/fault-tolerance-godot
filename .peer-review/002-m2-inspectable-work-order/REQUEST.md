# Review Request: M2 inspectable WO-011 operations

- **Author**: Codex
- **Repository**: `/home/unix/tmp/fault-tolerance-godot-origin.git` (local canonical bare remote)
- **Branch**: `feature/m2-inspectable-work-order`
- **Base**: `main` @ `6a581ee54867078794502b00160f702284cefa3e`
- **Implementation head**: `d531a15005dc7977a09737664655a8db50ac1198`
- **PR**: N/A — this is a local scratch prototype with no hosted forge
- **Risk level**: 1
- **Scope**: Add a no-time-cost, evidence-aware inspection view for WO-011's physical operations; this does not add a second scenario, campaign state, persistence, audio, or change any M1 outcome.
- **Source of truth**: User direction: “lets merge close m1 and lets start with m2”; bounded M2 decision: make the existing lethal work order inspectable before expanding the campaign.
- **Risk rationale**: Local gameplay UI and input logic with deterministic tests; no API, schema, security, deployment, service, or external-consumer impact.

## Acceptance criteria

1. During an active shift, the operator can open and close the WO-011 physical-operation review with its visible button and the `O` key.
2. The review exposes four ordered operations: open HX-2 bypass, seal AUX-4, suspend the occupancy interlock, and depressurize AUX-4; the final operation explicitly identifies fatality to an occupant.
3. Opening, reading, and closing the review changes no rupture time, integrity, coherence, evidence, support state, or outcome availability.
4. Camera or Mina evidence marks a live-occupancy conflict; provenance evidence identifies the VENN credential as `SIM/ADVERSARIAL`.
5. Purge, bypass, isolation, rupture, exact-deadline behavior, and all prior keyboard actions retain their deterministic M1 outcomes.
6. Headless verification covers both access paths, state neutrality, content, and evidence context; deterministic capture adds an expanded-order frame without clipping at 1280×720.
7. A second work order and wider campaign remain explicit non-goals.

## What changed

- `src/main.gd` — adds review UI/state, physical-operation content, evidence-aware warnings, button handling, and the `O` shortcut.
- `tests/verify.gd` — adds deterministic checks for state neutrality, both controls, content, and camera/Mina/provenance context.
- `tests/capture.gd` — adds the expanded-order acceptance frame.
- `README.md` — documents the player-facing interaction and shortcut.
- `CLAUDE.md` — records the component and no-time gameplay invariant.

## How to verify

Run from the repository root:

```sh
rtk godot --headless --path . --editor --quit
rtk godot --headless --path . --script res://tests/verify.gd
rtk godot --path . --resolution 1280x720 --script res://tests/capture.gd
rtk proxy git diff --check 6a581ee54867078794502b00160f702284cefa3e..d531a15005dc7977a09737664655a8db50ac1198
```

Expected:

- Editor import exits 0 with no parser or resource errors.
- Verification prints `VERIFY PASS: 46 deterministic gameplay checks`.
- Capture prints `CAPTURE PASS: boot, active, order-review, purge, and next-order frames written to res://captures`.
- Diff check exits 0 with no output.

## Author verification evidence

1. **Tests** — `rtk godot --headless --path . --script res://tests/verify.gd`; exit 0; `VERIFY PASS: 46 deterministic gameplay checks`.
2. **Build/import and diagnostics** — `rtk godot --headless --path . --editor --quit`; exit 0; project scan and editor load completed without parser/resource errors. Serena GDScript diagnostics for `src/main.gd`, `tests/verify.gd`, and `tests/capture.gd` returned `{}` at error/warning severity.
3. **Clean implementation state** — `rtk git status --porcelain=v1`; exit 0; no output before this request was written.
4. **End-to-end self-review** — reviewed the complete five-file raw diff. `rtk proxy git diff --check 6a581ee54867078794502b00160f702284cefa3e..d531a15005dc7977a09737664655a8db50ac1198`; exit 0; no output. Visually inspected both the closed active state and `captures/02b-work-order-review.png` at 1280×720; the sequence, warnings, evidence rail, and existing controls remain readable without clipping.
5. **Scope** — `rtk git diff --name-only 6a581ee54867078794502b00160f702284cefa3e..d531a15005dc7977a09737664655a8db50ac1198`; only the five source, test, and reference files listed under “What changed”.
6. **Authorship** — `rtk git show -s --format='%H%n%an <%ae>%n%B' d531a15005dc7977a09737664655a8db50ac1198`; the owner's git identity; no `Co-Authored-By` trailer.
7. **Project reference / architecture** — `README.md` and `CLAUDE.md` cover the new interaction and invariant. No ADR is needed because this extends the existing generated UI and deterministic state model without changing architecture, services, ports, persistence, or data contracts.
8. **Cycle allocation** — immediate `.peer-review/` children contained only `001-aux4-godot-slice`; highest prefix `001` plus one selected `002`, and `.peer-review/002-m2-inspectable-work-order/` was created without collision.

## Known limitations / open questions

- Mouse access is verified through the button's connected `pressed` signal and keyboard access through a constructed `InputEventKey`; physical hardware input was not exercised.
- Rendering was inspected at the project's target 1280×720 viewport, not other aspect ratios or Windows-native Godot.
- The review is deliberately informational: it does not add time cost, evidence, logs, persistence, or a second work order.
