# Review: M6 sealed audit packet
- **Reviewer**: Claude
- **Verdict**: APPROVE
- **Base reviewed**: 38dfacbc3c82965cafadde20ea47ac0d67834367 (main)
- **Implementation head reviewed**: 3f4c5870ecc328fbfa3c04396f4f65951b9f3083

## Verification performed

All checks were run from a clean detached worktree at the implementation head (`git worktree add --detach /home/unix/tmp/ft-review-006 3f4c587…`, `git status --short --branch` → `## HEAD (no branch)`, clean), Godot 4.4.1.stable on Linux/WSL2.

1. SHA and request integrity: `git rev-parse --verify` confirmed both `38dfacbc3c82965cafadde20ea47ac0d67834367` and `3f4c5870ecc328fbfa3c04396f4f65951b9f3083` exist; `git merge-base --is-ancestor` confirmed base→head ancestry; `git log base..head` shows exactly one implementation commit (`3f4c587 feat: add final sealed audit packet`).
2. Branch/PR state: current branch `feature/m6-sealed-audit-packet`; `git ls-remote origin` shows the branch tip at `3fdacb5` (the REQUEST.md commit, whose `git show --name-only` touches only `.peer-review/006-m6-sealed-audit-packet/REQUEST.md`, sitting directly on the implementation head). `gh pr view 2` → `state: OPEN`, `isDraft: false`, `mergeable: MERGEABLE`, `mergeStateStatus: CLEAN`, last commit `3fdacb5`.
3. Import check: `godot --headless --path . --editor --quit` → exit 0, no parser or resource errors.
4. Test suite: `godot --headless --path . --script res://tests/verify.gd` → exit 0, `VERIFY PASS: 130 deterministic gameplay checks`.
5. Captures: `godot --path . --resolution 1280x720 --script res://tests/capture.gd` → exit 0, `CAPTURE PASS: … final-ledger, and sealed-packet frames written to res://captures`; all ten PNGs regenerated. I visually inspected `captures/07-campaign-ledger.png` (closed `[A] AUDIT SEALED PACKET` action visible, ledger unclipped) and `captures/08-sealed-audit-packet.png` (red-bordered black-box panel; `PACKET WRITE SHIFT 06 / 18:41:09`, `FIRST FAULT SHIFT 07 / 19:04:11`, `MECHANICAL WATCH VERIFIED / OPERATOR COHERENCE 075%`, `RETAINED / LOCAL HANDOFF / NO MANUAL TRACE`, `ORDER PREDATES FIRST FAULT / AUTHOR UNRESOLVED`, disabled `[A] PACKET OPEN / WRITE-TIME CONFLICT` button — all legible, no clipping at 1280×720).
6. Whitespace/scope: `git diff --check base..head` → exit 0, no output. `git diff --stat` lists exactly `CLAUDE.md`, `README.md`, `src/main.gd`, `tests/capture.gd`, `tests/verify.gd` (+183/−6).
7. Authorship: `git show -s --format='%an %ae%n%B' 3f4c587` → `yiangwow <removed>`, no Co-Authored-By trailer.
8. Code read of the full diff plus surrounding context in `src/main.gd`:
   - Gating/idempotence: `open_archive_packet()` guards `phase != Phase.FINAL_SUMMARY or archive_packet_open` (src/main.gd:1432); keyboard `A` is only handled inside the `FINAL_SUMMARY` branch of `_unhandled_key_input` (src/main.gd:1812–1816) and the other phase branches are unchanged; button and key both route to the same `open_archive_packet()` (src/main.gd:753, 1813).
   - Non-mutation: `open_archive_packet()` touches only `archive_packet_open`, packet UI text/visibility, button disabled/text, and a deferred focus change — no resource, clock, phase, crew, or outcome field (src/main.gd:1431–1439); confirmed by the passing snapshot check in tests/verify.gd:572–583.
   - Availability on every legal WO-013 result: remote, retained handoff, lost-responder handoff, and overrun rupture all funnel through the single `_finish_wo013()` which unconditionally shows the resealed packet action (src/main.gd:1365–1428).
   - State derivation: timebase branches on `coherence < 50`, carrier on `wo013_responder_result == "RETAINED"` vs `"LOST / " + wo013_choice`, trace on `wo013_verified` (src/main.gd:1442–1453); `wo013_responder_result` is always `"RETAINED"`/`"LOST"` by the time `FINAL_SUMMARY` is reachable (src/main.gd:1346, 1356, 1361), so the string comparison has no unhandled value. The discrepancy line is constant, names no author, and never claims the fault is unreal — matching the invariant.
   - Reset: `_reset_model()` reseals and hides the packet (src/main.gd:913, 926–930), and the in-game `R` path (`restart_shift()` → full scene reload, src/main.gd:1487–1488) trivially reseals; tests/verify.gd:589–595 covers the model path.
   - M1–M5 invariants: the diff adds no changes to investigation, brace, WO-011/012/013 costs, outcomes, or responder rules; the 130-check suite (superset of the prior suite) passes.

