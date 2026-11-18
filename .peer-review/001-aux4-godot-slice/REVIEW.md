# Review: AUX-4 Godot vertical slice
- **Reviewer**: Claude
- **Verdict**: REQUEST_CHANGES

## Verification performed

Reviewed exactly `87e278f393bb3d9271e7a78d2ecf7ed557f9e37f..56f9791dbec6618a579a6096a0bd18630dfa99cd` (14 files, +1587) in the handed-off clean worktree `/home/unix/tmp/fault-tolerance-godot-review-001` at request commit `0b51315c0b5de0690b544f0e1fba64a34dfe03bf`.

- `git cat-file -t` on both pinned SHAs → `commit`; `git branch -a --contains 56f9791…` → `feature/aux4-vertical-slice` and `origin/feature/aux4-vertical-slice`. Re-verified immediately before writing this review: local and origin branch tips are both `0b51315…` (implementation head + REQUEST.md docs commit only), so the request is not stale.
- `godot --headless --path . --editor --quit` (Godot 4.4.1.stable) → exit 0; global classes `FaultToleranceGame` and `StationMap` registered; no parser or resource errors.
- `godot --headless --path . --script res://tests/verify.gd` → exit 0; `VERIFY PASS: 25 deterministic gameplay checks`.
- `godot --path . --resolution 1280x720 --script res://tests/capture.gd` → exit 0; `CAPTURE PASS`; four PNGs written to ignored `captures/` (only warning: unsupported V-Sync change, as disclosed in REQUEST.md).
- `git diff --check 87e278f…..56f9791…` → exit 0, no output.
- Visually inspected all four 1280×720 frames: boot, active-investigation, purge-outcome, and next-order states render without clipping; isolate shows `/ LOCKED` → `/ READY`, purge manifest shows `UNVERIFIED OCCUPANTS 01` and the reveal names Mina (acceptance criteria 4, 6, 7).
- `git show -s` on `56f9791…` → author the owner's git identity, no `Co-Authored-By` trailers.
- Full read of `src/main.gd`, `src/station_map.gd`, `tests/verify.gd`, `tests/capture.gd`, `project.godot`, `main.tscn` against the acceptance criteria and CLAUDE.md invariants.
- Ran a temporary headless repro script (created in `/tmp`, deleted afterward; no repo files modified) driving the same public methods verify.gd uses:
  - Path A — `camera(2) + provenance(2) + O₂(3) + isolate(5)`: `pre-isolate elapsed=7 jae_supported=true` → `outcome=rupture elapsed=12`.
  - Path B — all four investigations (6) + `O₂(3)` + `purge(3)`: `pre-purge elapsed=9` → `outcome=rupture elapsed=12`.
  - Path C — minimum-cost isolate: `outcome=isolate`, `"RESERVE" in outcome_ledger.text == false`.

## Findings

### [MAJOR-1] Exact-deadline commits rupture, making the supported-Jae isolation ledger branch unreachable dead code
- File: src/main.gd:757 (boundary check), src/main.gd:836-840 (dead branch), src/main.gd:752-754 (log labeling)
- Problem: `_spend_time` treats an action that completes in exactly the remaining time as a rupture (`elapsed_minutes >= RUPTURE_MINUTE` after adding `spent`), even when `spent == cost`, i.e. the action fully fit the window. Consequently the "do everything right" run — verify occupancy, trace provenance, route reserve oxygen to Jae, isolate (2+2+3+5 = 12) — always ends in rupture, so the `jae_supported → "CRITICAL / RESERVE"` line written into the isolate ledger at src/main.gd:836-840 can never render. The code contradicts itself about the intended possibility space: either exact-completion should succeed, or that ledger branch is dead code misrepresenting a reachable ending. The shift record compounds it: because `spent == cost`, the entry logs `COMMIT ISOLATE / 05m elapsed` with no `/ interrupted` marker, then the outcome is rupture anyway.
- Evidence: Repro paths A–C above (run against the pinned head): supported isolation → `outcome=rupture`; exact-window purge at T+9 → `outcome=rupture`; `RESERVE` never appears in any reachable isolate ledger (maximum pre-commit spend without O₂ is 6; with O₂ the minimum isolate total is exactly 12). verify.gd's rupture check (tests/verify.gd:79-81) only covers a genuine overrun (9 + bypass 4 = 13 clamped), not the exact-12 case, so the suite does not establish this as intended.
- Suggestion: Either let a commit whose full cost fits the remaining window finish (`>` instead of `>=` for the completed-commit case, or check overrun before applying the outcome), or — if simultaneous-with-cascade rupture is the intended cruelty — delete the unreachable `CRITICAL / RESERVE` branch and mark exact-window commits `/ interrupted` in the log so the record matches the outcome. State the chosen semantic in CLAUDE.md's invariants.

