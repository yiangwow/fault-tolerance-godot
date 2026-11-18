# Review: M12 Duplex Log Splicer
- **Reviewer**: Claude
- **Verdict**: APPROVE

## Verification performed

All commands run from a clean checkout of `feature/m12-duplex-log-splicer` in `/home/unix/tmp/fault-tolerance-godot` (worktree clean apart from this untracked `REVIEW.md`). Godot: `4.4.1.stable.mono.official.49a5bc7b6`.

**1. SHA / branch / PR existence**

```
$ git cat-file -t 6be28e2237282519154396b0b38148363b13b1e3   -> commit
$ git cat-file -t 39223e1cd6766b908863fba330d9d8ba00d1d16e   -> commit
$ git rev-parse origin/main
6be28e2237282519154396b0b38148363b13b1e3
$ git log --oneline origin/main..origin/feature/m12-duplex-log-splicer
1c009b9 docs: request M12 peer review
39223e1 feat: add duplex log splicer
$ gh pr view 8 --json state,mergeable,baseRefName,headRefName,statusCheckRollup
{"baseRefName":"main","headRefName":"feature/m12-duplex-log-splicer","state":"OPEN","mergeable":"MERGEABLE","statusCheckRollup":null}
```

PR #8 is OPEN, base `main` @ `6be28e2…` matches the request, and `statusCheckRollup` is `null` — this repository has no configured GitHub checks, as the author disclosed.

**2. Implementation head re-checked immediately before writing this review** (2026-07-27T17:49:30Z UTC)

```
$ git rev-parse origin/feature/m12-duplex-log-splicer
1c009b9b32477d749e7fc35ba2307393d424b4da
$ git diff --name-only 39223e1cd6766b908863fba330d9d8ba00d1d16e..HEAD
.peer-review/012-m12-duplex-log-splicer/REQUEST.md
```

The only commit above the reviewed implementation head is the `REQUEST.md` docs commit. The reviewed head is not stale.

**3. Scope and authorship**

```
$ git diff --name-status 6be28e223…..39223e1cd…
M  CLAUDE.md
M  README.md
M  src/main.gd
A  src/splice_display.gd
A  src/splice_display.gd.uid
M  tests/capture.gd
M  tests/verify.gd
 7 files changed, 1035 insertions(+), 31 deletions(-)

$ git diff --name-only 6be28e223…..39223e1cd… -- project.godot main.tscn
(no output — engine config and entry scene untouched)

$ git show --no-patch --format='%an <%ae>%n%s%n%(trailers)' 39223e1cd…
the owner's git identity
feat: add duplex log splicer
(no trailers — no Co-Authored-By)
```

Exactly the seven files claimed; no drive-by changes. Grepped every added line for `rand|http|FileAccess|ResourceSaver|OS\.|ProjectSettings|Thread|Timer` — the only hits are the pre-existing `_save_viewport` capture helper and the `preload` of the new display script. No randomness, persistence, network, plugin, autoload, or deployment change.

**4. Risk Level 1 checks — all run by me**

```
$ godot --headless --path . --editor --quit
  exit 0; scan/import/plugin steps completed, no parse or import errors.

$ godot --headless --path . --script res://tests/verify.gd
  exit 0
  VERIFY PASS: 246 deterministic gameplay checks

$ godot --path . --resolution 1280x720 --script res://tests/capture.gd
  exit 0
  WARNING: Could not set V-Sync mode ... (known environment warning)
  CAPTURE PASS: ... clock-walkback, and duplex-splicer frames written to res://captures

$ git diff --check 6be28e223…..39223e1cd…
  exit 0, no output
```

Base `tests/verify.gd` had 198 `_expect(` sites; the head has 209 — the eleven new assertions are genuinely wired into `_run()` via `_verify_duplex_splicer()` (`tests/verify.gd:875`), not dead code.

**5. Gate/feed mapping derived independently from the constants**

From `src/main.gd:71-76`, targets `[5,3,6,1,7,2]` against `core [3,3,2,7,3,2]`, `tether [5,7,5,1,6,1]`, `badge [6,1,6,4,7,6]`:

| row | target | core | tether | badge | unique match |
|-----|--------|------|--------|-------|--------------|
| 0 | 101 | 011 | **101** | 110 | TETHER |
| 1 | 011 | **011** | 111 | 001 | CORE |
| 2 | 110 | 010 | 101 | **110** | BADGE |
| 3 | 001 | 111 | **001** | 100 | TETHER |
| 4 | 111 | 011 | 110 | **111** | BADGE |
| 5 | 010 | **010** | 001 | 110 | CORE |

Exactly one match per row, order `TETHER, CORE, BADGE, TETHER, BADGE, CORE` — matches acceptance criterion 2 and the `CLAUDE.md` invariant.

**6. Code read against each acceptance criterion**

