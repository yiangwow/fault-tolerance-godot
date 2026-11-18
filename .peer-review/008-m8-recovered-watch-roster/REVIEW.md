# Review: M8 recovered watch roster
- **Reviewer**: Claude
- **Verdict**: APPROVE

## Verification performed

Reviewed exactly `3c8775687b7251f6f65fea961fc0a70bf3150125..dd79bd27809631688dc56447a94ddc8d122e7747` (one implementation commit, `dd79bd2 feat: add recovered watch roster`). All execution ran in a clean dedicated detached worktree at the implementation head (`git worktree add --detach /home/unix/tmp/ft-review-008 dd79bd2…`; `git status --short` empty; `HEAD` re-verified as `dd79bd27809631688dc56447a94ddc8d122e7747`). The author's shared worktree was not switched or modified.

- **Pre-review state**: both SHAs resolve (`git rev-parse … ^{commit}` returned each full SHA). Branch `feature/m8-recovered-watch-roster` tracks `github/feature/m8-recovered-watch-roster`, in sync at `f9c685845b1e6de0c951dd665ac49f3842f653af`. PR #4 is OPEN, non-draft, `MERGEABLE`/`CLEAN`, base `main`, head commit `f9c6858…`, `statusCheckRollup: null` (no CI configured). Exclusive handoff verified: `git diff-tree --no-commit-id --name-only -r f9c6858` lists only `.peer-review/008-m8-recovered-watch-roster/REQUEST.md`.
- **Import**: `godot --headless --path . --editor --quit` (Godot 4.4.1.stable) exited 0 with no parser or resource errors.
- **Deterministic suite**: `godot --headless --path . --script res://tests/verify.gd` exited 0 with `VERIFY PASS: 168 deterministic gameplay checks`, matching the request.
- **Capture**: `godot --path . --resolution 1280x720 --script res://tests/capture.gd` exited 0 with `CAPTURE PASS: … recovered-watch frames written to res://captures`, writing all prior frames plus `09-watch-roster-day-2.png` and `10-watch-summary-ledger.png`.
- **Visual inspection of both new frames** (real 1280×720 renders): frame 09 shows the active watch with `WATCH DAY 02 / 03`, day history `D1 RST / D2 RST / D3 ---`, carrier `COMPLIANT`, roster header credential line, both actions with full disclosed costs (`END -01d / INT +02 / COH +01` and `END +01d / INT +03 / COH -06`), the `WATCH DAYS LEFT 01d` clock, and no clipping. Frame 10 shows the sealed ledger with `D1 RST / D2 RST / D3 MNL`, deltas `06 -> 07 DAYS`, `057% -> 065%`, `090% -> 079%`, credential `AUX-4 OPERATOR KEY / ACCEPTED`, and the `ROSTER PREDATES FIRST FAULT / AUTHOR UNRESOLVED` discrepancy. I independently recomputed both frames' arithmetic (roster, roster, manual = +1+1−1 endurance, +3+3+2 integrity, −6−6+1 coherence from 06/057/090) and it matches exactly.
- **Diff hygiene and scope**: `git diff --check <base>..<head>` exited 0 with no output; `git diff --name-only` lists exactly `CLAUDE.md`, `README.md`, `src/main.gd`, `tests/capture.gd`, `tests/verify.gd`. `project.godot` and `src/station_map.gd` untouched.
- **Authorship**: the range's single commit is the owner's git identity with no `Co-Authored-By` trailer.
- **Focused probe** (my own script, beyond the shipped suite): exited 0 with `PROBE PASS: 6 focused checks` — E/H keys inert in the final summary; watch entry hides the opened packet while `archive_packet_open` history is retained; `open_watch_roster()` re-entry mid-watch cannot re-snapshot or reset day state; A/N/R keys inert mid-watch; `open_archive_packet()` blocked mid-watch.
- **Code inspection of the full range**: `open_watch_roster` gates on `FINAL_SUMMARY` + `wo013_choice in ["remote","handoff"]` (src/main.gd:1626), so rupture stays terminal (also asserted by the suite, which confirms `next_order_button` stays hidden on rupture). `resolve_watch` guards phase, `watch_day >= 3`, and choice validity (src/main.gd:1661-1666); effects use exact clamped arithmetic (src/main.gd:1668-1676). Carrier state is derived, monotonic in `watch_roster_uses`, and `_watch_has_survivor` (src/main.gd:1778-1779) can never revive a dead Mina or a lost WO-013 responder. `_reset_model` clears all six watch variables and hides the watch box. Keyboard routing is phase-scoped with early returns (src/main.gd:2303-2311). Low-coherence attribution changes only `outcome_reveal` text (src/main.gd:1792-1795), verified by the suite to leave availability and effects unchanged. The shipped tests cover all six M1×WO-012 entry combinations, rupture gating, snapshot/archive neutrality, exact per-day arithmetic and bounds clamping, carrier deterioration and no-revival, post-completion immutability across direct/key/button paths, reset, input parity, and the all-manual route.
- **Head re-verification immediately before writing this review**: `git rev-parse dd79bd2…^{commit}` still resolves, remote branch head is still `f9c685845b1e6de0c951dd665ac49f3842f653af` (REQUEST.md-only commit atop the implementation head), PR #4 still OPEN at that head. The request is not stale.

