# Review: M10 Reactive Service Run
- **Reviewer**: Claude
- **Verdict**: APPROVE

## Verification performed

- `git fetch origin && git cat-file -t 84ae961... / 33ee098...` — both pinned SHAs exist as commits. `gh pr view 6 --json state,headRefName,baseRefName` — PR private archive PR #6 is `OPEN`, head `feature/m10-service-run`, base `main`.
- `git log 84ae961..33ee098` — exactly one commit (`33ee098 feat: add reactive service run`), author the owner's git identity, no `Co-Authored-By` trailer. `git diff --stat` — 6 files, 911 insertions / 30 deletions, matching the REQUEST.md "What changed" list exactly (no drive-by changes).
- `git diff --name-only 33ee098..8b287f9` (branch tip) — only `.peer-review/010-m10-service-run/REQUEST.md`, so the working checkout at the tip is code-identical to the implementation head; checks below ran against it.
- Full end-to-end read of the reviewed diff: `src/main.gd`, `src/station_map.gd`, `tests/verify.gd`, `tests/capture.gd`, `README.md`, `CLAUDE.md`. Confirmed against the acceptance criteria: entry gate `open_service_run()` requires `Phase.MAINTENANCE_SUMMARY`; overhaul priority follows `MAINTENANCE_SYSTEMS := ["loop", "reserve", "carrier"]` (src/main.gd:29) with LOOP-C fallback; `_service_projection` implements +2-capped-at-4 / −1-floored-at-0; first-zero losses post once via the `service_failures.has(key)` guard with exact penalties (loop −4 integrity, reserve −1 endurance, carrier −3 coherence, all `maxi(0, ...)`-bounded); `service_carrier_silent` is set only behind `_watch_has_survivor()` and touches no historical crew/roster/watch state; shared mouse buttons dispatch through phase-guarded `_on_maintenance_system_pressed` / `_on_maintenance_action_pressed`; all post-completion paths (direct call, keyboard, button signal) are inert behind phase guards. Console refresh ordering (`_refresh_maintenance()` then `_refresh_service()` in `_refresh_all`) cannot leave the service console in a stale M9 state.
- `godot --headless --path . --editor --quit` (Godot 4.4.1.stable.mono) — exit 0, no parse/import errors.
- `godot --headless --path . --script res://tests/verify.gd` — exit 0, `VERIFY PASS: 215 deterministic gameplay checks`. The new `_verify_service_run` suite independently covers the entry gate, history preservation, invalid/full-selection rejection, keyboard and shared-button paths, +2/−1 arithmetic, all three exact bounded losses, one-time loss posting after repair-and-re-zero, carrier silence with and without a historical survivor, low-coherence control availability, post-completion inertness, and `_reset_model` cleanup.
- `godot --path . --resolution 1280x720 --script res://tests/capture.gd` — exit 0, `CAPTURE PASS` (known V-Sync warning only). Visually inspected `captures/14-service-run-active.png`, `15-service-carrier-silence.png`, `16-service-ledger.png` at 1280×720: M9 scar mark and `M9 SCARS C-L` line render; carrier overhauled at 04/04 with `AT LIMIT / ACTION REJECTS`; transfer preview shows all three projected conditions; frame 15 shows the posted carrier loss (coherence 089→086, `CARRIER / SILENT`) and the at-limit no-op button; frame 16 shows the full ledger with the `COMMAND TIMESTAMPS MATCH SERVICE WEAR / PHYSICAL TIMEBASE DISPUTED / CAUSE UNRESOLVED` correlation line.
- `git diff --check 84ae961..33ee098` — exit 0, no output.
- Cycle allocation: `.peer-review/` contains `001`–`009`; `010-m10-service-run` is the correct next number.
- `gh pr checks 6` — "no checks reported"; the repository has no CI configured, consistent with prior cycles.
- Immediately before writing this review: re-fetched; `origin/feature/m10-service-run` = `8b287f9`, whose parent is `33ee098` (implementation head unchanged), PR #6 still `OPEN`.

## Findings