- **(1) M11 gate** — `open_splicer()` returns unless `phase == Phase.WALKBACK_SUMMARY` (`src/main.gd:3524`); the only caller is `open_next_order()` at `src/main.gd:1673`. `_finish_walkback()` now exposes the continue button for both the locked and tether-recovery outcomes, both of which are completed WO-017 summaries.
- **(3) Input mapping** — keyboard `1/2/3/Space` → `core/tether/badge/stamp` (`src/main.gd:4615-4625`); the shared route buttons dispatch through `_on_maintenance_system_pressed()` (`src/main.gd:2209-2211`) with `SPLICE_FEEDS` index-aligned to `MAINTENANCE_SYSTEMS`.
- **(4) Misfeed accounting** — `src/main.gd:3580-3602`: `splice_misfeeds += 1`, `splice_tension = maxi(0, splice_tension - 1)`, no append, no index advance, one `_append_log` timestamp, and `_finish_splice(true)` exactly at tension 0.
- **(5) Inert inputs** — `advance_splice_feed()` guards phase, `key not in SPLICE_FEEDS`, and `splice_index >= 6` before any mutation (`src/main.gd:3549-3554`); `stamp_splice()` rejects a premature stamp with a notice only, no `_append_log` (`src/main.gd:3610-3616`).
- **(6)/(7) Arithmetic and bounds** — `src/main.gd:3620-3632`: clean `integrity = mini(100, integrity + 3)`, `coherence = maxi(0, coherence - 2)`; degraded leaves integrity untouched and applies `coherence = maxi(0, coherence - 6)`. `_finish_splice` is re-entrancy-guarded by `phase != Phase.SPLICER` plus a second per-path precondition, so neither outcome can fire twice.
- **(8) Reset** — `_reset_model()` clears all nine M12 fields (`src/main.gd:1313-1320`), and `_refresh_splicer()` restores `station_map`/legend/note visibility through `_set_splice_display_visible(false)` (`src/main.gd:3676-3677, 3798-3804`).
- **(9) Low coherence** — the only `coherence < 50` reads in M12 are the carrier attribution string (`src/main.gd:3741-3745`) and the `low_coherence` flag passed to the renderer (`src/main.gd:3687`), which affects only impression alpha (`src/splice_display.gd:108`). No control, punch, tension, or arithmetic path reads coherence.
- **(10) Presentation-only renderer** — `set_splice_state()` deep-copies both arrays and the dictionary (`src/splice_display.gd:35-38`); the script contains no game-state writes and is never given a reference back to the game node.
- **(11) Ledger copy** — `_splice_summary_ledger()` (`src/main.gd:3888-3905`) and the reveal lines (`src/main.gd:3654-3661`) state the underprint predates the repair and leave authorship unresolved; neither names a duplicate, forgery, loop, or simulation.

**7. Rendered frames inspected at 1280×720**

`captures/20-splicer-active.png` — three labelled perforated tapes, gate column, amber current-row emphasis on row 0 across all four columns, `TENSION 2 / MISFEEDS 0` footer, buttons reading `HEAD 011 / GATE 101` etc.
`captures/21-splicer-misfeed.png` — one completed splice line from the TETHER tape row 0 to gate row 0, violet impression on that row, current-row emphasis moved to row 1, footer `TENSION 1 / MISFEEDS 1`, notice `MISFEED 01/02 / TETHER PUNCH 111 != GATE 011 / TENSION 01`.
`captures/22-splicer-ledger.png` — ledger shows `INTEGRITY 069% -> 072%` (+3) and `COHERENCE 085% -> 083%` (−2), confirming criterion 6 arithmetic in a real render, not just in tests.

## Findings

### [MINOR-1] No test covers feed input in the six-seated-but-unstamped window
- File: `src/main.gd:3552`
- Problem: Acceptance criterion 5 lists three inert-input cases — invalid feed name, premature cross-stamp, and "feed input after all six segments". `_verify_duplex_splicer()` covers the first two (`tests/verify.gd:1237-1252`) and covers post-*completion* inertness after the phase has already moved to `SPLICER_SUMMARY` (`tests/verify.gd:1279-1290`), but nothing exercises the state where `splice_index == 6` and `phase` is still `Phase.SPLICER`. That is the only window in which the `splice_index >= SPLICE_TARGET_CODES.size()` clause of the guard is the thing doing the work; in every tested case the phase check alone would have sufficed.
- Evidence: The clean-run test advances six segments and immediately stamps (`tests/verify.gd:1265-1273`), so the guard clause is never the deciding condition. Deleting `or splice_index >= SPLICE_TARGET_CODES.size()` from `src/main.gd:3552` would still leave all 246 checks passing while allowing a seventh punch through `advance_splice_feed()` — the array index at `src/main.gd:3555` would then be out of range. I did not empirically confirm this (see "What I did NOT check"); it is read from the guard and the test bodies.
- Impact is low: the guard is present and correct on read, and the UI path is independently protected because all three feed buttons are disabled once six segments are seated (`src/main.gd:3768`). The exposure is a regression-detection gap, not current wrong behavior.
- Suggestion: one assertion after the sixth accepted feed and before `stamp_splice()`, asserting `splice_index`, `splice_tension`, and `log_lines.size()` are unchanged after a further `advance_splice_feed()` and a `KEY_1` event.

