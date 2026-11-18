# Review: M11 Local Clock Walkback
- **Reviewer**: Claude
- **Verdict**: APPROVE

## Verification performed

Reviewed exactly `9eecb36e5eb67e41303751c2668cc6dbc5a33c64..8f01d97094f2b0e123a9ab9626f9a19936d894d5` (6 files, +1011/−21, matching the What-changed list; no drive-by changes).

- State check: `git fetch origin` clean; branch `feature/m11-clock-walkback` tracked and up to date; PR private archive PR #7 state `OPEN`; base SHA `9eecb36e...` and implementation head `8f01d97...` both resolve to commits; base equals `origin/main`. Re-verified immediately before writing this review: `git rev-parse origin/feature/m11-clock-walkback` = `d9e7bb087a346a8f23ddc6f89250eb6b6f735743`, and `git diff --name-only 8f01d97...d9e7bb0` lists only `.peer-review/011-m11-clock-walkback/REQUEST.md` — the implementation head is unchanged and the only later commit is the review-request doc, so the request is not stale.
- Authorship: `git log --format='%an <%ae>' -1 8f01d97` → the owner's git identity (author and committer); commit message `feat: add local clock walkback` contains no `Co-Authored-By` trailer.
- `godot --headless --path . --editor --quit` → exit 0, no parse/import errors (Godot 4.4.1.stable).
- `godot --headless --path . --script res://tests/verify.gd` → exit 0, `VERIFY PASS: 235 deterministic gameplay checks`.
- `godot --path . --resolution 1280x720 --script res://tests/capture.gd` → exit 0, `CAPTURE PASS: ... maintenance and service and clock-walkback frames written to res://captures` (known V-Sync warning only).
- `git diff --check 9eecb36...8f01d97` → exit 0, no output.
- Inspected `captures/17-walkback-active.png`, `18-walkback-mid-route.png`, `19-walkback-three-witness-ledger.png` at 1280×720: room graph, red damaged BRIDGE–CORE corridor with X mark, unread/read witness markers, pulsing current-location ring, numbered amber breadcrumbs (COR>MED>AUX in frame 18), and the three-witness ledger showing badge arrivals 18:40:58/18:41:09/18:41:17 preceding CORE departure 19:04:23 with INT 063→069 (+6) and COH 089→085 (−4).
- Full read of the diff against all 12 acceptance criteria. Traced by hand: graph symmetry of `WALKBACK_GRAPH` against the six specified edges; sorted-key edge→route mapping (`core|med`→reserve, `airlock|aux`→loop, `bridge|core`→carrier) at `src/main.gd:26-30`; hazard dedup via one union pass over `service_scars`/`service_failures` at `src/main.gd` (`open_walkback`), giving a single surcharge for overlapping M9+M10 history; seal arithmetic of the canonical three-witness path (9→0 crossing one hazard) and the recovery path ([2,0,0,0,1,0] → exposed at −8/−6), both matching the test expectations that pass; entry gate `phase != Phase.SERVICE_SUMMARY → return`; inertness guards on `move_walkback`/`apply_walkback_action`/`_on_maintenance_*` and the `WALKBACK_SUMMARY` key handler (R only); bounded clamps `mini(100,...)`/`maxi(0,...)` on every resource write; `_reset_model` clearing all nine walkback fields and ending in `_refresh_all()`, whose `_refresh_walkback` else-branch hides the map overlay. Confirmed `service_scars` is populated from M9 failures at WO-016 entry (`src/main.gd:2510-2513`), so the M9-scar surcharge plumbing is real, and that walkback code only reads (never writes) Mina/Jae/responder/carrier/roster state. The auto-recovery check `_walkback_has_available_action()` after each accepted move/read correctly fires exactly when no read, affordable move, or valid CORE lock remains, and the `walkback_seal < 1` branch inside `apply_walkback_action` is unreachable defensive cover. Low coherence touches only the `maintenance_carrier_label` copy — no control, cost, or graph path reads `coherence`.

## Findings

### [NIT-1] Revisited rooms overdraw earlier breadcrumb numbers
- File: src/station_map.gd:180-191 (post-change `_draw_walkback_overlay` path loop)
- Problem: Each waypoint draws a filled circle then its index at the room's fixed point, so when a path revisits a room (e.g. the recovery route re-entering AUX-4, or any return to CORE) the newest number is painted over the older one and only the latest visit index is legible on the map.
- Evidence: Path points come from `rooms[room_key]` with no per-visit offset; the recovery test path `core→bridge→airlock→aux→med→aux` revisits `aux`. The textual `TETHER PATH` line remains complete, so this is cosmetic only.
- Suggestion: Optional — offset repeat visits by a few pixels or render only the latest index deliberately.

### [NIT-2] Two-witness ledger timestamps already imply the arrival ordering the copy calls unresolved
- File: src/main.gd (post-change `_walkback_summary_ledger` / `_finish_walkback` two-witness copy)
- Problem: The two-witness summary prints both read clock arrivals (18:40:58 / 18:41:09) and `CORE DEPARTURE 19:04:23`, so the raw ledger data shows arrival preceding departure even though the reveal line says the arrival sequence is unresolved via the unread third witness.
- Evidence: `_walkback_summary_ledger` appends the CORE-departure line unconditionally; the two-witness body reads "The unread witness leaves the arrival sequence unresolved."
- Suggestion: Take it or leave it — defensible as "two clocks are not conclusive," but withholding the departure line (or the read timestamps) in the two-witness ending would make the withheld conclusion airtight.

## What I did NOT check

- Recovery triggered while standing at CORE with fewer than two witnesses and no affordable move — the tests exercise auto-recovery only away from CORE; the code path is the same `_finish_walkback(true)` call, but I did not execute that exact state.
- Non-1280×720 window sizes and aspect ratios (the request explicitly scopes visual checks to 1280×720; stretch behavior untested).
- A full interactive mouse playthrough of WO-017 in a windowed session — button behavior was verified via emitted `pressed` signals in the headless suite and code read, not by real pointer input.
- Godot versions other than 4.4.1.stable, and non-WSL2 platforms/renderers (capture ran on the GL Compatibility D3D12 Mesa stack with its known V-Sync warning).
- Long-run soak of `_process`-driven `queue_redraw()` in the new overlay (performance), and pixel-exact rendering beyond the three inspected captures.
- GitHub CI: none exists to check — the repository has no configured status checks (`statusCheckRollup` null), consistent with the request's stated delivery gates.