### [MINOR-1] Timeline events are logged at the post-spend minute, not the minute they occurred
- File: src/main.gd:764-777
- Problem: `_apply_timeline` runs after `elapsed_minutes` has absorbed the whole spend, and stamps events with the current total. A threshold crossed mid-spend is misdated by up to the spend size in the diegetic "APPEND ONLY" shift record.
- Evidence: Capture frame `02-active-investigation.png` shows `[T+05] MED-2 oxygen reserve below 18%` — the minute-4 event — because the crossing happened inside the 2-minute provenance query (1+2+2 = 5). A 3-minute O₂ route from T+3 logs the same event at `[T+06]`.
- Suggestion: Stamp the event with its threshold minute (`[T+04]`), or advance the clock minute-by-minute inside `_spend_time`.

### [MINOR-2] README hardcodes the author's absolute project path
- File: README.md:11, README.md:32-33
- Problem: Both run commands use `--path /home/unix/tmp/fault-tolerance-godot`, the author's original worktree. In any other checkout (including this review worktree) the commands run a different project or fail; CLAUDE.md correctly uses `--path .`.
- Evidence: This worktree is `/home/unix/tmp/fault-tolerance-godot-review-001`; following README verbatim here does not run the reviewed code.
- Suggestion: Use `--path .` (run from the repo root), matching CLAUDE.md.

### [MINOR-3] No test covers the unverified-purge manifest branch or the T+10 Jae death event
- File: tests/verify.gd:46-62; src/main.gd:799 and src/main.gd:771-777
- Problem: verify.gd tests the purge manifest only with Mina verified (`UNVERIFIED OCCUPANTS 01`). The complementary invariant-bearing branch — purge without verification must report `CERTIFIED CREW LOSS 00` — and the minute-10 unsupported-Jae death event (log + coherence penalty) are untested, so a regression in either would pass the suite.
- Evidence: The only purge scenario (tests/verify.gd:46-62) collects `mina` first; no scenario reaches `elapsed_minutes >= 10` while still ACTIVE.
- Suggestion: Add a blind-purge check asserting `CERTIFIED CREW LOSS 00`, and a four-investigations + bypass run (6+4 = 10) asserting the Jae death log/coherence effect.

### [NIT-1] Keypad keys are ignored
- File: src/main.gd:1049, src/main.gd:1053-1063
- Problem: Boot accepts `KEY_ENTER`/`KEY_SPACE` but not `KEY_KP_ENTER`, and evidence shortcuts accept only the top-row digits, not `KEY_KP_1`–`KEY_KP_5`. Take it or leave it; button focus navigation covers these users.

## What I did NOT check

- Real interactive input: `_unhandled_key_input` and mouse/button paths were exercised only via the programmatic methods the tests use, not with actual key/mouse events in a live session.
- Rendering at window sizes other than 1280×720, or `canvas_items` stretch behavior on high-DPI/other aspect ratios.
- Font fallback appearance on systems lacking Bahnschrift/Consolas (this machine used the DejaVu fallbacks successfully).
- Windows-native Godot; all checks ran on WSLg's GL-compatibility/D3D12 path, matching REQUEST.md's disclosure.
- Long-run behavior: memory or performance over extended `_process`/`queue_redraw` animation.
- The author's claimed pre-freeze fixes ("unreachable timeout", "T+13 overrun") individually — I only verified the current head's behavior.
- The claimed 60 FPS-equivalent smoothness of animations in the captures (static frames only).

## Round 2

- **Reviewer**: Claude
- **Verdict**: APPROVE
- **Newly reviewed implementation head**: `ed82cfe3372a9ba7b05aada963208cd1d6e96a74`

### Verification performed

Reviewed exactly `356ccf5da4430cbc1601bdef373bde99e49dab48..ed82cfe3372a9ba7b05aada963208cd1d6e96a74` (2 commits: `a134656`, `ed82cfe`; 4 files, +88/−16: `CLAUDE.md`, `README.md`, `src/main.gd`, `tests/verify.gd`) in the clean handed-off worktree `/home/unix/tmp/fault-tolerance-godot-review-001-r2` at handback commit `f3cee47292c59fa4287469844b194aebc4f3c337`.

