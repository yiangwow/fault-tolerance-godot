# Review: M5 timed AUX-4 seal brace
- **Reviewer**: Claude
- **Verdict**: APPROVE

Reviewed range: `9677b227b69fa0cf79c8c808df872302c2ff7417..5bb1d4cc34118de0ae220ab73c69cc0230b944be` (base `main @ 9677b227b69fa0cf79c8c808df872302c2ff7417`, implementation head `5bb1d4cc34118de0ae220ab73c69cc0230b944be`). Re-verified immediately before writing this review: branch tip is `70ca8c87626d18ab58390832c26293b05abdceaf`, and `git diff --name-only 5bb1d4c..70ca8c8` lists only `.peer-review/005-m5-aux4-seal-brace/REQUEST.md`, so the implementation head is intact and the request is not stale.

## Verification performed

All checks ran in a fresh detached worktree at `5bb1d4cc34118de0ae220ab73c69cc0230b944be` (created with `git worktree add --detach`, no pre-existing `.godot/`), Godot 4.4.1.stable.mono.official.49a5bc7b6 on Linux/WSL2.

1. `git cat-file -t` on both SHAs → `commit`; `git diff --name-only base..head` → exactly `CLAUDE.md`, `README.md`, `src/main.gd`, `src/station_map.gd`, `tests/capture.gd`, `tests/verify.gd` (matches stated scope, no drive-bys). `git diff --check base..head` → exit 0, no output.
2. Fresh-checkout import: `godot --headless --path . --editor --quit` → exit 0; `Kenney Future Narrow.ttf` reimported; all four scripts registered with no parser/resource errors.
3. `godot --headless --path . --script res://tests/verify.gd` → exit 0, `VERIFY PASS: 122 deterministic gameplay checks`.
4. `godot --path . --resolution 1280x720 --script res://tests/capture.gd` → exit 0, `CAPTURE PASS: boot, active, braced-seal, order-review, purge, follow-up, campaign-summary, WO-013, and final-ledger frames written to res://captures`; all nine PNGs produced.
5. Visual inspection of `captures/02c-braced-inner-seal.png`: field-action card ("FIELD ACTION / AUX-4 INNER SEAL", "BRACED / LOCAL ROUTES +08 INT / PURGE NO BENEFIT", disabled `[6] BRACED` button), map "SEAL / BRACED" clamp struts, footer `[1–4] VERIFY [5/6] FIELD [E/B/I] COMMIT`, log rows `[T+06] … deformation detected` / `[T+07] BRACE … 01m elapsed`, timer 05:00, integrity 044% (58−7×2), coherence 077% (84−7) — all legible, unclipped, and arithmetically consistent. `06-wo013-repair.png`: unbraced purge/sterilize route, traced source, both repair controls with full `-04m`/`-05m` cost disclosure, unclipped. `07-campaign-ledger.png`: seven-row braced-isolation final ledger (`M1 / SEAL BRACED / +08 LOCAL INT`, `INTEGRITY 060% -> 065%`, `COHERENCE 072% -> 075%`, `ENDURANCE 08 -> 06 DAYS`) — legible, consistent with isolate 52+8=60 then handoff +5.
6. Public reachability verified by source arithmetic (`EVIDENCE` costs 1+2+1+2 = 6 at `src/main.gd:30-55`; commit costs purge 3 / bypass 4 / isolate 5 at `src/main.gd:984`) and by test assertions run in step 3: four evidence queries reach exactly T+06 with the panel visible and isolation unlocked (`tests/verify.gd:379-390`), brace → T+07, isolate (5m) completes exactly at T+12 with integrity 60 (`tests/verify.gd:391-399`, `resolves_fault` deadline rule at `src/main.gd:1003-1006`); brace + `stabilize_jae` (3m) + isolate overruns, ruptures, clamps at 12, and records `BRACED / LOST WITH AUX-4` (`tests/verify.gd:307-321`). The test helper `_advance_to_seal_brace_window` (`tests/verify.gd:684-688`) uses only public evidence actions — no synthetic state.
7. Route-specific integrity: bypass 43→51 and isolate 52→60 via `mini(100, base + _seal_integrity_bonus())`; purge fixed 87 and rupture 0 untouched (asserted at `tests/verify.gd:323-346, 393-399, 427`). Gating/one-shot/parity: unavailable before T+06, early and repeated calls change no state or time, keyboard `6`/`KP_6` and button share one path, one-minute cost applies normal −2 integrity/−1 coherence (`tests/verify.gd:249-305`; guard at `src/main.gd:949-955`).
8. WO-012/WO-013 drift check: the diff only appends `_seal_ledger_line`/`_seal_campaign_ledger_line` text to existing ledgers and adds one map parameter; disposition costs (`+09d`/`-04d`), WO-013 costs/effects (remote 51+12=63), and responder rules asserted unchanged (`tests/verify.gd:347-377` plus pre-existing M2–M4 checks in the passing 122). Legacy unbraced routes keep fixed values (`tests/verify.gd:402-431`).
9. Independent probe (temporary script, run then deleted; worktree left clean): braced purge → integrity 87, immediate ledger discloses `PURGE NO BENEFIT`, and the `M1 / SEAL` row renders identically in WO-012, WO-013 decision, and final ledgers — history is carried immutably (probe output pasted in MINOR-1).
10. Authorship: `git show -s --format='%an <%ae>'` → the owner's git identity, no `Co-Authored-By` trailer. `README.md`/`CLAUDE.md` updated in the same commit; residual-reference check `grep -rn aux7 src tests` → none.