### [NIT-1] Scar-free fallback copy still claims "M9 SCAR RETAINED"
- File: src/main.gd:2483
- Problem: `open_service_run()` always sets `service_notice` to `"%s OVERHAULED / M9 SCAR RETAINED"`, including the LOOP-C fallback path where no M9 failure exists and the ledger simultaneously reports `M9 SCARS NONE`.
- Evidence: The fallback branch of `_service_overhaul_key()` returns `"loop"` with `service_scars` empty; the notice string is unconditional. Reachability caveat: M9's arithmetic (start sum 9, wear 12, repairs 6, and the ≥7-sum requirement to survive pulse three) guarantees at least one contained failure, so this state is only observable through direct mutation, as the new verify test does with `maintenance_failures.clear()`.
- Suggestion: Branch the notice on `service_scars.is_empty()` (e.g. "NO M9 SCAR RECORDED").

### [NIT-2] Selection label shows the selected route's own first-zero cost
- File: src/main.gd:2696
- Problem: `maintenance_selection_label` renders `FIRST ZERO / %s` with `_service_failure_effect(service_selected)` — the loss for the route the action can only raise — while the routes actually at risk are the two unselected ones.
- Evidence: In `captures/14-service-run-active.png`, with LOOP-C selected, the label reads `FIRST ZERO / -04 INTEGRITY` although the projected transaction is `L-C 3>4 / N-R 3>2 / C-L 4>3`. The authoritative per-route risk flags live in `_service_projection_line`, which correctly marks any transfer-induced first zero, so acceptance criterion 4 is still met.
- Suggestion: Either label it as the selected route's reference cost or show the effects flagged in the projection.

## What I did NOT check

- No interactive windowed playthrough with a real keyboard/mouse; input paths were verified only through synthesized `InputEventKey` events and `emit_signal("pressed")` in the headless suite.
- Resolutions and aspect ratios other than 1280×720 (the REQUEST.md flags this as a known limitation; Godot stretch behavior was not exercised).
- Godot versions other than 4.4.1.stable.mono on this WSL2/Mesa D3D12 environment; the renderer warning path on other platforms.
- M1–M9 behavior beyond what the 215-check regression suite and the three prior-milestone capture frames already cover; I did not manually replay earlier campaign branches.
- Exhaustive enumeration of all M9 stroke-allocation strategies; the claim that a scar-free WO-015 completion is unreachable rests on the arithmetic argument in NIT-1, not brute-force search, and the LOOP-C fallback was exercised only via direct state mutation.
- Keyboard input after WO-016 completion was verified by code inspection of the `SERVICE_SUMMARY` branch of `_unhandled_key_input` (only `KEY_R` handled), not by a dedicated test assertion.
- No CI exists on this repository, so no automated pipeline corroborates the local runs.
## Round 2
- **Reviewer**: Claude
- **Verdict**: APPROVE
- **New implementation head reviewed**: 709b8052eaa9749c91f0bb3333f583079ca33e4c

## Verification performed (Round 2)