- `git rev-parse HEAD` → `f3cee47292c59fa4287469844b194aebc4f3c337`; `git cat-file -t` on `87e278f…`, `56f9791…`, `356ccf5…`, `ed82cfe…`, `a134656…` → all `commit`. `git fetch origin` then `git rev-parse origin/feature/aux4-vertical-slice` → `f3cee47…`, re-confirmed immediately before writing this section — the request is not stale. `git diff --name-only ed82cfe…..f3cee47…` → only `.peer-review/001-aux4-godot-slice/RESPONSE.md`, so no implementation commits landed after the new head.
- `git show -s` on `a134656…`, `ed82cfe…`, `f3cee47…` → all the owner's git identity, no `Co-Authored-By` trailers; fix commit message references [MAJOR-1] [MINOR-1] [MINOR-3] [NIT-1], docs commit references [MINOR-2].
- `godot --headless --path . --editor --quit` (Godot 4.4.1.stable) → exit 0; global classes registered; no parser or resource errors.
- `godot --headless --path . --script res://tests/verify.gd` → exit 0; `VERIFY PASS: 35 deterministic gameplay checks` (up from 25; the 10 new checks cover exact-deadline isolation, blind purge, threshold timestamp, unsupported Jae death + coherence, and keypad input).
- `godot --path . --resolution 1280x720 --script res://tests/capture.gd` → exit 0; `CAPTURE PASS`; four PNGs written to ignored `captures/` (only the disclosed V-Sync warning).
- `git diff --check 356ccf5…..ed82cfe…` → exit 0, no output.
- Full read of the delta plus the surrounding `_spend_time`/`_apply_timeline`/`_finish` context in `src/main.gd:746-778` and the complete updated `tests/verify.gd`.
- Independent repro script (created in `/tmp`, deleted afterward; no repo files modified) driving the same public methods, probing paths beyond the suite:
  - Exact-deadline isolate (2+2+3+5=12): `outcome=isolate elapsed=12`, `CRITICAL / RESERVE` present, commit log `[T+12] COMMIT ISOLATE / 05m elapsed` with no `/ interrupted` marker.
  - Exact-deadline purge (6+3+3=12, Mina verified): `outcome=purge elapsed=12`, `UNVERIFIED OCCUPANTS 01`.
  - Exact-deadline bypass (5+3+4=12): `outcome=bypass elapsed=12`.
  - Overrun (6+3+bypass 4=13): `outcome=rupture elapsed=12`, `COMMIT BYPASS … / interrupted` logged.
  - Blind purge: `CERTIFIED CREW LOSS 00`, reveal still names Mina.
  - Mid-spend threshold crossing (O₂ from T+3): `[T+04] MED-2 oxygen reserve below 18%` present.
  - Keypad `KP_2`–`KP_5` (suite covers `KP_ENTER`/`KP_1`): camera/mina/provenance collected and Jae supported.
  - All probes passed (`R2 REPRO PASS`, exit 0).

### Finding resolutions

- **[MAJOR-1]** — **Resolved (fixed in `a134656…`), verified.** `_spend_time` gained a `resolves_fault` parameter set only by `commit_choice` (src/main.gd:741, 746); a repair commit with `spent == cost` landing exactly at minute 12 now completes (src/main.gd:757-758), while verification/support reaching 12 and any overrun still rupture. The formerly dead `CRITICAL / RESERVE` isolate-ledger branch (src/main.gd:837-841) is now reachable — confirmed by my repro and by the new suite check (tests/verify.gd:46-58). The log-labeling contradiction is gone: exact-fit commits log `05m elapsed` and genuinely succeed; only truncated spends carry `/ interrupted` (verified in repro paths A and D). The chosen boundary semantic is recorded in CLAUDE.md's invariants as Round 1 requested.
- **[MINOR-1]** — **Resolved (fixed in `a134656…`), verified.** The minute-4/7/10 events now stamp their threshold timestamps literally (src/main.gd:768, 771, 775-777). My repro confirmed `[T+04]` appears when the crossing happens inside a 3-minute spend, and the suite regression (tests/verify.gd:95-104) covers it. Note the backdated entry appends after the action's own `[T+0N]` line, so the "APPEND ONLY" record is no longer strictly timestamp-ordered — an inherent consequence of the fix direction I suggested; cosmetic, not a finding.
- **[MINOR-2]** — **Resolved (fixed in `ed82cfe…`), verified.** Both README commands now use `--path .` (README.md:9, README.md:32), matching CLAUDE.md; all my verification ran with checkout-relative commands from this worktree.
- **[MINOR-3]** — **Resolved (fixed in `a134656…`), verified.** The suite now asserts a blind purge reports `CERTIFIED CREW LOSS 00` (tests/verify.gd:78-85) and a four-investigations + bypass run reaching minute 10 asserts the Jae death log line and `coherence == 66` (tests/verify.gd:106-119). I confirmed the coherence arithmetic independently (84 initial − 10 minutes − 12 death penalty + 4 bypass recovery = 66) and both branches in my repro.
- **[NIT-1]** — **Resolved (fixed in `a134656…`), verified.** Boot accepts `KEY_KP_ENTER` (src/main.gd:1050) and evidence/support shortcuts accept `KEY_KP_1`–`KEY_KP_5` (src/main.gd:1055-1064). The suite exercises keypad Enter and KP_1; my repro exercised KP_2–KP_5.

### What I did NOT check

- Real interactive input: keypad paths were exercised by constructing `InputEventKey` objects programmatically, not by actual hardware key events in a live session (NumLock-off keypad behavior in particular).
- Anything outside the pinned delta: Round 1's unchecked items stand (non-1280×720 rendering, font fallbacks, Windows-native Godot, long-run `_process` performance) — nothing in this delta touches them.
- A verification/support action landing exactly on minute 12: no reachable action sequence produces one (maximum pre-commit spend is 9), so the rupture side of the new boundary contract for non-repair spends is enforced by code reading (src/main.gd:757-758) and the overrun path only.
- Re-inspection of the four capture PNGs beyond `CAPTURE PASS` exit status; the delta does not change rendering code, and Round 1 inspected the frames at the prior head.
- The stray untracked `/home/unix/tmp/fault-tolerance-godot-review-001-r2/.serena/commit` file present in the worktree (local tooling artifact; not part of any reviewed commit, left untouched).