## Findings

### [MINOR-1] Braced-purge campaign history reads "+08 LOCAL INT" although no integrity was applied
- File: src/main.gd:1668
- Problem: `_seal_campaign_ledger_line()` unconditionally renders `M1 / SEAL       BRACED / +08 LOCAL INT` whenever `inner_seal_braced` is true, with no route qualifier. On the purge route the brace applied nothing, so the later ledgers assert a "+08" the campaign never received, adjacent to `M1 / INTEGRITY  087%`.
- Evidence: probe run at the implementation head — braced purge produced `outcome=purge integrity=87`, immediate ledger `PURGE NO BENEFIT` (correct per criterion 10), then WO-012 ledger `M1 / INTEGRITY  087%` directly above `M1 / SEAL       BRACED / +08 LOCAL INT`, repeated verbatim in the WO-013 decision and final ledgers. Contrast `_seal_ledger_line(false)` (src/main.gd:1653), which does route-qualify the immediate ledger.
- Failure scenario: a player who braced at T+07 and then purged reads the WO-012/WO-013/final history as "the brace added 8 integrity to this campaign" and misjudges their 87% as buffered, when the immediate ledger had said the opposite. No numeric state is wrong; text only.
- Suggestion: carry the applied/no-benefit distinction into the campaign row, e.g. `BRACED / NO PURGE BENEFIT` when `outcome_id == "purge"`.

### [NIT-1] `SEAL_DEFORMATION_MINUTE := 6` is duplicated in two files
- File: src/station_map.gd:10 (duplicate of src/main.gd:22)
- Problem: the map derives the deforming state from its own copy of the constant rather than from state passed by `main.gd`; if the alarm minute ever moves again (as it just did, 7→6), the two can drift silently.
- Evidence: both grep hits above; `set_scenario_state` already receives `minutes` and `seal_braced` but not the deformation threshold/event.

## What I did NOT check

- The `SEAL / LOST` map rendering after a braced rupture was verified by code reading (`src/station_map.gd:75-79`, `failed` branch) and the ledger assertion at `tests/verify.gd:318`, but no rendered capture of the lost-seal map state exists and I did not screenshot one.
- Rendering beyond the 1280×720 target: other resolutions, stretch behavior, non-WSL2 platforms, and non-Mesa/D3D12 drivers.
- Interactive input end-to-end (real window keyboard/mouse events); key handling was exercised only through synthesized `InputEventKey` objects in the headless suite.
- A brace attempt that itself crosses T+12: I verified by cost arithmetic that it is unreachable (maximum pre-commit elapsed time via public actions is 6 evidence + 1 brace + 3 Jae = 10 minutes), but there is no test asserting that ceiling.
- `captures/01`–`05` were regenerated and spot-glanced for presence/size but not pixel-inspected this cycle beyond the three frames named in the request.
- No lint/format tooling exists for GDScript in this repo; I did not run Serena diagnostics — the author's claim of clean diagnostics is untested by me.

## Round 2
- **Reviewer**: Claude
- **Verdict**: APPROVE

Re-reviewed range: `5bb1d4cc34118de0ae220ab73c69cc0230b944be..3b65b1b5cd5b947f7cae599620cf7e4ec5ffc0d4` (new implementation head `3b65b1b5cd5b947f7cae599620cf7e4ec5ffc0d4`). The range contains exactly two implementation commits — `692a1292501066e76157d9cb2671fd4268cac67e` (`fix: [MINOR-1] qualify seal campaign history`) and `3b65b1b5cd5b947f7cae599620cf7e4ec5ffc0d4` (`refactor: [NIT-1] pass seal event state to map`) — plus the two `.peer-review/` handoff commits (`70ca8c8`, `5fc2f94`), which I treated as records, not implementation. Head-integrity check immediately before writing this round: branch tip is `0e9616f6e5514827257c46448f58181eda5c801e` and `git diff --name-only 3b65b1b..0e9616f` lists only `.peer-review/005-m5-aux4-seal-brace/RESPONSE.md`, so no implementation changed after the new head and the response is not stale.

### Verification performed (round 2)

All executable checks ran in a fresh detached worktree at `3b65b1b5cd5b947f7cae599620cf7e4ec5ffc0d4` (`git worktree add --detach`, no pre-existing `.godot/`), Godot 4.4.1.stable.mono.official.49a5bc7b6 on Linux/WSL2; the worktree was removed afterwards.