## Findings

### [MINOR-1] REQUEST.md overstates verify.gd coverage: no repeated-open or out-of-phase open assertion
- File: tests/verify.gd:548–595 (and REQUEST.md "What changed": "phase gating, keyboard/button parity, idempotence")
- Problem: The suite opens the packet once per game instance (button emit at tests/verify.gd:563, direct call at 625, `KEY_A` at 684–687) but never asserts that a second open request on the same instance is a no-op, and never attempts `open_archive_packet()` from a pre-`FINAL_SUMMARY` phase to assert the gate holds. Acceptance criteria 2's "repeated requests are idempotent" and "only from `FINAL_SUMMARY`" are therefore enforced only by the two-condition guard at src/main.gd:1432, which I verified by reading, not by an executed check.
- Evidence: `grep -n 'open_archive_packet\|archive_button\|KEY_A' tests/verify.gd` → lines 548–595, 625–629, 684–693; no instance is opened twice and no open is attempted outside `FINAL_SUMMARY`.
- Failure scenario: a future refactor that drops either half of the guard (e.g. removes the `archive_packet_open` early-return while regenerating packet text with side effects, or loosens the phase check so `A` opens the panel over the WO-013 repair view) would still pass all 130 checks.
- Suggestion: add two one-line assertions — call `open_archive_packet()` in `Phase.REPAIR_2` and expect the panel closed, and re-emit `pressed`/`KEY_A` after opening and expect identical state/text.

## What I did NOT check

- Any GUT/interactive playthrough of the full game with a real window and mouse input — all behavioral verification went through the headless verify suite, the capture script, and code reading; I did not manually play to the final ledger.
- Rendering on platforms, renderers, window sizes, or DPI settings other than GL Compatibility at 1280×720 on Linux/WSL2 with Godot 4.4.1.stable (mono); the `canvas_items` stretch behavior at other resolutions is untested.
- The low-coherence packet rendering as pixels — `TWO VALID ANSWERS` is asserted deterministically in verify.gd:688–693, but no screenshot of the low-coherence branch exists (the author flagged this) and I did not generate one.
- Focus-traversal/controller navigation of the disabled archive button after opening (only keyboard shortcuts and programmatic button signals were exercised).
- CI: none is configured on the repository (`gh pr checks` reports no checks), so no independent CI run backs this review — local verification above is the only executable evidence.
- The unchanged `src/station_map.gd`, `main.tscn`, and font/import assets beyond confirming the diff does not touch them.
- Repository history outside `38dfacbc3c82965cafadde20ea47ac0d67834367..3f4c5870ecc328fbfa3c04396f4f65951b9f3083`; earlier-milestone invariants were re-verified only through the passing 130-check suite, not re-derived from their own review cycles.
## Round 2

