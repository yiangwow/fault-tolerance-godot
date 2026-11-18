# Review: M14 Suspension Bus Breakout
- **Reviewer**: Claude
- **Verdict**: APPROVE

Reviewed base: `89ada04e75e20003343af2a891df87a2d15ae592`
Reviewed implementation head: `e524c9e1c99ef8ae943d2f6876e96c319885eb44`

## Verification performed

**SHA / branch / PR state (verified twice — once at review start, once immediately before writing this review):**

```
$ git cat-file -t 89ada04e75e20003343af2a891df87a2d15ae592 && git cat-file -t e524c9e1c99ef8ae943d2f6876e96c319885eb44
commit
commit
$ git merge-base --is-ancestor 89ada04... e524c9e...   # exit 0 — base is an ancestor of the head
$ git ls-remote git@github.com:yiangwow/fault-tolerance-godot.git refs/heads/feature/m14-suspension-bus-breakout refs/heads/main
17003c382da2f38c92f53bf2646edb722f6a9dc4  refs/heads/feature/m14-suspension-bus-breakout
89ada04e75e20003343af2a891df87a2d15ae592  refs/heads/main
$ gh pr view 10 --json state,baseRefName,headRefName,commits
{"base":"main","head":"feature/m14-suspension-bus-breakout",
 "heads":["e524c9e1c99ef8ae943d2f6876e96c319885eb44","17003c382da2f38c92f53bf2646edb722f6a9dc4"],
 "state":"OPEN"}
```

PR #10 is OPEN against `main`, contains the reviewed implementation head plus the
`REQUEST.md` docs commit `17003c3`. `git diff --name-status e524c9e..17003c3` shows exactly one
file: `.peer-review/014-m14-suspension-bus-breakout/REQUEST.md`, so the handed-off worktree
content is identical to the reviewed head for all implementation files. Base `main` is still at
the requested SHA. Request is well-formed; no PARTIAL condition applies.

**Authored range and diff hygiene:**

```
$ git diff --name-status 89ada04..e524c9e
M CLAUDE.md      M README.md      A src/bus_display.gd   A src/bus_display.gd.uid
M src/main.gd    M tests/capture.gd   M tests/verify.gd
7 files changed, 1031 insertions(+), 14 deletions(-)

$ git diff --check 89ada04..e524c9e       # exit 0, no output

$ git log --format='AN:%an AE:%ae CN:%cn CE:%ce B:[%b] TRAILERS:[%(trailers)]' 89ada04..e524c9e
AN:yiangwow AE:<removed> CN:yiangwow CE:<removed> B:[] TRAILERS:[]
```

I walked every `src/main.gd` hunk (`git diff -U0 ... | grep '^@@'` → 22 hunks). All are M14
additions or the two-line WO-019 → WO-020 chain extension in `_finish_gyro` (`src/main.gd:4244`,
`:4250`). No drive-by logic changes, no `Co-Authored-By`, correct authorship.

**Gates re-run independently in a clean throwaway clone checked out at `e524c9e` (not the
handed-off worktree), Godot 4.4.1.stable.mono:**

```
$ godot --headless --path . --editor --quit                       # exit 0, no parse/import errors
$ godot --headless --path . --script res://tests/verify.gd
VERIFY PASS: 279 deterministic gameplay checks                    # exit 0
$ godot --path . --resolution 1280x720 --script res://tests/capture.gd
CAPTURE PASS: ... inertial-cage, and bus-breakout frames written to res://captures   # exit 0
   (only the known "Could not set V-Sync mode" driver warning)
```

All three author-claimed results reproduce exactly, including the `279` check count.
`captures/26-bus-active.png`, `27-bus-arc-rejected.png`, `28-bus-ledger.png` were generated and
inspected at native 1280×720, plus zoomed crops of the readout and switch bank.

**Independent probe (temporary `tests/probe_review014.gd`, driven through the full M1→M13 chain,
deleted afterwards along with the clone — 21 checks, 0 failures).** I deliberately exercised
paths `tests/verify.gd` does *not* cover:

- Arc after **two** accepted proofs (verify.gd only covers zero-proof and one-proof arcs):
  phase `BUS_SUMMARY`, `bus_degraded` true, integrity unchanged (`076% -> 076%`), coherence
  `080% -> 074%` (exactly −6), ledger still 8 rows and truthful:
  ```
  PROOFS         PORT SPLIT>CENTER ISLAND / 02 OF 03
  ARC FUSES      00 / 02 REMAIN
  REJECTIONS     02
  LOAD LABELS    04 / PARTIAL ISOLATION / 02 PROOFS
  ```
  `FULL BREAKOUT` correctly absent — the copy does not over-claim (criterion 7).
- Resource clamping on clean close from `integrity=99, coherence=1` → `integrity==100`,
  `coherence==0` (criterion 5, bounds).
- Slipped-M13 entry (two wrong latches) → enters `BUS_BREAKOUT`, and the summary
  `SOURCE FRAME` line correctly reads `SLIPPED FRAME / LOAD ORDER PARTIAL` (criterion 1).
- Full clean run leaves `mina_state`, `wo013_responder_result`, `watch_roster_uses`,
  `service_scars`, `endurance_days`, and `gyro_load_events` byte-identical (criterion 8).
- Post-close `toggle_bus_bar`, and *direct* `_finish_bus_breakout(true)` / `_finish_bus_breakout(false)`
  calls from `BUS_SUMMARY`: coherence and bar state unchanged. The double-award guard at
  `src/main.gd:4640` holds even against direct method invocation (criterion 9).

**Code review of the state machine** (`src/main.gd:4544-4919`): entry is gated on
`Phase.GYRO_SUMMARY` only; the reject branch spends exactly one fuse and never advances
`bus_proof_index`; the accept branch appends exactly one event and never spends a fuse; the
degraded close is reachable only at `bus_fuses == 0` and the clean close only at
`bus_proof_index == 3`. Bar toggles are unbudgeted, so no unwinnable state exists. Log
sequence numbers (`bus_proof_index + bus_rejections`) increase monotonically across mixed
accept/reject runs — confirmed in `27-bus-arc-rejected.png`'s shift record.

**Presentation contract** (`src/bus_display.gd`): `set_bus_state` deep-copies both incoming
arrays (`:36`, `:39`), the module holds no reference to game state, and `_draw` no-ops when
inactive. Verified in `27-bus-arc-rejected.png` that after one accepted proof the violet load
trace spans **all three** switch rows including the visibly *open* port bar, and all four
conductor labels (HAB-A / MED-2 / AUX-4 / HAB-C) persist — criterion 12 holds. The eight-row
clean ledger in `28-bus-ledger.png` is fully visible with `INTEGRITY 076% -> 079%` and
`COHERENCE 080% -> 078%` both on screen — criterion 13 holds, and the new
`get_visible_line_count()` gate in `tests/capture.gd:437` is a real regression guard against the
M13 MAJOR-1 failure mode.

**Documentation:** the eleven new `CLAUDE.md` invariants (`:277-303`) each match the
implementation I read — topologies `O/C/C`, `O/C/O`, `O/O/O` correspond to
`BUS_BAR_TARGETS` at `src/main.gd:99-103`; two fuses to `BUS_FUSE_LIMIT`; ±3/−2 and 0/−6 to
`_finish_bus_breakout`. README key bindings match `_unhandled_key_input` (`src/main.gd:5698-5711`)
and `_on_maintenance_system_pressed` / `_on_maintenance_action_pressed` (`:2346`, `:2366`).

All 14 acceptance criteria verified. No BLOCKER or MAJOR found.

## Findings

### [MINOR-1] Proof-log `STAGE` line renders outside the readout rectangle at 1280×720
- File: `src/bus_display.gd:164`
- Problem: `draw_string(..., "STAGE %02d / 03", HORIZONTAL_ALIGNMENT_LEFT, -1, text_size + 1, ...)`
  passes width `-1` (unbounded) at the largest font size in the module, while the enclosing
  readout box is only `panel.size.x * 0.19` wide (`:157-159`). At the documented 1280×720 target
  the string needs roughly 94 px inside a ~64 px usable box, so `/ 03` renders *on top of and
  past* the violet readout border, onto the panel background.