### [NIT-1] Unguarded `-1` index if a fourth shared route button is ever bound
- File: `src/main.gd:2211`
- Problem: `advance_splice_feed(SPLICE_FEEDS[MAINTENANCE_SYSTEMS.find(key)])` — `Array.find()` returns `-1` for an unknown key, and GDScript negative indexing resolves `SPLICE_FEEDS[-1]` to `"badge"` rather than erroring. An unknown key would silently attempt the BADGE feed instead of being rejected.
- Evidence: Not reachable today — `_on_maintenance_system_pressed` is only connected via `.bind(key)` over the three fixed `MAINTENANCE_SYSTEMS` keys (`src/main.gd:822`), and `advance_splice_feed` itself re-validates its argument. It is a latent trap for the next milestone that reuses this console. (The adjacent `move_walkback(MAINTENANCE_SYSTEMS.find(key))` on line 2213 predates this diff.)

### [NIT-2] Tear marks are indexed by misfeed ordinal, not by the row that misfed
- File: `src/splice_display.gd:172`
- Problem: `var y := gate.position.y + (float(damage) + 0.5) * row_height` places the first tear on gate row 0 and the second on gate row 1, regardless of which segment actually misfed.
- Evidence: In `captures/21-splicer-misfeed.png` the misfeed occurred on segment 1, but the red X is drawn over gate row 0 — the row that was successfully spliced — so the damage visually contradicts the completed splice line terminating on that same row. Cosmetic only; the numeric state (`MISFEEDS 01 / 02`) is correct everywhere.

### [NIT-3] Degraded ledger reads "NONE / 06 REQUIRED / PARTIAL" when zero segments were seated
- File: `src/main.gd:3892`
- Problem: `_splice_choice_line()` returns the placeholder `"NONE / 06 REQUIRED"` when `splice_choices` is empty (`src/main.gd:3856-3857`), and `_splice_summary_ledger()` appends `" / PARTIAL"` to it unconditionally on the degraded path.
- Evidence: Reachable in normal play — row 0's target is `101`, so pressing `1` (CORE, `011`) twice produces two misfeeds with no accepted segment, and the summary ledger renders `FRESH SPLICE    NONE / 06 REQUIRED / PARTIAL`. Every other ledger line in the slice reads as instrument copy; this one reads as a concatenation artifact.

No BLOCKER or MAJOR findings. The request's checklist claims all reproduce: 246 checks, clean import, clean capture, clean `diff --check`, correct authorship with no trailer, seven-file scope, `README.md` and `CLAUDE.md` updated in the implementation commit, and cycle `012` correctly allocated as the highest existing prefix plus one.

## What I did NOT check

- **No independently authored probe tests.** The `Write` tool was unavailable in this review session, so I could not author scratch GDScript to exercise paths the author's suite misses (I created and then removed a temporary worktree at `/tmp/m12-review` for that purpose before hitting the restriction). Everything beyond the author's suite is verified by code reading plus rendered-frame inspection, not by execution. MINOR-1's stated consequence of removing the guard clause is reasoning from the code, not a reproduced failure.
- **Degraded outcomes from segment counts other than 0 and 1.** The suite covers a tear after one accepted segment; I read but did not execute the paths where the tear lands at segments 2–5.
- **Entry into WO-018 from the tether-recovery WO-017 outcome.** Both the two-witness and three-witness lock paths and the recovery path set `next_order_button.visible = true`, and `_splice_source_line()` (`src/main.gd:3864-3869`) branches on `walkback_exposed`, but every test and capture I ran enters M12 through the three-witness lock only. The `TETHER RECOVERY / RETURNS 02 / SUIT 01` and `02-CLOCK LOCK / THIRD WITNESS UNREAD` source lines are unexercised.
- **Entry into WO-018 from non-`isolate` WO-011 branches.** The M12 helpers build on `_enter_walkback()`'s single canonical chain; purge- and bypass-rooted campaigns reach M12 through the same code but were not run.
- **CI.** None exists — `statusCheckRollup` is `null` on PR #8. I did not treat local runs as a substitute for CI; the delivery gates here are the four local commands above.
- **Resolutions other than 1280×720.** I inspected only the three 1280×720 frames; no aspect-ratio or scaling matrix was run, matching the author's stated limitation.
- **Perforation legibility.** `_draw_perforations` (`src/splice_display.gd:133-142`) fills a punched hole with `VOID` over an already-dark tape body, so holes read as near-invisible while unpunched positions get the outline. I could not judge from static captures at this size whether that reads correctly to a player in motion; I did not run the game interactively. Not raised as a finding.
- **Performance.** `SpliceDisplay._process` calls `queue_redraw()` every frame while active (`src/splice_display.gd:45-47`); I did not profile it, and it mirrors the existing `station_map` pattern.
- **`.peer-review/` content other than `REQUEST.md`.** I reviewed exactly `6be28e2237282519154396b0b38148363b13b1e3..39223e1cd6766b908863fba330d9d8ba00d1d16e` and did not review the `1c009b9` docs commit as code.
