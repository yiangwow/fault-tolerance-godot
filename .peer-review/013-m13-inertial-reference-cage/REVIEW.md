# Review: M13 Inertial Reference Cage
- **Reviewer**: Claude
- **Verdict**: APPROVE

## Verification performed

Both requested SHAs exist and are correctly ordered; the branch tip is the `REQUEST.md` docs commit only, so the reviewed range is intact:

```
$ git cat-file -t 936618638097f2f74696f5958445c466a819d710 && git cat-file -t 301e80ec7e73e23ea02436cbd471f6ccbcaef848
commit
commit
$ git merge-base --is-ancestor 9366186... 301e80e... && echo yes ; git merge-base --is-ancestor 301e80e... HEAD && echo yes
yes
yes
$ git rev-parse HEAD origin/feature/m13-inertial-reference-cage
5c7b44060b4e2b7a977cbce759aac25b939241af
5c7b44060b4e2b7a977cbce759aac25b939241af
$ git log --oneline -2
5c7b440 docs: request M13 peer review
301e80e feat: add inertial reference cage
```

Head re-verified immediately before writing this review: implementation head `301e80ec7e73e23ea02436cbd471f6ccbcaef848` unchanged, branch tip `5c7b44060b4e2b7a977cbce759aac25b939241af`, working tree clean apart from this untracked `REVIEW.md`.