- Evidence: `captures/26-bus-active.png` and `27-bus-arc-rejected.png`, region x≈300-410,
  y≈195-215. Zoomed crop shows the `03` glyphs straddling the box border on both frames. Every
  sibling string in the same box (`ACCEPTED`, `FUSES`, `REJECTED`) stays inside because they are
  shorter, so the defect is specific to this line. Acceptance criterion 11 asks for a
  "proof/fuse readout … at 1280x720"; the stage row is the one element that escapes it.
- Failure scenario: a player at the documented resolution sees the primary progress indicator
  bleeding through the instrument bezel on every M14 frame, in the same panel the M13 cycle was
  already re-worked to keep contained.
- Suggestion: either shorten to `STAGE %02d/03` and drop the `+ 1` size bump, or pass
  `readout.size.x - 10.0` as the width so it clips consistently with the rest of the box.

### [MINOR-2] Three readout/switch strings are truncated mid-word by their own width argument
- File: `src/bus_display.gd:186` (also `:184` and `:134`)
- Problem: these three calls pass a width narrower than the rendered string, so Godot clips them
  mid-token rather than wrapping or shortening:
  - `:186` `"NO ACCEPTED LOAD"` → renders `NO ACCEPTED LO`
  - `:184` `"LOAD PERSISTS / GAP CROSSED"` → renders `LOAD PERSISTS`, and its
    `trace.end.y + 9.0` baseline puts it directly on the readout's bottom border
  - `:134` `"TARGET %s"` → renders `TARGET OPE` for the `OPEN` case, and at the starboard
    switch it also collides with the violet load trace drawn 5 px above the same row
- Evidence: `captures/26-bus-active.png` (`NO ACCEPTED LO` at x≈322,y≈307; `TARGET OPE` at
  x≈88,y≈255) and `captures/27-bus-arc-rejected.png` (`LOAD PERSISTS` overlapping the box border
  at y≈462; `TARGET OPE` overlapped by the trace at y≈380).
- Failure scenario: at the only supported resolution the recorder's own summary of its central
  premise ("the load persists across the crossed gap") is cut before the meaningful half, and
  the per-switch target annotation reads as a partial word. No gameplay information is lost —
  the same target is stated unambiguously in the button text (`TARGET OPEN`), the
  `PRINTED TARGET` ledger row, and the selection label — which is why this is MINOR and not
  MAJOR, but it is a legibility regression against criterion 11.
- Suggestion: shorten the literals (`NO LOAD`, `LOAD PERSISTS`, `TGT OPEN`) rather than widening
  the boxes, keeping the M13 geometry untouched.

### [MINOR-3] `bus_proofs` stores timestamped recorder lines that are never displayed; the ledger re-derives names by position
- File: `src/main.gd:4866-4872` (populated at `:4622`)
- Problem: `inject_bus_proof` appends `BUS_PROOF_LINES[completed_proof]` — full recorder events
  including timestamps and the `LOAD LABELS 04` claim (`"19:14:12 / PORT SPLIT / LOAD LABELS 04"`,
  `src/main.gd:105-109`). `_bus_proof_line()` then ignores those stored strings and rebuilds the
  display from `BUS_PROOF_NAMES[index]`, keyed on array *position* rather than on the recorded
  event. The timestamps never reach any UI surface.
- Evidence: `28-bus-ledger.png` shows `PROOFS  PORT SPLIT>CENTER ISLAND>FULL BREAKOUT / 03 OF 03`
  — no timestamp anywhere in the frame. Grepping the file confirms `BUS_PROOF_LINES` is read only
  at `:4622`; its content is asserted only by `tests/verify.gd`. This is the same defect pattern
  the author accepted and fixed as `[MINOR-2]` in cycle 013, where the M13 ledger was changed to
  derive a `LOAD RECORDER` row from the actual stored `gyro_load_events`; M14 reverts to the
  pre-fix pattern.