- **Reviewer**: Claude
- **Round 2 verdict**: APPROVE
- **Implementation head reviewed (round 2)**: 2d01e4360e71aa1d6e9ccd8536232cd9a3c3d6d7
- **Delta reviewed**: 3f4c5870ecc328fbfa3c04396f4f65951b9f3083..2d01e4360e71aa1d6e9ccd8536232cd9a3c3d6d7 (implementation content: `tests/verify.gd` only, +23/−0; the other files in the range are this cycle's `.peer-review/006-m6-sealed-audit-packet/` REQUEST.md and REVIEW.md commits)

### Verification performed (round 2)

All executable checks ran from a fresh clean detached worktree at the new implementation head (`git worktree add --detach /home/unix/tmp/ft-review-006-r2 2d01e43…`; `git status --short --branch` → `## HEAD (no branch)`, clean; `git rev-parse HEAD` → `2d01e4360e71aa1d6e9ccd8536232cd9a3c3d6d7`), Godot 4.4.1.stable.mono on Linux/WSL2. The worktree was removed after verification.

1. SHA integrity: `git rev-parse --verify` confirmed both `3f4c5870ecc328fbfa3c04396f4f65951b9f3083` and `2d01e4360e71aa1d6e9ccd8536232cd9a3c3d6d7` exist; `git merge-base --is-ancestor 3f4c587… 2d01e43…` → ancestry confirmed. Head re-verified immediately before writing this section.
2. Branch/tip integrity: current branch `feature/m6-sealed-audit-packet`; `git ls-remote origin` → tip `616d1b57fc95deae1dfcad0192bbf1f21363b358` (matches local HEAD). `git log 2d01e43…..HEAD` contains exactly one commit, `616d1b5 docs: respond to M6 peer review`, and `git show --name-only 616d1b5` touches only `.peer-review/006-m6-sealed-audit-packet/RESPONSE.md` — no implementation commits after the new head.
3. PR state: `gh pr view 2` → `state: OPEN`, `isDraft: false`, `mergeable: MERGEABLE`, `mergeStateStatus: CLEAN`, last commit `616d1b57fc95deae1dfcad0192bbf1f21363b358`. `gh pr checks 2` → `no checks reported on the 'main' branch` (no CI configured, unchanged from Round 1).
4. Delta scope: `git show --stat 2d01e43…` → `tests/verify.gd | 23 +++…, 1 file changed, 23 insertions(+)`; no `src/`, scene, asset, or doc file changed, so Round 1's code-level findings on `src/main.gd` and the Round 1 capture inspection remain valid for this head. `git diff --check 3f4c587…..2d01e43…` → exit 0, no output.
5. Authorship: `git show -s --format='%an %ae'` on the fix commit → `yiangwow <removed>`; grep for `Co-Authored-By` in the commit body found nothing.
6. Import check (worktree): `godot --headless --path . --editor --quit` → exit 0, no parser or resource errors.
7. Test suite (worktree): `godot --headless --path . --script res://tests/verify.gd` → exit 0, `VERIFY PASS: 132 deterministic gameplay checks` (130 prior checks + the two new guard assertions; matches RESPONSE.md's claim).
8. Code read of the delta: the first new assertion calls `open_archive_packet()` on a `_enter_wo013("isolate", "quarantine")` instance while still in the WO-013 repair phase and asserts `archive_packet_open`, `archive_panel.visible`, and `archive_button.visible` all remain false (tests/verify.gd:531–537) — this executes the pre-`FINAL_SUMMARY` gate. The second re-calls `open_archive_packet()` on an already-opened packet and asserts panel/button state, packet text, button text, endurance, integrity, coherence, elapsed minutes, and WO-013 minutes are all unchanged against snapshots taken before the first open (tests/verify.gd:596–611) — this executes repeated-open idempotence. Both go through public state only, and the existing reset assertion still follows them.

### Findings resolution (round 2)

#### [MINOR-1] REQUEST.md overstates verify.gd coverage: no repeated-open or out-of-phase open assertion
- **Resolution**: RESOLVED — fixed in 2d01e4360e71aa1d6e9ccd8536232cd9a3c3d6d7.
- **Evidence**: The commit adds exactly the two suggested one-assertion checks: "the sealed packet cannot open before the final summary" (out-of-phase open attempted during WO-013, tests/verify.gd:531–537) and "reopening an open archive packet is idempotent" (second open on the same instance with text/state snapshot comparison, tests/verify.gd:596–611). I re-ran the suite independently from the clean detached worktree: exit 0, `VERIFY PASS: 132 deterministic gameplay checks`. Acceptance criterion 2's "only from `FINAL_SUMMARY`" and "repeated requests are idempotent" are now enforced by executed checks, not just the code guard.

No new findings. The Round 1 approval conditions carry to this head: the delta is test-only, adds coverage without weakening any existing assertion, and the full suite passes.

### What I did NOT check (round 2)

- Captures were not regenerated at this head: the delta touches only `tests/verify.gd`, so `captures/07-campaign-ledger.png` and `captures/08-sealed-audit-packet.png` are byte-identical products of unchanged rendering code; my visual inspection from Round 1 (at 3f4c587…) is the standing evidence for criterion 8.
- Everything listed under Round 1's "What I did NOT check" still stands unchanged: no interactive playthrough, no other platforms/renderers/resolutions, no low-coherence screenshot, no controller/focus-traversal testing, and no CI (none is configured — local verification remains the only executable evidence).
- The idempotence assertion snapshots the specific retained-handoff route used at tests/verify.gd:596; I did not add or demand repeated-open checks on every other WO-013 route, since the single shared guard at src/main.gd:1432 covers all routes and was read in Round 1.
- I did not re-review the unchanged `38dfacb…..3f4c587…` implementation diff beyond confirming this head's delta does not touch it.