PR state (`gh pr view 9`): `state=OPEN`, `headRefName=feature/m13-inertial-reference-cage`, `baseRefName=main`, `statusCheckRollup=null` (no CI configured — matches the author's stated limitation).

Scope of the reviewed diff — exactly the seven declared files, no drive-by paths:

```
$ git diff --name-status 9366186..301e80e
M CLAUDE.md
M README.md
A src/gyro_display.gd
A src/gyro_display.gd.uid
M src/main.gd
M tests/capture.gd
M tests/verify.gd
 7 files changed, 1232 insertions(+), 43 deletions(-)
$ git log --format='%an|%ae|%b' -1 301e80e
yiangwow|<removed>|      (no Co-Authored-By trailer)
```

Risk Level 1 checks, all run by me on the handed-off worktree (implementation files identical to `301e80e`; only `.peer-review/.../REQUEST.md` differs from the head):

```
$ godot --headless --path . --editor --quit
… update_script_paths_documentation / loading_editor_layout: end
IMPORT EXIT: 0                       # no parse or import errors

$ godot --headless --path . --script res://tests/verify.gd
VERIFY PASS: 264 deterministic gameplay checks
VERIFY EXIT: 0

$ godot --path . --resolution 1280x720 --script res://tests/capture.gd
CAPTURE PASS: … clock-walkback, duplex-splicer, and inertial-cage frames written to res://captures
CAPTURE EXIT: 0                      # only the known V-Sync warning

$ git diff --check 9366186..301e80e
diff --check exit: 0                 # no output
```

Independent probe (13 additional assertions I wrote myself, run against a throwaway copy of the project at `/tmp/m13probe` so the handed-off worktree stayed clean; scratch copy deleted afterwards). 12 passed; the single failure was a defect in my own harness, not in the code — `restart_shift()` calls `get_tree().reload_current_scene()`, which cannot work in a `--script` SceneTree (`ERROR: Parameter "current_scene" is null`), so that path is unverifiable this way and I have listed it under "What I did NOT check":

- `rotate_gyro`/`latch_gyro`/`_finish_gyro` invoked while `phase == SPLICER` change no phase, log line, integrity, or coherence — confirms AC3/AC8 guards (`src/main.gd:4034`, `4081`, `4141`).
- One rejected index followed by the seven-move route still finishes clean with `pins == 1`, `settle == 2`, 4 load events, `+4` integrity, `-3` coherence — AC4/AC5 hold across a mixed path.
- `open_gyro_cage()` and `open_next_order()` at `GYRO_SUMMARY` are inert (AC9).
- Bounds: from `integrity=98/coherence=2` a clean close clamps to `100/0`; from `coherence=3` a slip clamps to `0` (AC6).
- Boundary case AC7 reproduced from the other side: parked exactly on a mid-cage datum with `settle == 0`, the phase stays open, the latch is accepted, and the *next* ring's unreachable datum is what slips the cage — one latch, one load event, degraded.
- Clean summary keeps `gyro_ring_index == 4` with `gyro_latches == [0,1,2,3]`.

Focus/keyboard interaction verified graphically (I suspected a focused rotate button would swallow `Space`; it does not):

```
M13 entry focus (ring0 off datum): system:reserve
M13 off-datum SPACE -> angle0 0->0 settle 9->9 pins 2->1     # latch attempt, not a rotation
M13 on-datum focus: action
M13 on-datum SPACE -> latches=[0] angle0=2
```

So the CLAUDE.md invariant "`Space` latches the active ring" holds even when a rotate button holds focus. No finding.

Read-through: `src/gyro_display.gd` is presentation-only — no game state is written, and `set_gyro_state` deep-copies every incoming array (`src/gyro_display.gd:49-52`), so the `GYRO_TARGET_ANGLES` constant and the live `gyro_angles`/`gyro_latches` cannot be aliased (AC11). Frames `23-gyro-active.png`, `24-gyro-index-rejected.png`, `25-gyro-ledger.png` inspected at native 1280×720 and zoomed; all four ring pointers, all four ICE datum markers, the ledger, readout, and violet load trace are correct and legible. `CLAUDE.md` and `README.md` accurately describe the new invariants and shortcuts (AC13).

## Findings

### [MINOR-1] Slipped-cage ledger prints the printed datums under a "FINAL DATUMS" heading
- File: `src/main.gd:4452`
- Problem: `_gyro_summary_ledger()` hard-codes `"FINAL DATUMS    02 / 04 / 05 / 00"` for both outcomes. On a clean close that string happens to equal the achieved ring state; on a slip it does not, and the heading reads as final achieved state.
- Evidence: probe run — after latching ring 0 and slipping on ring 1 with zero settle, `gyro_angles == [2, 5, 2, 7]` while the rendered ledger contains:
  ```
  FINAL DATUMS    02 / 04 / 05 / 00
  LATCHED         OUT / 01 OF 04
  SETTLE          00 / 09 REMAIN
  ```
  A player reading the slipped ledger is told the cage's final datums are `2/4/5/0` when rings 1–3 are actually at `5/2/7`.
- Suggestion: either rename the line (e.g. `PRINTED DATUMS`) or emit `gyro_angles` alongside the targets.

### [MINOR-2] `gyro_load_events` records timestamped recorder lines that are never displayed
- File: `src/main.gd:4103` (constant at `src/main.gd:91-96`)
- Problem: each correct latch appends `GYRO_LOAD_LINES[ring]` (e.g. `"19:14:02 / HAB-A LOAD ACCEPTED / OPERATOR ZERO"`), but every consumer reads only `gyro_load_events.size()` — `_gyro_load_line()` at `src/main.gd:4431-4432` rebuilds its output from `GYRO_LOAD_NAMES` instead, and the summary/reveal/forecast all use the count.
- Evidence: `grep -n "GYRO_LOAD_LINES" src/main.gd` yields only the declaration, the append, and no read site; the only other reference is the assertion `game.gyro_load_events == game.GYRO_LOAD_LINES` in `tests/verify.gd:1340`. The clean ledger frame `captures/25-gyro-ledger.png` shows `HAB LOAD BUS 04 / 04 / HAB-A>MED-2>AUX-4>HAB-C` — no timestamp reaches the player. The hard-wired-recorder timestamps that the CLAUDE.md invariant leans on are recorded state a player can never see.
- Suggestion: surface the lines in the summary ledger or the shift record, or store the ring index and drop the unused strings.

### [MINOR-3] Completed cage readout reports the latched final ring as "SEEKING"
- File: `src/gyro_display.gd:193`
- Problem: at `GYRO_SUMMARY` after a clean close, `ring_index == 4`, so `_has_latch(4)` is false and `clampi(4 + 1, 1, 4)` is `4` — the readout renders `RING 4  SEEKING` in amber for a ring that is in fact latched. The display stays visible in the summary phase (`src/main.gd:4213`: `display_active := phase in [Phase.GYRO, Phase.GYRO_SUMMARY]`).
- Evidence: cropped and upscaled `captures/25-gyro-ledger.png` at (30,480)-(330,540) shows `SETTLE 02` / `RING 4  SEEKING` behind the outcome overlay; probe confirms `gyro_ring_index == 4 and 4 not in gyro_latches` at clean completion. Impact is limited because the outcome overlay dims and partially covers the panel.
- Suggestion: clamp `_has_latch` lookup to `mini(ring_index, 3)`, or render `CAGE ZEROED` when `ring_index == 4`.

### [NIT-1] Outer ring and tooth labels collide with the readout and load-trace boxes at 1280×720
- File: `src/gyro_display.gd:141-150`, `186-192`
- Problem: with `outer_radius = min(0.34·w, 0.38·h)`, the outermost amber arc passes through the `SETTLE / INDEX PINS` readout box and behind the violet load-trace box, and its bottom tooth label `4` is drawn over the readout border. Additionally, all four rings label their eight teeth, producing radial runs of repeated digits (`6 6 6 6`, `2 2 2`) between rings.
- Evidence: `captures/23-gyro-active.png` region (30,180)-(410,470) upscaled. Everything remains readable, so this does not fail AC11 — noted only as a polish item.

## What I did NOT check

- **`restart_shift()` from inside WO-019.** It calls `get_tree().reload_current_scene()` (`src/main.gd:4556-4557`), which errors in a `--script` SceneTree, so I could not exercise the real in-game restart path. I verified the equivalent via `_reset_model()` only, as the repo's own suite does (`tests/verify.gd:1288-1300`). The AC9 "restores the station map" claim rests on my reading of the `_refresh_splicer` → `_refresh_gyro` ordering in `_refresh_all` (`src/main.gd:4805`), where `_set_splice_display_visible` sets `station_map.visible = not active` (`src/main.gd:3881`) and `_set_gyro_display_visible(false)` deliberately does not touch it (`src/main.gd:4327-4338`).
- **Any interactive play session.** All input was driven through direct method calls, `_unhandled_key_input`, `emit_signal("pressed")`, and one graphical `root.push_input` probe. I did not play the campaign by hand from boot to WO-019.
- **Resolutions other than 1280×720** and any window/stretch scaling behaviour of `GyroDisplay`, matching the author's stated limitation.
- **Exhaustive M13 route enumeration.** I covered the shortest route, one-pin-then-clean, two-bad-latch slip, settle-exhaustion slip, and both zero-settle boundary directions. I did not enumerate all reachable rotation sequences over the 8⁴ detent space.
- **CI.** `statusCheckRollup` is `null` — there are no configured checks on PR #9, so no CI evidence exists to confirm or contradict. Local import, verify, and capture are the only executable gates.
- **Godot 4.4.x versions other than 4.4.1.stable.mono** (the build on this machine) and platforms other than Linux/WSL2 with the GL Compatibility renderer.
- **`captures/` contents as committed artifacts** — the directory is gitignored; I regenerated the three M13 frames myself rather than trusting the author's copies. A stale `24-gyro-index-slip.png` from an earlier local run is present in my checkout and is not produced by the reviewed code.
## Round 2

- **Reviewer**: Claude
- **New implementation head**: `e3efc5f01d26cb30a3f73344507c959a1046d2c8`
- **Verdict**: REQUEST_CHANGES

## Verification performed

**Branch-tip claim and PR state.** The branch tip carries exactly one commit after the new implementation head, and it touches only `.peer-review/`:

```
$ git log --oneline -5
2fd5875 docs: respond to M13 review findings
e3efc5f fix: address M13 review findings
40d9b2d docs: record M13 peer review
5c7b440 docs: request M13 peer review
301e80e feat: add inertial reference cage

$ git diff --name-status e3efc5f..HEAD
A	.peer-review/013-m13-inertial-reference-cage/RESPONSE.md

$ git diff --stat e3efc5f..HEAD -- src tests project.godot README.md CLAUDE.md main.tscn assets
(no output — implementation files in the worktree are identical to e3efc5f)
```

Claim verified. `gh pr view 9`: `state=OPEN`, `mergedAt=null`, `isDraft=false`, `statusCheckRollup=null` (still no configured CI). Remote `origin/feature/m13-inertial-reference-cage` = `2fd5875382b5003367f81c19e6c65010fdf72f73` = local HEAD; working tree clean. Head re-verified immediately before writing this section.

**Implementation delta reviewed** — `301e80e..e3efc5f`, three implementation files (the other two paths in that range are the round-1 `REQUEST.md`/`REVIEW.md` docs commits):

```
$ git diff --stat 301e80e..e3efc5f
 .peer-review/.../REQUEST.md   | 125 +++++
 .peer-review/.../REVIEW.md    | 124 ++++
 src/gyro_display.gd           |  12 +-
 src/main.gd                   |  20 +-
 tests/verify.gd               |  11 +-
$ git log --format='%an|%ae' -1 e3efc5f
yiangwow|<removed>          (no Co-Authored-By trailer)
```

**Level 1 checks, all re-run by me on the handed-off worktree:**

```
$ godot --headless --path . --editor --quit
IMPORT EXIT: 0                       # 0 lines matching parse error|SCRIPT ERROR|Failed to load

$ godot --headless --path . --script res://tests/verify.gd
VERIFY PASS: 264 deterministic gameplay checks
VERIFY EXIT: 0                       # 0 FAIL lines

$ godot --path . --resolution 1280x720 --script res://tests/capture.gd
CAPTURE PASS: … clock-walkback, duplex-splicer, and inertial-cage frames written to res://captures
CAPTURE EXIT: 0                      # only the known V-Sync warning

$ git diff --check 301e80e..e3efc5f
diff --check exit: 0                 # no output
```

**Independent A/B probe.** I extracted both `301e80e` and `HEAD` with `git archive` into throwaway trees under `/tmp` (handed-off worktree left untouched; both scratch trees deleted afterwards), imported each, and ran the same self-written probe that walks the campaign to `GYRO_SUMMARY` and dumps `outcome_ledger` geometry plus per-line visibility. Post-delta, all three M13 outcome paths:

```
=== M13 CLEAN SUMMARY ===        (also SLIP 0-load and SLIP 1-load — identical geometry)
  rect_size=(800.0, 120.0) min=(0.0, 120.0) fit=false scroll=false
  line_count=10 visible_line_count=8
   [VIS]     SOURCE RECORD   SEALED REEL / UNDERPRINT MATCH
   [VIS]     PRINTED DATUMS  02 / 04 / 05 / 00
   [VIS]     FINAL ANGLES    02 / 04 / 05 / 00
   [VIS]     LATCHED         OUT>ROL>PIT>ROT / 04 OF 04
   [VIS]     INDEX PINS      02 / 02 REMAIN
   [VIS]     SETTLE          02 / 09 REMAIN
   [VIS]     HAB LOAD BUS    04 / 04 / HAB-A>MED-2>AUX-4>HAB-C / SOURCE UNCERTIFIED
   [VIS]     LOAD RECORDER   19:14:02 > 19:14:04 > 19:14:07 > 19:14:08
   [CLIPPED] INTEGRITY       072% -> 076%
   [CLIPPED] COHERENCE       083% -> 080%
```

Same probe at `301e80e`: `line_count=8 visible_line_count=8`, with `INTEGRITY`/`COHERENCE` both `[VIS]`. See MAJOR-1.

Regenerated `captures/25-gyro-ledger.png` inspected at native 1280×720 and cropped/upscaled against the `301e80e` render of the same frame; the pixels agree with the probe (old frame ends `HAB LOAD BUS / INTEGRITY 072% -> 076% / COHERENCE 083% -> 080%`, new frame ends `HAB LOAD BUS / LOAD RECORDER 19:14:02 > … > 19:14:08` with nothing after it). `captures/24-gyro-index-rejected.png` and `23-gyro-active.png` also regenerated and inspected.

## Resolution: [MINOR-1] Slipped-cage ledger prints the printed datums under a "FINAL DATUMS" heading

**Resolved.** `_gyro_summary_ledger()` now renders `PRINTED DATUMS  02 / 04 / 05 / 00` plus a separate `FINAL ANGLES` line fed by the new `_gyro_final_angle_line()` (`src/main.gd:4434-4438`, `4466-4467`), and both lines are within the visible region. My probe reproduces the exact case from the round-1 evidence — after one correct latch and two rejected indexes, `gyro_angles == [2, 5, 2, 7]` and the ledger reads `FINAL ANGLES    02 / 05 / 02 / 07` against `PRINTED DATUMS  02 / 04 / 05 / 00`. The zero-load slip reads `00 / 05 / 02 / 07`. The misleading heading is gone.

## Resolution: [MINOR-2] `gyro_load_events` records timestamped recorder lines that are never displayed

**Resolved.** `_gyro_load_time_line()` (`src/main.gd:4441-4447`) derives the visible `LOAD RECORDER` line from the stored `gyro_load_events` rather than from a parallel name table, so the strings are now read, not just written. Probe evidence across three routes: clean → `19:14:02 > 19:14:04 > 19:14:07 > 19:14:08`; one load → `19:14:02`; zero loads → `NONE RECORDED`. All three land on line 8 and are visible. Note that `LOAD RECORDER` is the last line that survives the clipping described in MAJOR-1 — this fix is one line away from being invisible itself.

## Resolution: [MINOR-3] Completed cage readout reports the latched final ring as "SEEKING"

**Resolved.** `_readout_state_line()` (`src/gyro_display.gd:196-203`) returns `CAGE ZEROED` when `ring_index >= targets.size()`, and the colour selection at `src/gyro_display.gd:193-194` now uses the same condition so the line renders in phosphor rather than amber. The empty-`targets` guard keeps the pre-entry state on the old `RING n` branch. Verified visually: `captures/25-gyro-ledger.png` region (30,485)-(340,540) upscaled ×4 reads `SETTLE 02 / CAGE ZEROED`, where the `301e80e` render of the identical frame read `RING 4  SEEKING`. Degraded closes keep `ring_index < 4` and still show `RING n  SEEKING`, which is accurate — that ring genuinely never latched.

## Resolution: [NIT-1] Outer ring and tooth labels collide with the readout and load-trace boxes at 1280×720

**Accepted deferral.** The deferral reasoning is sound and I do not press it. The `src/gyro_display.gd` delta is confined to `_draw_readout` and the new `_readout_state_line()`; `outer_radius`, the ring-geometry block, and the tooth-label loop (`src/gyro_display.gd:141-150`) are untouched, so the finding is neither worsened nor improved. Regenerated `23-gyro-active.png` and `24-gyro-index-rejected.png` remain legible at native 1280×720. Presentation polish for the owner's call.

## New findings

### [MAJOR-1] The MINOR-1/MINOR-2 fixes push `INTEGRITY` and `COHERENCE` out of the visible WO-019 ledger
- File: `src/main.gd:4462-4479` (label configured at `src/main.gd:1018-1025`)
- Problem: `outcome_ledger` is a `RichTextLabel` with `fit_content = false`, `scroll_active = false`, and `custom_minimum_size.y = 120`, which at font size 12 renders exactly 8 lines and silently truncates the rest. `_gyro_summary_ledger()` produced 8 lines at `301e80e`; adding `FINAL ANGLES` and `LOAD RECORDER` makes it 10. The two dropped lines are the last two — the milestone's `INTEGRITY 0xx% -> 0yy%` and `COHERENCE 0xx% -> 0yy%` accounting. WO-019 is now the only summary ledger in the campaign that does not show its own resource result, and it is the campaign's final ledger. There is no scrollbar and no visual cue that content was cut.
- Evidence: A/B probe on the two extracted trees (full output above). At `e3efc5f`, all three M13 outcome paths report `line_count=10 visible_line_count=8` with `INTEGRITY`/`COHERENCE` clipped; at `301e80e` the same three paths report `line_count=8 visible_line_count=8` with both lines visible. `rect_size=(800.0, 120.0)` equals `custom_minimum_size`, so the label does not expand — and because `custom_minimum_size.y` is a fixed pixel value under `canvas_items` stretch, the truncation is resolution-independent, not a 1280×720 artifact. Confirmed in pixels: `captures/25-gyro-ledger.png` region (230,270)-(1060,430) ends at `LOAD RECORDER`; the `301e80e` render of the identical capture path ends at `COHERENCE 083% -> 080%`. For comparison, `captures/22-splicer-ledger.png` (M12, 7 lines) still shows `INTEGRITY 069% -> 072%` / `COHERENCE 085% -> 083%`.
- Why the suite missed it: the four new assertions in `tests/verify.gd:1341-1344` and `1442-1444` all test `outcome_ledger.get_parsed_text()`, which returns clipped text as readily as visible text. `get_visible_line_count()` is what distinguishes them. The author's stated visual inspection of `25-gyro-ledger.png` also did not catch it, since the absence of two lines is easy to miss without the A/B.
- Suggestion: raise `custom_minimum_size.y` for this phase (10 lines needs ~150), or fold content back to 8 lines (e.g. merge `PRINTED DATUMS` / `FINAL ANGLES` onto one row, or append the recorder times to `HAB LOAD BUS`). Whichever you pick, an assertion on `outcome_ledger.get_visible_line_count() >= outcome_ledger.get_line_count()` at the M13 summary would make this class of regression detectable — and would be worth applying to the other summary phases too.

No other new finding. The `tests/verify.gd` delta only tightens existing `_expect` calls (assertion count unchanged at 264, all passing), `_gyro_final_angle_line()` and `_gyro_load_time_line()` are pure read-only formatters over already-deterministic state, and `_readout_state_line()` writes no game state.

## What I did NOT check

- **Whether MAJOR-1 affects earlier milestones.** I measured line counts only for the M13 ledger and confirmed M12's 7-line ledger renders fully. `_maintenance_summary_ledger`, `_service_summary_ledger`, and `_walkback_summary_ledger` delegate to helpers, so I did not establish their true rendered line counts; I only observed that their capture frames look complete. Any pre-existing clipping there is outside this delta's scope.
- **Everything covered by round 1's "What I did NOT check" that this delta does not touch**, which still stands: `restart_shift()`'s real `reload_current_scene()` path, interactive play from boot, resolutions other than 1280×720, exhaustive enumeration of the 8⁴ detent space, and non-4.4.1 Godot builds / non-Linux platforms.
- **Re-verification of round-1 acceptance criteria unrelated to the delta.** I re-ran the full suite and capture, but I did not repeat round 1's targeted probes for AC3/AC4/AC5/AC7/AC8/AC9 guard behaviour, since `src/main.gd`'s state machine is untouched by this delta (the only `main.gd` change is two new formatter functions and the ledger string).
- **CI.** `statusCheckRollup` is still `null` on PR #9 — no checks exist, so no CI evidence confirms or contradicts anything here.
- **`captures/` as committed artifacts.** Gitignored; I regenerated every frame I cite from both trees myself. The stale `24-gyro-index-slip.png` from an earlier local run is still present in this checkout and is not produced by the reviewed code.
