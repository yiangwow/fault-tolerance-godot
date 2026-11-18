# Review Request: M6 sealed audit packet
- **Author**: Codex
- **Repository**: https://github.com/yiangwow/fault-tolerance-godot
- **Branch**: feature/m6-sealed-audit-packet
- **Base**: main @ 38dfacbc3c82965cafadde20ea47ac0d67834367
- **Implementation head**: 3f4c5870ecc328fbfa3c04396f4f65951b9f3083
- **PR**: private archive PR #2 — OPEN
- **Risk level**: 1
- **Scope**: Add one optional, non-mutating sealed audit packet to the existing WO-013 final ledger. It may expose a forensic counter-ledger after the campaign is already resolved, but must not add an order, change an outcome, consume time or resources, persist new state, or resolve whether its author is an AI, hallucination, crew member, or other manifestation.
- **Source of truth**: The user's original brief is a pixelated systems-horror game about an engineer enduring a failing space station while the crew and operator lose coherence, with the possibility that an uncertain rogue manifestation has lured them into making conditions worse. The user then directed continued Godot development. This milestone's bounded decision is to deepen that premise through optional post-outcome evidence: an order timestamp predating the first physical fault, derived campaign facts, and an explicitly unresolved author.
- **Risk rationale**: This changes internal deterministic UI/state, test coverage, capture automation, and project documentation only. It adds no public API, save schema, service, deployment behavior, security boundary, plugin, network call, or external-consumer contract.

## Acceptance criteria

1. Every legal WO-013 result reaches the existing final ledger with an available but closed `[A] AUDIT SEALED PACKET` action.
2. Keyboard `A` and the visible audit action open the same packet, only from `FINAL_SUMMARY`, and repeated requests are idempotent.
3. The packet establishes the bounded chronology `Shift 06 / 18:41:09` packet write before `Shift 07 / 19:04:11` first fault, then concludes `ORDER PREDATES FIRST FAULT / AUTHOR UNRESOLVED`.
4. Packet text is state-derived: carrier and responder trace reflect the actual WO-013 route, while the coherence line distinguishes high-coherence mechanical-watch verification from low-coherence ambiguity.
5. Opening or re-opening the packet changes no phase, elapsed time, WO-013 time, endurance, integrity, coherence, carried Mina/Jae state, responder result, repair choice, or repair outcome.
6. Reset reseals and hides the packet until another campaign reaches a final ledger.
7. The packet does not claim the physical fault was unreal and does not canonically identify a rogue AI, supernatural actor, hallucination, or human author.
8. The closed and opened final-ledger states remain legible and unclipped at 1280×720 using the established terminal grammar, with the opened packet distinguished by one bounded red-border black-box panel.
9. Existing M1–M5 routes, values, controls, and outcomes remain unchanged.
10. Non-goals: no new work order, persistence layer, save/load, resource, timed cost, random event, audio system, imported plugin, network behavior, or definitive explanation.

## What changed

- `src/main.gd`
  - Adds sealed-packet state, final-summary gating, keyboard/button input, state-derived forensic copy, reset behavior, and the bounded final-ledger panel.
- `tests/verify.gd`
  - Adds public-route checks for final-outcome availability, phase gating, keyboard/button parity, idempotence, derived content, total non-mutation, reset behavior, and legacy invariants.
- `tests/capture.gd`
  - Adds an opened sealed-audit-packet frame reached through legal public actions.
- `README.md` and `CLAUDE.md`
  - Document the optional final audit action, control, rendering grammar, and deterministic non-mutation contract.

## How to verify

1. `godot --headless --path . --editor --quit`
   - Expected: exit 0 and all scripts register without parser or resource errors.
2. `godot --headless --path . --script res://tests/verify.gd`
   - Expected: exit 0 and `VERIFY PASS: 130 deterministic gameplay checks`.
3. `godot --path . --resolution 1280x720 --script res://tests/capture.gd`
   - Expected: exit 0 and ten milestone frames, including the closed campaign ledger and opened sealed audit packet, are written to `res://captures`.
4. Inspect `captures/07-campaign-ledger.png` and `captures/08-sealed-audit-packet.png`.
   - Expected: the optional action is visible while closed; the opened counter-ledger, timestamps, state-derived lines, unresolved-author conclusion, and footer fit at 1280×720 without clipping.
5. `git diff --check 38dfacbc3c82965cafadde20ea47ac0d67834367..3f4c5870ecc328fbfa3c04396f4f65951b9f3083`
   - Expected: exit 0 with no output.

## Author verification evidence

1. Tests: `godot --headless --path . --script res://tests/verify.gd` exited 0 with `VERIFY PASS: 130 deterministic gameplay checks`.
2. Build/import: `godot --headless --path . --editor --quit` exited 0 and registered the project scripts without parser or resource errors.
3. Captures: `godot --path . --resolution 1280x720 --script res://tests/capture.gd` regenerated all ten frames. `captures/07-campaign-ledger.png` and `captures/08-sealed-audit-packet.png` were visually inspected at original resolution; an initially clipped conclusion was corrected by increasing the packet panel and label heights, then regenerated and re-inspected.
4. Diagnostics: Serena warning-or-higher diagnostics returned `{}` for `src/main.gd`, `tests/verify.gd`, `tests/capture.gd`, and unchanged `src/station_map.gd`.
5. Clean status: after the implementation commit, `git status --short --branch` exited 0 with only `## feature/m6-sealed-audit-packet`.
6. Self-review: reviewed the complete `main..HEAD` implementation diff end to end. Packet guards, keyboard/button parity, reset behavior, content derivation, and the full non-mutation snapshot are exercised through public actions.
7. Scope: `git diff --name-only main..HEAD` lists only `CLAUDE.md`, `README.md`, `src/main.gd`, `tests/capture.gd`, and `tests/verify.gd`. Godot-generated `project.godot` churn was explicitly removed.
8. Authorship: `git show -s --format=%an%n%ae%n%B HEAD` reported `yiangwow`, `<removed>`, and no `Co-Authored-By` trailer.
9. Project docs: mandatory `CLAUDE.md` and `README.md` were updated. No service, port, deployment workflow, public API, schema, or new architectural boundary changed; no ADR is needed for this bounded Level 1 addition.
10. Delivery: implementation head `3f4c5870ecc328fbfa3c04396f4f65951b9f3083` is pushed to both configured remotes. GitHub PR #2 is OPEN, non-draft, MERGEABLE, and reports a CLEAN merge state with exactly the five intended files and one implementation commit.
11. CI: no workflow or required checks are configured; `gh pr checks 2` reports no checks on `main`. Local import, deterministic verification, capture generation, visual inspection, and static diagnostics therefore provide the available verification evidence.
12. Cycle allocation: immediate numbered directories were `001-aux4-godot-slice` through `005-m5-aux4-seal-brace`; `006-m6-sealed-audit-packet` was created after confirming no collision.

## Known limitations / open questions

- The packet is a single authored counter-ledger, not a reusable evidence/archive framework.
- No separate low-coherence screenshot is included; both coherence branches and their exact copy are covered deterministically.
- The packet does not persist across reset and intentionally has no resource or outcome effect.
- Rendering was verified at the 1280×720 target on Linux/WSL2 with Godot 4.4.1, not across other platforms, renderers, or window sizes.
- No CI workflow exists on the private GitHub repository.