- Failure scenario: the recorder-trace timestamps — the evidentiary core of the WO-020 premise,
  and the thing the M13 ledger now surfaces — are recorded but unobservable to the player. The
  positional lookup is also a latent divergence: any future change permitting out-of-order or
  partial-order acceptance would silently label proofs with the wrong names, since
  `_bus_proof_line` never consults what was actually recorded.
- Suggestion: derive the ledger row from `bus_proofs` (as `_gyro_summary_ledger` now does for
  M13), or drop the unused timestamps from `BUS_PROOF_LINES` so the stored record matches what
  the game claims to have recorded.

### [NIT-1] Stray two-space indent introduced into the CLAUDE.md overview paragraph
- File: `CLAUDE.md:15-20`
- Problem: the diff re-indents the tail of the Overview paragraph by two spaces while lines 5-14
  of the same paragraph remain flush-left, producing a ragged block. It is unrelated to WO-020
  content and is the only formatting change in the file outside the new invariants.
- Evidence: `git diff 89ada04..e524c9e -- CLAUDE.md` shows five otherwise-unchanged lines
  re-emitted with a leading `  `; `CLAUDE.md:14` (`... then walk the`) is flush-left while
  `:15` (`  physical deck on a suit tether ...`) is not.
- Failure scenario: cosmetic only — Markdown still renders one paragraph. Flagged because
  checklist item 5 claims the diff contains only the stated scope.

## What I did NOT check

- **Real interactive play.** Every M14 path I exercised was driven through public methods and
  synthesized `InputEventKey` objects. I never played the game with a keyboard or mouse. Focus
  behavior in particular is unverified: `_focus_bus_control` (`src/main.gd:4819`) uses
  `call_deferred("grab_focus")`, and I did not confirm that tab order, focus rings, or the
  focus handoff from a toggled bar button to the inject button behave correctly for a real
  player, nor that the shared maintenance buttons re-label without a visible flicker.
- **Resolutions other than 1280×720.** All captures and all clipping findings are at the single
  documented target. `bus_display.gd` derives every dimension from `panel.size`, so the
  MINOR-1/MINOR-2 clipping will change character at other sizes — possibly worse at smaller
  viewports (`text_size` clamps at a floor of 8, so text stops shrinking while boxes keep
  shrinking) — but I did not test any other resolution, window resize, or the `canvas_items`
  stretch behavior under a non-16:9 aspect.
- **Other renderers/platforms.** GL Compatibility on Mesa 23.2.1 under WSL2 only. No Vulkan, no
  Windows/macOS, no headless-vs-windowed rendering differences. `draw_polyline(..., antialiased=true)`
  at `bus_display.gd:183` and the `Time.get_ticks_msec()` pulse are driver-sensitive; I did not
  assess them elsewhere.
- **Frame-timing dependence.** `_process` redraws every frame while `bus_active` (`:46-48`),
  which stays true through `BUS_SUMMARY`. I confirmed this affects no recorded state, but did not
  profile it or check for pulse-phase artifacts in capture timing.
- **M14 entered from non-default M1-M12 campaign shapes.** My probe and `tests/verify.gd` both
  reach M14 through `isolate → quarantine → handoff/vent` with a specific watch/rotation/service
  policy. I did not enumerate purge or bypass routes, sterilization, roster-degraded carriers,
  M10 carrier silence, or M11 tether-recovery into M14. I read the code and found no read of
  those variables inside the M14 block other than `gyro_degraded` in `_bus_source_line`, but I
  did not execute those combinations.
- **Low-coherence rendering below 50.** I verified the copy switch and control preservation via
  the existing deterministic assertion and by reading `_draw_impossible_trace` (`:141-152`), but
  produced **no capture** of the low-coherence violet trace. The faint second trace line at
  `:149` is visually unverified.
- **Degraded/welded final frame.** `captures/27-bus-arc-rejected.png` shows one rejection with a
  fuse remaining, not the welded two-rejection close. There is no committed or generated capture
  of the degraded M14 outcome overlay, so its layout is verified only by ledger text, not
  visually.