## Findings

### [NIT-1] Two day-numbering conventions visible simultaneously during the active watch
- File: src/main.gd:2055
- Problem: The status label renders the *upcoming* day (`DAY %02d / 03` from `watch_day + 1`) while the decision ledger four lines above it renders *completed* days (`WATCH DAY       %02d / 03` from `watch_day`). In `09-watch-roster-day-2.png` the same panel shows both `WATCH DAY 02 / 03` and `DAY 03 / 03  ·  CARRIER COMPLIANT`.
- Evidence: Visual inspection of the captured frame; src/main.gd:1813 vs src/main.gd:2055-2057.
- Suggestion: Optional — label one of them explicitly (e.g. `NEXT ENTRY 03 / 03`). Both values are individually correct and every numeric effect is disclosed, so this never blocks.

## What I did NOT check

- Rendering on platforms, renderers, window sizes, or display scales other than Linux/WSL2 with Godot 4.4.1 GL Compatibility (Mesa/D3D12) at the 1280×720 target — the same environment limitation the author declared.
- Physical keyboard focus traversal, key repeat, IME, gamepad, accessibility tooling, or real mouse events; input verification (mine and the suite's) uses synthesized `InputEventKey` objects, direct method calls, and button `pressed` signal emission.
- Exhaustive replay of every pre-M8 route permutation by hand; earlier-route regression coverage relies on the 168-check deterministic suite (which includes the prior milestones' checks) plus reading the diff's touch points in `_finish`, `_finish_wo013`, `open_next_order`, and the `_refresh_*` functions.
- Mid-watch coherence crossing the 50 threshold changing the attribution line between days — I read the code path (it is a pure derivation from current coherence, affecting text only) but did not execute that specific sequence.
- CI — none is configured on the repository (`statusCheckRollup: null`), so local verification is the delivery gate, as stated in the request.
- The GitHub-side identity behind the pushed commits beyond the git author/committer fields and PR metadata readable via `gh`.
## Round 2

Reviewer: Claude

**Round 2 verdict**: APPROVE

New implementation head: `21ad5e3a574fde10fb9773c7566cd778681e3446`

### Verification performed (round 2)

Re-reviewed exactly `dd79bd27809631688dc56447a94ddc8d122e7747..21ad5e3a574fde10fb9773c7566cd778681e3446`. All execution ran in a clean dedicated detached worktree at the new implementation head (`git worktree add --detach /home/unix/tmp/ft-review-008-r2 21ad5e3…`; `git status --short` empty; `HEAD` = `21ad5e3a574fde10fb9773c7566cd778681e3446`; worktree removed after review). The author's shared worktree was not switched or modified.

- **Range contents**: exactly three commits — `f9c6858` (REQUEST.md only), `a948fbe` (REVIEW.md only), and the fix commit `21ad5e3 fix: [NIT-1] distinguish next watch entry` touching only `src/main.gd` (one line) and `tests/verify.gd` (two assertion clauses). `git diff-tree --no-commit-id --name-only -r` confirmed each commit's file list. Exclusive handoff held: no implementation commits between the REQUEST push and the Round 1 handback. `git diff --check` over the range exited 0 with no output. All commits in the range are the owner's git identity with no `Co-Authored-By` trailer.
- **Code delta**: `src/main.gd:2056` now renders `"NEXT ENTRY %02d / 03  ·  CARRIER %s"` from `mini(3, watch_day + 1)`; the historical ledger line at `src/main.gd:1813` is untouched and still renders completed days as `WATCH DAY %02d / 03`. The two conventions are now labeled distinctly, resolving the [NIT-1] ambiguity. `grep -n "NEXT ENTRY" src/main.gd` shows exactly one render site; no other copy, effect, guard, or input path changed.
- **Assertion teeth**: `tests/verify.gd:985` pins `watch_status_label.text.begins_with("NEXT ENTRY 01 / 03")` at watch entry and `tests/verify.gd:1007` pins `begins_with("NEXT ENTRY 03 / 03")` after the second roster day. I mutated the label back to `"DAY %02d / 03  ·  CARRIER %s"` in my worktree and re-ran the suite: it failed with `VERIFY FAIL: 2 of 168 checks failed` (both new clauses tripped; `tests/verify.gd:892` confirms `quit(1)` on failure). Restored the worktree (`git checkout -- src/main.gd`, `git status --short` clean) before the passing runs below.
- **Import**: `godot --headless --path . --editor --quit` (Godot 4.4.1.stable) exited 0 with no parser or resource errors.
- **Deterministic suite**: `godot --headless --path . --script res://tests/verify.gd` exited 0 with `VERIFY PASS: 168 deterministic gameplay checks` — same check count as Round 1, since the fix strengthens two existing assertions rather than adding checks.
- **Capture and visual inspection**: `godot --path . --resolution 1280x720 --script res://tests/capture.gd` exited 0 with `CAPTURE PASS`, regenerating all frames. `09-watch-roster-day-2.png` is a 1280×720 RGBA PNG (verified with `file`) and was visually inspected: the ledger shows `WATCH DAY 02 / 03` and the status line four rows below shows `NEXT ENTRY 03 / 03  ·  CARRIER COMPLIANT` — completed days and the upcoming entry are now explicitly distinguished, with no clipping anywhere in the frame. Frame arithmetic still matches exactly (two roster days from 06/057%/090% → `08 DAYS` / `063%` / `078%`, log `D1 RST / D2 RST / D3 ---`).
- **Head re-verification immediately before writing this section**: `git rev-parse 21ad5e3…^{commit}` resolves; `github/feature/m8-recovered-watch-roster` is `93b81e22d79e3fb36b6bd13288ffe5d7c06fd888` (a RESPONSE.md-only commit atop the fix — `git diff-tree` confirms it touches only `.peer-review/008-m8-recovered-watch-roster/RESPONSE.md`); PR #4 is OPEN, MERGEABLE/CLEAN at head `93b81e2…`, `statusCheckRollup: null`. The request is not stale.

### Finding resolutions (round 2)

- **[NIT-1] Two day-numbering conventions visible simultaneously during the active watch** — **Resolved (fixed in `21ad5e3a574fde10fb9773c7566cd778681e3446`)**. Independently verified: the status label now reads `NEXT ENTRY`, the ledger keeps `WATCH DAY`, the regenerated day-two frame shows both unambiguously, and the two new pinned assertions demonstrably fail if the fix is reverted. The fix is copy-plus-test only; no gameplay state, effect, cost, guard, or input behavior changed.

### What I did NOT check (round 2)

- Anything outside the delta `dd79bd2..21ad5e3` beyond re-running the full 168-check suite, import, and capture — the Round 1 code inspection of the full M8 range was not repeated line by line.
- Rendering on platforms, renderers, window sizes, or display scales other than Linux/WSL2 with Godot 4.4.1 GL Compatibility (Mesa/D3D12) at the 1280×720 target.
- Frame `10-watch-summary-ledger.png` was regenerated by the passing capture run but not re-inspected pixel by pixel; the fix cannot affect it (the status label is hidden outside `Phase.WATCH` and the ledger copy is untouched).
- Physical keyboard focus, key repeat, IME, gamepad, accessibility tooling, or real mouse events — unchanged Round 1 limitation.
- CI — none is configured (`statusCheckRollup: null`); local verification remains the delivery gate.