1. `git diff --name-only 5bb1d4c..3b65b1b` → `src/main.gd`, `src/station_map.gd`, `tests/verify.gd` plus the two handoff `.peer-review/` files; no other files. `git diff --check 5bb1d4c..3b65b1b` → exit 0, no output.
2. Full diff of both fix commits read end to end: MINOR-1 touches only `_seal_campaign_ledger_line()` plus one new test block; NIT-1 removes `SEAL_DEFORMATION_MINUTE` from `src/station_map.gd`, adds an `inner_seal_deforming` field fed by a new `seal_deforming` parameter on `set_scenario_state()`, and switches `_draw()` to the passed state. `grep -rn SEAL_DEFORMATION_MINUTE src` → only `src/main.gd:22` (declaration) and `src/main.gd:1016,1022` (uses); the constant is single-sourced.
3. `godot --headless --path . --editor --quit` → exit 0, font reimported, all scripts registered, no parser/resource errors.
4. `godot --headless --path . --script res://tests/verify.gd` → exit 0, `VERIFY PASS: 123 deterministic gameplay checks` (122 → 123; the new check is the braced-purge history assertion).
5. `godot --path . --resolution 1280x720 --script res://tests/capture.gd` → exit 0, `CAPTURE PASS: boot, active, braced-seal, order-review, purge, follow-up, campaign-summary, WO-013, and final-ledger frames written to res://captures`; all nine PNGs produced.
6. Visual inspection of the two frames the fixes could affect: `02c-braced-inner-seal.png` still shows the deforming/braced map (`SEAL / BRACED` clamp struts), the field-action card, `[T+06]` deformation and `[T+07]` brace log rows, timer 05:00, integrity 044%, coherence 077% — the map's switch from its own constant to passed event state produced no rendering regression. `07-campaign-ledger.png` (braced-isolation route) still reads `M1 / SEAL BRACED / +08 LOCAL INT` with `INTEGRITY 060% -> 065%` — the non-purge branch of the qualified ledger line is unchanged, as required.
7. Call-site coverage for MINOR-1: `_seal_campaign_ledger_line()` is the single source for all four later-ledger renderings (`src/main.gd:1175, 1226, 1368, 1405`), and `outcome_id` is assigned only at reset (`src/main.gd:867`) and WO-011 commit (`src/main.gd:1037`), so the `outcome_id == "purge"` qualifier holds identically in the WO-012, campaign-summary, WO-013, and final ledgers. The immediate-ledger function `_seal_ledger_line()` (`src/main.gd:1654`) is untouched.
8. Authorship: both fix commits are the owner's git identity with no `Co-Authored-By` trailer, and each message references its finding ID.

### Finding resolutions

- **[MINOR-1]** Braced-purge campaign history reads "+08 LOCAL INT" although no integrity was applied — **resolved (fixed in `692a1292501066e76157d9cb2671fd4268cac67e`)**. `_seal_campaign_ledger_line()` (`src/main.gd:1669`) now renders `BRACED / NO PURGE BENEFIT` when `outcome_id == "purge"` and the `+08 LOCAL INT` text only on non-purge routes. The new public-route regression test (`tests/verify.gd:334-341`) drives a braced purge through `open_next_order()` and asserts the WO-012 ledger contains `BRACED / NO PURGE BENEFIT` and excludes `+08 LOCAL INT`; it passes in the 123-check run, and the shared-function analysis in item 7 extends the guarantee to the WO-013 and final ledgers. The author's failing-first evidence (`VERIFY FAIL: 1 of 123` before the fix) is consistent with the test being added ahead of the fix, though I did not re-run the pre-fix state myself.
- **[NIT-1]** `SEAL_DEFORMATION_MINUTE := 6` is duplicated in two files — **resolved (fixed in `3b65b1b5cd5b947f7cae599620cf7e4ec5ffc0d4`)**. The map no longer owns a threshold constant; `main.gd` passes `timeline_events.has("seal_deformation")` into `set_scenario_state()` (`src/main.gd:1508`), and `_draw()` branches on the received `inner_seal_deforming` state (`src/station_map.gd:63`). This is actually stronger than the suggested fix: the map now reflects the real event rather than re-deriving it from elapsed minutes. Tests assert the map state is false before T+06 and true after (`tests/verify.gd:250-252, 271`).

### What I did NOT check (round 2)

- The pre-fix failing state of the new MINOR-1 test (`VERIFY FAIL: 1 of 123`) claimed in RESPONSE.md — I verified only the post-fix passing suite.
- WO-013-decision and final-ledger renderings of the braced-**purge** route as pixels; the qualified text there is guaranteed by the shared single function and `outcome_id` immutability (item 7), and was probe-verified at the round-1 head, but no round-2 capture of that specific route exists.
- Serena warning-or-higher diagnostics claimed empty in RESPONSE.md — not re-run by me.
- Everything declared unchecked in round 1 that this delta does not touch: lost-seal map capture, non-1280×720 rendering, real-window interactive input, other platforms/drivers, and pixel inspection of `captures/01`–`05` beyond presence.