- `git fetch origin && gh pr view 6 --json state,headRefName,baseRefName` — `{"baseRefName":"main","headRefName":"feature/m10-service-run","state":"OPEN"}`; PR #6 remains OPEN.
- `git cat-file -t 709b8052eaa9749c91f0bb3333f583079ca33e4c` — `commit`; branch tip is `cce74dcc236ae29974abbdf8a33e9ca00824e2fe`, whose parent chain is `cce74dc → 709b805 → 1bc2ced → 8b287f9 → 33ee098`.
- `git diff --name-only 709b805..origin/feature/m10-service-run` — only `.peer-review/010-m10-service-run/RESPONSE.md`; every commit after the new implementation head changes peer-review files exclusively, so the working checkout at the tip is code-identical to 709b805 and all checks below ran against it. Re-confirmed immediately before writing this section (tip still `cce74dc`, PR still OPEN).
- `git log 33ee098..709b805` — three commits, all authored the owner's git identity, no `Co-Authored-By` trailers; the only implementation commit is `709b805 fix: clarify M10 service copy`. `git diff --name-only 33ee098..709b805` on non-peer-review paths — exactly `src/main.gd` and `tests/verify.gd` (+14/−5), matching RESPONSE.md's claimed scope with no drive-by changes.
- Full read of the implementation delta: `open_service_run()` now selects the notice suffix on `service_scars.is_empty()` ("NO M9 SCAR RECORDED" vs "M9 SCAR RETAINED"); the selection label template changed from `FIRST ZERO / %s` to `SELECTED ROUTE LOSS / %s`; `tests/verify.gd` gained matching assertions on both strings.
- `git status --porcelain=v1` — clean, exit 0.
- `godot --headless --path . --editor --quit` (Godot 4.4.1.stable.mono) — exit 0, no script parse/import errors (only the environment's known editor-settings and V-Sync noise).
- `godot --headless --path . --script res://tests/verify.gd` — exit 0, `VERIFY PASS: 215 deterministic gameplay checks`.
- `godot --path . --resolution 1280x720 --script res://tests/capture.gd` — exit 0, `CAPTURE PASS` (known V-Sync/Mesa D3D12 warnings only); regenerated `captures/14-service-run-active.png`, `15-service-carrier-silence.png`, `16-service-ledger.png`.
- Visual inspection of `captures/14-service-run-active.png` at 1280×720: the reference line renders as `SELECTED ROUTE LOSS / -04 INTEGRITY` beneath the authoritative `PROJECTED / L-C 3>4 / N-R 3>2 / C-L 4>3` line, unclipped; the notice reads `CARRIER LINK OVERHAULED / M9 SCAR RETAINED`, which is correct on this path because an M9 scar (`M9 SCARS C-L`) exists.
- `git diff --check 33ee098..709b805` — exit 0, no output.

## Resolution of Round 1 findings

### [NIT-1] Scar-free fallback copy still claims "M9 SCAR RETAINED" — RESOLVED (fixed in 709b805)
- Verified in the diff: the notice in `open_service_run()` (src/main.gd:2480–2492) now branches on `service_scars.is_empty()` and emits `NO M9 SCAR RECORDED` on the LOOP-C fallback path, exactly the suggested direction. The scar-free regression in `tests/verify.gd:1262–1266` now additionally asserts `"NO M9 SCAR RECORDED" in game.service_notice` and passes within the 215-check run I executed. The normal scarred path still reads `M9 SCAR RETAINED`, confirmed both in code and in the regenerated capture frame.

### [NIT-2] Selection label shows the selected route's own first-zero cost — RESOLVED (fixed in 709b805)
- Verified in the diff: `_refresh_service()` (src/main.gd:2700–2706) now labels the line `SELECTED ROUTE LOSS / %s`, honestly presenting it as the selected route's reference cost rather than an imminent-first-zero claim; the transfer-induced first-zero risk remains flagged per route by the unchanged, authoritative `_service_projection_line`. The label regression in `tests/verify.gd:1210–1214` asserts the new string and passes; the regenerated 1280×720 frame shows the full copy without clipping, matching RESPONSE.md's evidence.

No new findings in the Round 2 delta. The fix commit's message (`fix: clarify M10 service copy`) does not reference the finding IDs as Section 7 suggests, but RESPONSE.md maps both IDs to the commit explicitly; not worth a finding.

## What I did NOT check

- Everything listed in Round 1's "What I did NOT check" still stands (no interactive windowed playthrough, no non-1280×720 resolutions, no other Godot versions/platforms, no manual replay of M1–M9 branches, no brute-force M9 stroke-allocation search, no CI on this repository).
- The NIT-1 fallback string was exercised only through the verify suite's direct `maintenance_failures.clear()` mutation, since a scar-free WO-015 completion remains unreachable through play per the Round 1 arithmetic argument; no capture frame shows it.
- I did not re-inspect `captures/15` and `16` pixel-by-pixel this round; the Round 2 delta does not touch the states they render, and `CAPTURE PASS` regenerated them without error.
- PR #6 mergeability/CI: `gh pr checks` still reports no checks (repository has no CI), so no automated pipeline corroborates the local runs.