- **CI.** GitHub reports `statusCheckRollup: null` for PR #10 — no checks are configured, so I
  could not confirm any CI gate. Per protocol §3.7 that remains the author's and the owner's call at
  merge time; local import, verify, capture, and this review are the only gates that ran.
- **Merge cleanliness.** `gh` reported `mergeable: UNKNOWN` / `mergeStateStatus: UNKNOWN` on both
  polls, so I did not confirm that PR #10 merges without conflict. `main` is unmoved since the
  base SHA, so a conflict is unlikely, but it is unverified.
- **`src/bus_display.gd.uid`.** I confirmed the file exists and the project imports cleanly at
  `e524c9e`; I did not verify the UID value is globally unique against every other resource UID
  in the project.
## Round 2

- **Reviewer**: Claude
- **Responding to**: `RESPONSE.md` @ `2a98caf41f22af35dc0f971784091b5cd15e5cdb`
- **New implementation head**: `6c89ed80f2ba1e7c728db3d09bc1686913264eff`
- **Reviewed delta**: `e524c9e1c99ef8ae943d2f6876e96c319885eb44..6c89ed80f2ba1e7c728db3d09bc1686913264eff`
- **Verdict**: APPROVE

The round-1 APPROVE was correctly self-invalidated by the implementation commit `6c89ed8`. I
re-reviewed the delta and every disposition independently. All four findings are genuinely fixed;
no new BLOCKER or MAJOR exists.

### Verification performed

**Head / branch / PR state (checked at review start and again immediately before writing this
section; unchanged between the two polls):**

```
$ git rev-parse HEAD                       -> 2a98caf41f22af35dc0f971784091b5cd15e5cdb
$ git log --format=%H -1 6c89ed8...        -> 6c89ed80f2ba1e7c728db3d09bc1686913264eff
$ git ls-remote origin refs/heads/feature/m14-suspension-bus-breakout
2a98caf41f22af35dc0f971784091b5cd15e5cdb   refs/heads/feature/m14-suspension-bus-breakout
$ git ls-remote origin refs/heads/main
89ada04e75e20003343af2a891df87a2d15ae592   (base unmoved)
$ gh pr view 10 --json state,baseRefName   -> OPEN -> main
$ git status --porcelain                   -> empty (worktree untouched by me)
```

Branch tip `2a98caf` adds only `RESPONSE.md` on top of the implementation head
(`git diff --name-status 6c89ed8 2a98caf` → `A .peer-review/014-.../RESPONSE.md`), so the tree I
tested is byte-identical to `6c89ed8` for every implementation file. I also confirmed the author
did **not** edit my round-1 review or the request:
`git diff --name-only 5e51a6a 2a98caf -- .../REVIEW.md` and
`git diff --name-only 17003c3 2a98caf -- .../REQUEST.md` are both empty.

**Delta scope and hygiene:**

```
$ git show --stat 6c89ed8
CLAUDE.md | 15 +++++++-------   src/bus_display.gd | 8 ++++----
src/main.gd | 25 ++++++++++++++++++----   tests/verify.gd | 5 +++++
4 files changed, 38 insertions(+), 15 deletions(-)

$ git diff --check 89ada04..6c89ed8        # exit 0, no output
$ git log --format='AN:%an AE:%ae CN:%cn CE:%ce TRAILERS:[%(trailers)]' e524c9e..2a98caf
AN:yiangwow AE:<removed> CN:yiangwow CE:<removed> TRAILERS:[]   (x4)
```

No drive-by changes; no `Co-Authored-By`; correct authorship on all four commits. Cumulative
base→new-head file set is the same nine files (seven implementation + the two review docs).

**Gates re-run in a fresh throwaway clone checked out at `6c89ed8`** (not the handed-off
worktree), Godot `4.4.1.stable.mono`:

```
$ godot --headless --path . --editor --quit          # exit 0; 0 lines matching ERROR:/parse error
$ godot --headless --path . --script res://tests/verify.gd
VERIFY PASS: 279 deterministic gameplay checks       # exit 0, 0 FAIL lines
$ godot --path . --resolution 1280x720 --script res://tests/capture.gd
CAPTURE PASS: ... inertial-cage, and bus-breakout frames written to res://captures   # exit 0
   (only the known "Could not set V-Sync mode" driver warning; no "clips" push_error)
```

The `279` count is unchanged because the three MINOR-3 assertions were folded into existing
`_expect` conjuncts rather than added as separate checks — I confirmed by reading the diff, not by
trusting the count.

**Independent probe (temporary `tests/probe_r014.gd` + a windowed `probe_r014_vis.gd`, driven
through the full M1→M13 chain, 24 checks / 0 failures, both deleted with the clone).** I re-derived
every claim in `RESPONSE.md` rather than reading its evidence:

```
--- degraded after 2 ACCEPTED proofs then 2 rejections ---
SOURCE FRAME    STABLE FRAME / LOAD ORDER 04
FINAL BUS      O/C/O
PROOFS         PORT SPLIT>CENTER ISLAND / 02 OF 03
PROOF RECORDER 19:14:12 > 19:14:15
ARC FUSES      00 / 02 REMAIN / REJECTED 02
LOAD LABELS    04 / PARTIAL ISOLATION / 02 PROOFS
INTEGRITY      076% -> 076%
COHERENCE      080% -> 074%          <- 8 rows, integrity untouched, exactly -6 coherence

--- zero-proof degraded ---
PROOFS         NONE / 03 REQUIRED
PROOF RECORDER NONE RECORDED         <- no "19:14" substring anywhere in the ledger

--- clean ---
PROOF RECORDER 19:14:12 > 19:14:15 > 19:14:19
ARC FUSES      02 / 02 REMAIN / REJECTED 00
INTEGRITY      076% -> 079%   COHERENCE 080% -> 078%
```

Also confirmed by probe: a *survived* rejection then a clean close renders
`ARC FUSES 01 / 02 REMAIN / REJECTED 01` (the merged row is not hard-coded); slipped-M13 entry
still reaches `BUS_BREAKOUT` and closes with `SLIPPED FRAME / LOAD ORDER PARTIAL` plus the full
three-timestamp recorder row; low coherence (`coherence = 20`) leaves the eight rows, the
timestamps, and the `+3 / -2` arithmetic identical; `integrity=99, coherence=1` clamps to
`100 / 0`; `_reset_model()` clears every `bus_*` field; and post-close `toggle_bus_bar`,
`inject_bus_proof`, *direct* `_finish_bus_breakout(true)` and `_finish_bus_breakout(false)`, and
synthesized `KEY_1`/`KEY_SPACE` events leave integrity, coherence, bars, fuses, rejections, proofs,
phase, **and the rendered ledger text** bit-identical. A 15-field snapshot of M1–M13 state
(`mina_state`, `jae_supported`, `wo013_responder_result`, `watch_roster_uses`, `watch_actions`,
`endurance_days`, `maintenance_conditions/_failures`, `service_conditions/_failures`,
`walkback_path`, `walkback_witnesses`, `splice_choices`, `gyro_load_events`, `gyro_degraded`) is
unchanged across both a clean and a degraded M14 run.

**Ledger visibility (the specific thing I was asked to confirm):** rendered at 1280×720 via the
same `get_visible_line_count()` / `get_line_count()` comparison the capture gate uses —

```
degraded-2proof: visible=8 rendered=8
degraded-0proof: visible=8 rendered=8
```

and `captures/28-bus-ledger.png` (regenerated, inspected at native resolution) shows all eight
clean rows on screen, ending in `INTEGRITY 076% -> 079%` / `COHERENCE 080% -> 078%`. The added
`PROOF RECORDER` row did not push the ledger past its box because `ARC FUSES` and `REJECTIONS` were
merged into one row — row count is still exactly 8 in all three outcome shapes, and the new
recorder row (45 chars) is narrower than the existing `PROOFS` row (63 chars), so it is not the
width-binding line.

### Resolution of round-1 findings

**[MINOR-1] `STAGE` line renders outside the readout rectangle — RESOLVED (fixed).**
`src/bus_display.gd:164` now reads `"STAGE %02d/03"` with width `readout.size.x - 10.0` and the
module's normal `text_size` (the `+ 1` bump is gone). A 4× zoomed crop of the regenerated
`captures/26-bus-active.png` at x≈310-410, y≈180-300 shows `STAGE 01/03` complete and entirely
inside the violet bezel, vertically aligned with `PROOF LOG` / `ACCEPTED 00` / `FUSES 02` /
`REJECTED 00`. No glyph touches the border.

**[MINOR-2] Three strings truncated mid-word — RESOLVED (fixed), with one cosmetic residual.**
Verified in regenerated captures at native 1280×720:
- `:186` now `"NO LOAD"` — renders complete inside the trace box (`26-bus-active.png`).
- `:184` now `"LOAD PERSISTS"` at baseline `readout.end.y - 6.0` — renders complete and clear of
  the bottom border (crop of `27-bus-arc-rejected.png`, x 315-395 / y 420-470).
- `:134` now `"TGT %s"` with `CLS`/`OPEN` — renders `TGT OPEN` complete on both the port switch in
  `26-bus-active.png` and the starboard switch in `27-bus-arc-rejected.png`.

Residual, **not** a new finding: on the starboard switch the violet load trace still passes through
the lower third of the `TGT OPEN` glyphs (`_draw_impossible_trace` draws at `switch_y - 5.0`, the
ghost label at `left.y - 7.0`). I zoomed it 8×; the text is legible and unambiguous, and the same
target is stated three other places. The truncation the finding was about is gone; the overlap was
a secondary observation in the original text and the author's fix did not need to move it.

The legend still reads `TARGET OPEN` (`src/main.gd:638`) while the map ghost now reads `TGT OPEN`.
I checked this deliberately — the legend is the glossary for the abbreviation, so the pair reads
correctly rather than inconsistently. Not a finding.

**[MINOR-3] Stored timestamped proof events never displayed; ledger re-derived names by position —
RESOLVED (fixed).** I read the implementation rather than the response: `_bus_proof_line()`
(`src/main.gd:4866-4872`) now iterates `bus_proofs` and extracts field 1 of each **stored** event
via `_bus_proof_event_field`; the new `_bus_proof_time_line()` (`:4875-4881`) extracts field 0 from
the same stored events; `BUS_PROOF_NAMES[index]` positional lookup is gone from both. The only
remaining `BUS_PROOF_NAMES` reads are in the live-phase notice/log and button copy, keyed on
`bus_proof_index` at the moment of acceptance — that *is* the event being recorded, so it is
correct. The timestamps now reach a UI surface: `PROOF RECORDER` in `_bus_summary_ledger()`
(`:4928`), confirmed visible in `28-bus-ledger.png`. The latent divergence the finding described is
closed — under a hypothetical out-of-order acceptance the ledger would now name what was actually
recorded. Row budget preserved by merging `REJECTIONS` into the `ARC FUSES` row; I verified the
merged row is computed from `[bus_fuses, bus_rejections]` and reports correctly in the 0-, 1-, and
2-rejection cases. Truthfulness holds in all three shapes: two accepted proofs report
`19:14:12 > 19:14:15` with no `19:14:19` and no `FULL BREAKOUT`; zero proofs report
`NONE RECORDED`. This matches the pattern the author accepted for M13's `LOAD RECORDER` row.

**[NIT-1] Stray two-space indent in the CLAUDE.md overview — RESOLVED (fixed).** `CLAUDE.md:5-20`
is uniformly flush-left; I dumped the first four characters of every line in the paragraph to
confirm none begins with whitespace. The remaining indented lines in the file (`:26+`) are
list-item continuations and are correct. The accompanying invariant edit (`:292-294`, "whose
timestamps remain visible in the final ledger") is a new documentation claim, and I verified it is
true rather than aspirational — the timestamps are on screen in `28-bus-ledger.png`.

### New findings

None. I looked specifically for defects the fix could have introduced — ledger row-count
regressions from the added `PROOF RECORDER` row, arithmetic damage from merging the fuse and
rejection rows, a broken `+`/`%` precedence in the multi-line format expression at
`src/main.gd:4929-4930`, over-claiming copy in the partial-proof degraded ledger, and clipping of
the shortened strings — and found none. The `"UNREADABLE"` branch in `_bus_proof_event_field`
(`:4887`) is unreachable given the three well-formed `BUS_PROOF_LINES` constants; it is defensive,
not dead-wrong, and I am not raising it.

### What I did NOT check

- **Anything outside the delta.** I did not re-verify the round-1 conclusions about the M14 state
  machine, entry gating, fuse budget, `BusDisplay` deep-copy contract, or the fourteen acceptance
  criteria beyond the ledger/render surfaces the fix touched. Those rest on round 1.
- **Real interactive play.** Unchanged from round 1: every path was driven through public methods
  and synthesized `InputEventKey` objects. Focus order, focus rings, and the `call_deferred`
  focus handoff (`src/main.gd:4819`) remain unverified with a real keyboard or mouse.
- **Resolutions other than 1280×720.** All three fixed strings are now bounded by widths derived
  from `panel.size`, so their clipping behavior at other viewport sizes is different but untested.
  `text_size` still floors at 8 while boxes keep shrinking, so smaller viewports may reintroduce
  MINOR-1/MINOR-2-class clipping. No resize, no non-16:9 aspect, no `canvas_items` stretch test.
- **`TGT CLS` rendering.** The `target_closed == true` ghost variant is not reachable in any of the
  three committed captures (stage targets never require closing an open bar in the capture path).
  It is a shorter string than `TGT OPEN` in the same box, so I judged it safe by inspection rather
  than by rendering it.
- **Low-coherence rendering below 50.** I verified via probe that the copy switch, controls, row
  count, timestamps, and arithmetic are unaffected at `coherence = 20`, but the outcome ledger is
  hidden during the active phase, so I produced **no** rendered low-coherence M14 summary frame.
  The faint second violet trace line at `bus_display.gd:149` is still visually unverified.
- **Other renderers/platforms.** GL Compatibility on Mesa 23.2.1 under WSL2 only. No Vulkan, no
  Windows/macOS. `draw_polyline(..., antialiased=true)` and the `Time.get_ticks_msec()` pulse are
  driver-sensitive and untested elsewhere.
- **M14 entered from non-default M1–M12 campaign shapes.** My probe reaches M14 through
  `isolate → quarantine → handoff` with one fixed watch/rotation/service/walkback/splice policy
  (plus the slipped-gyro variant). I did not execute purge, bypass, sterilization,
  roster-degraded carriers, M10 carrier silence, or M11 tether recovery into M14. The delta touches
  only ledger-string derivation, which reads no such variable, but I did not run those combinations.
- **CI.** `gh pr view 10 --json statusCheckRollup` still returns `null` — no checks are configured,
  so no CI gate could be confirmed. Per protocol §3.7 that is the author's and the owner's call at merge
  time; local import, verify, capture, my probe, and this review are the only gates that ran.
- **Merge cleanliness.** `gh` reported `mergeable: UNKNOWN` / `mergeStateStatus: UNKNOWN` on both
  polls, so I did not confirm PR #10 merges without conflict. `main` is unmoved at
  `89ada04`, so a conflict is unlikely but unverified.
- **`src/bus_display.gd.uid` uniqueness.** Untouched by this delta and not re-checked; the project
  imports cleanly at `6c89ed8`.
- **The response document's own evidence.** By design, I did not rely on any output pasted in
  `RESPONSE.md`; every number, string, and frame above was produced by my own run in a clean clone.
  All temporary artifacts (the clone, both probe scripts, generated captures, crops, logs) were
  deleted; `git status --porcelain` in the reviewed worktree is empty and no repository or GitHub
  state was modified.
