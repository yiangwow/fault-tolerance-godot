# Review: M7 hands-on AUX-4 seal brace rig
- **Reviewer**: Claude
- **Verdict**: APPROVE

Reviewed range: `ace34abb5bd7887a2b9d11c326a158e29fc9aba6..58aae5a7cc3e9d5fb33fb85619b3fc7daa378a58` (base main @ `ace34abb5bd7887a2b9d11c326a158e29fc9aba6`, implementation head `58aae5a7cc3e9d5fb33fb85619b3fc7daa378a58`).

## Verification performed

All executed from a clean detached worktree at `58aae5a7cc3e9d5fb33fb85619b3fc7daa378a58` (`git worktree add --detach`, `git status --short` empty), Godot 4.4.1.stable.mono.official on Linux/WSL2.

- **SHA / branch / PR verification**: `git rev-parse --verify` confirmed both pinned SHAs exist. Branch `feature/m7-brace-rig` tip is `ae5233bedf1f529e63a3fb1f6c8c7a1a717655bb` locally and on `origin` after fetch; its parent is exactly the implementation head, and `git diff --name-only 58aae5a..ae5233b` shows only `.peer-review/007-m7-brace-rig/REQUEST.md` — protocol-compliant handoff, no implementation commits after the request. `gh pr view 3` → `OPEN draft:false`, base `main`, head `feature/m7-brace-rig`; `gh api .../pulls/3` head SHA `ae5233b...` matches the branch tip. `statusCheckRollup: null` (no CI configured, matching the request). Head re-verified intact immediately before writing this review.
- **Import**: `godot --headless --path . --editor --quit` → exit 0, no parser/resource errors or warnings in the log.
- **Test suite**: `godot --headless --path . --script res://tests/verify.gd` → exit 0, `VERIFY PASS: 141 deterministic gameplay checks` (matches the author's claim).
- **Captures**: `godot --path . --resolution 1280x720 --script res://tests/capture.gd` → exit 0, `CAPTURE PASS: ...` with all eleven frames written, including the two new/updated ones.
- **Visual inspection at 1280×720**: `02c-brace-rig.png` shows the open rig at T+06 with clock still 06:00 (no time spent), status `RIG / PORT 1/2 / STBD 0/2 / TENSION STARBOARD`, `LOCK -01m / +08 LOCAL INT / PURGE NO BENEFIT` disclosed, port `[7]` dimmed (leading), starboard `[8]` highlighted/actionable, `[9] LOCK` dimmed, and decision-support guidance "Keep port and starboard within one detent." `02c-braced-inner-seal.png` shows T+07, clock 05:00, integrity 46→44 (one minute of time cost), map `SEAL / BRACED` with brace marks, `[6] BRACED`, and log lines `[T+07] BRACE AUX-4 INNER SEAL / 01m elapsed` and `inner seal braced / local route buffer +08`. Neither frame clips; deck map, crew register, work order, verify/commit columns, log, and footer all remain legible and intact.
- **Hygiene**: `git diff --check ace34ab..58aae5a` → exit 0, no output. `git diff --stat` → exactly the five declared files (`CLAUDE.md`, `README.md`, `src/main.gd`, `tests/capture.gd`, `tests/verify.gd`); `project.godot` and `src/station_map.gd` untouched. `git show -s` on the head → `yiangwow <removed>`, no Co-Authored-By trailer.
- **Independent gameplay probe**: I wrote and ran a temporary headless SceneTree script (removed afterward; worktree left clean) covering paths the shipped suite does not literally exercise. Result: `PROBE PASS: 7 checks`, exit 0:
  1. Pre-T+06 keyboard `6/KP6/7/8/9` presses: no open, no tension, no lock, no time/integrity/coherence change.
  2. Repeated `open_brace_rig()` calls are inert.
  3. Starboard-first tensioning is also capped at a one-detent lead and reaches 2/2 by alternating.
  4. Starboard-first balanced lock still costs exactly one minute.
  5. After completion, reopen/retension/relock attempts change nothing (controls hidden, `_brace_rig_available()` false).
  6. A brace lock whose minute lands exactly on minute 12 ruptures AUX-4 without setting the brace — consistent with the pre-existing "support that merely reaches minute 12 ruptures" invariant, since `brace_inner_seal()` returns before setting `inner_seal_braced` when `_spend_time` reports rupture (src/main.gd:1096-1101).
- **Code read of the full range diff**, checked against every acceptance criterion:
  - Gating: `_brace_rig_available()` (src/main.gd:1024) requires `Phase.ACTIVE` + `seal_deformation` event + not already braced, and guards open, tension, lock, and completion alike. All four brace keys are inside the `Phase.ACTIVE` match only (src/main.gd:1932-1939).
  - Zero-cost open/tension: `open_brace_rig` and `_tension_brace` mutate only the three transient rig vars plus presentation text; no `_spend_time`, evidence, or crew paths touched.
  - Interlock: `_tension_brace` (src/main.gd:1055) computes the candidate and rejects `>2` or `absi(lead) > 1` before mutating — monotonic 0→2, one-detent skew cap, rejection state-free. Button disable logic in `_refresh_buttons` mirrors the same predicate, so mouse and keyboard rejections are equivalent, and the trailing shoe stays enabled (asserted in verify.gd and visible in the capture).
  - 2/2 lock: `lock_brace_rig` (src/main.gd:1086) rejects early locks without state change and funnels into the legacy `brace_inner_seal()`, which re-guards and spends exactly one WO-011 minute via the unchanged `_spend_time`; `inner_seal_braced` + `brace_rig_open = false` make every repeat path inert.
  - Parity: `KEY_6..KEY_9` each pair with `KEY_KP_6..KEY_KP_9` (src/main.gd:1932-1939); verify.gd exercises top-row (KEY_6/7/8/9), full keypad (KP_6→KP_9), and mouse (`emit_signal("pressed")` on all four buttons) to the same one-minute completion.
  - Cleanup: rig state cleared in `_reset_model` (src/main.gd:934-936) and at outcome commit (src/main.gd:1181-1183); verify.gd asserts a partial rig (open, port 1/2) does not block `commit_choice("purge")` and leaks no tension into the outcome.
  - Downstream invariants: verify.gd retains and passes braced-bypass `43 → 51` (tests/verify.gd:467-469), braced-isolation `52 → 60` at the exact deadline (tests/verify.gd:520-522), purge non-benefit, WO-012/WO-013 carryover, final-ledger, and sealed-packet checks; `SEAL_BRACE_INTEGRITY_BONUS` application code is untouched by the diff.
  - Docs: CLAUDE.md invariants and README controls updated in the same commit and accurately describe the shipped behavior.

## Findings

### [MINOR-1] Shipped suite never attempts pre-event rig actions, only asserts pre-event state
- File: tests/verify.gd:250-262
- Problem: Acceptance criterion 1 says the rig "cannot open, tension, lock, spend time, or alter state" before T+06, but the pre-event block only asserts passive state (`not brace_rig_open`, controls invisible) and attempts the legacy `brace_inner_seal()` (tests/verify.gd:258). No test calls `open_brace_rig()`, `_tension_brace`, `lock_brace_rig`, or presses keys 6–9 before the deformation event.
- Evidence: Grep of tests/verify.gd shows the first `open_brace_rig`/KEY_6 interaction occurs only after `_advance_to_seal_brace_window`. My independent probe (verification section, probe 1) confirmed the guards do hold, so this is a coverage gap, not a behavior bug.
- Failure scenario: A future refactor that splits `open_brace_rig`'s guard from `_brace_rig_available()` (e.g. checking only `brace_rig_open`) could let key `6` open the rig at T+00 and would still pass the 141-check suite.
- Suggestion: Add pre-event `open_brace_rig()` + key 6–9 attempts to the existing early-brace block; it costs four lines next to the existing `game.brace_inner_seal()` call.

### [NIT-1] Completed brace leaves residual 2/2 tension values until outcome or reset
- File: src/main.gd:1102
- Problem: `brace_inner_seal()` clears `brace_rig_open` but not `brace_port_tension`/`brace_starboard_tension`; the 2/2 values persist through the rest of the ACTIVE phase and are only zeroed at outcome commit (src/main.gd:1181-1183) or `_reset_model` (src/main.gd:934-936).
- Evidence: Probe 2 confirmed the stale values are unreachable — `_brace_rig_available()` is false once braced, controls are hidden, and nothing else reads the tension vars — so this is purely a latent-state tidiness note.
- Failure scenario: None today; only a hazard if a future feature reads tension outside the rig lifecycle.
- Suggestion: Zero both tensions alongside `brace_rig_open = false` for symmetry. Take it or leave it.

## What I did NOT check

- Rendering on platforms, renderers, display scales, or window sizes other than Linux/WSL2 + GL Compatibility at the 1280×720 target (same limitation the author declared).
- Interactive play with a real window, mouse, and physical keyboard/keypad — all input verification was through synthesized `InputEventKey` events and button `pressed` signals in headless/scripted runs, so OS-level focus, key-repeat, and IME behavior are unexercised.
- Focus-navigation ergonomics of the `call_deferred("grab_focus")` calls (e.g. Tab/arrow traversal between rig buttons) beyond confirming they cause no headless errors.
- Gamepad/controller input, audio, accessibility, or non-English locales (all out of scope per the request's non-goals).
- The nine remaining capture frames beyond spot-checking that they were regenerated with exit 0 — I visually inspected only the two rig-related frames named in the request.
- The author's claim that a rejected M7 prototype exists only in a local stash — unverifiable from the repository; I confirmed only that the reviewed range contains no trace of it.
- GitHub-side branch protection or merge settings; no CI exists to validate (`statusCheckRollup: null`), so merge-time verification remains local-only evidence.
## Round 2

Reviewer: Claude
**Round 2 verdict**: APPROVE

Re-reviewed only the implementation delta `58aae5a7cc3e9d5fb33fb85619b3fc7daa378a58..f645c94d0e7fa7c732d01d41e95bb2da8311dca3` and the two Round 1 findings. New implementation head: `f645c94d0e7fa7c732d01d41e95bb2da8311dca3`.

### Verification performed (round 2)

All state-path checks executed from a clean detached worktree at `f645c94d0e7fa7c732d01d41e95bb2da8311dca3` (`git worktree add --detach`, `git status --short` empty), Godot 4.4.1.stable.mono.official on Linux/WSL2. The worktree was restored clean and removed afterward.

- **SHA / branch / PR verification**: `git rev-parse --verify` confirmed both `58aae5a7cc3e9d5fb33fb85619b3fc7daa378a58` and `f645c94d0e7fa7c732d01d41e95bb2da8311dca3` exist. The delta contains exactly four commits: `ae5233b` (REQUEST.md), `65f4840` (REVIEW.md), `16c1d49` `test: [MINOR-1] exercise pre-event rig guards` (tests/verify.gd only, +19/−2), and `f645c94` `fix: [NIT-1] clear locked rig tension` (src/main.gd +2, tests/verify.gd +2). Implementation files touched in the delta are only `src/main.gd` and `tests/verify.gd`. Branch `feature/m7-brace-rig` tip is `e3a3e8c91656fa0aedf047a189df74bc338e4078` locally and on `origin` after fetch; `git diff --name-only f645c94..e3a3e8c` lists only `.peer-review/007-m7-brace-rig/RESPONSE.md` — no implementation commits after the new head, so this approval attaches to `f645c94` and remains valid at the current tip per Workflow step 7. `gh pr view 3` → `state OPEN, isDraft false`, base `main`, head `feature/m7-brace-rig`; `gh api .../pulls/3` head SHA `e3a3e8c...` matches the branch tip; `statusCheckRollup: null` (still no CI, matching the request). Tip and PR head re-verified unchanged immediately before writing this section. Both fix commits: author `yiangwow <removed>`, zero `Co-Authored-By` trailers in the delta range.
- **Import**: `godot --headless --path . --editor --quit` → exit 0, no parser or resource errors.
- **Test suite**: `godot --headless --path . --script res://tests/verify.gd` → exit 0, `VERIFY PASS: 141 deterministic gameplay checks` (matches the author's claim; the count is stable because both fixes extend existing `_expect` conditions rather than adding checks).
- **Captures** (rerun because `src/main.gd` changed): `godot --path . --resolution 1280x720 --script res://tests/capture.gd` → exit 0, `CAPTURE PASS` with all eleven frames. Visually re-inspected both rig frames at 1280×720: `02c-brace-rig.png` still shows the open rig at 06:00 with port `1/2`, starboard `0/2` actionable, lock dimmed, costs disclosed; `02c-braced-inner-seal.png` still shows T+07, clock 05:00, integrity 46→44, `[6] BRACED`, map `SEAL / BRACED`, and the brace log lines. Neither frame clips; no residual tension appears anywhere in the completed-state UI.
- **Mutation probe for [MINOR-1]'s failure scenario**: in the worktree I applied exactly the regression the Round 1 finding hypothesized — weakened `open_brace_rig()`'s guard from `if not _brace_rig_available() or brace_rig_open:` to `if brace_rig_open:` — and reran the suite: `VERIFY FAIL: pre-event rig methods and keys change no state, resources, copy, or repair time` plus one downstream failure, `VERIFY FAIL: 2 of 141 checks failed`. The new test has teeth. Mutation reverted (`git checkout -- src/main.gd`, `git status --short` empty).
- **Code read of the delta**: the [NIT-1] clear (src/main.gd:1103-1104) sits after the `_spend_time` early return, so it fires only on successful completion — correct placement, since the rupture path (`_finish`, src/main.gd:1183-1185) and `_reset_model` (src/main.gd:934-936) already clear all three rig vars on their paths; every terminal state now zeroes tension. The [MINOR-1] test block (tests/verify.gd:258-279) exercises `open_brace_rig()`, both tension methods, `lock_brace_rig()`, keys 6–9 via `_unhandled_key_input`, and the legacy `brace_inner_seal()` before T+06, then pins rig state, tensions, brace state, elapsed time, integrity 58, coherence 84, and dialogue copy. The completion assertion (tests/verify.gd:371-372) now requires both tensions to be zero post-lock while retaining the one-minute cost and resource checks.

### Resolutions

#### [MINOR-1] Shipped suite never attempts pre-event rig actions, only asserts pre-event state
- **Resolution**: RESOLVED — fixed in `16c1d49738e78a7892d91d2557a50c5f6f7c8e88`.
- **Evidence**: tests/verify.gd:258-279 now actively invokes every rig entry point (methods and keys 6–9) before the T+06 event and asserts no state, resource, copy, or time change. Independently confirmed effective by the mutation probe above: the exact guard-split regression named in the Round 1 failure scenario now fails the suite (2 of 141), whereas it previously would have passed.

#### [NIT-1] Completed brace leaves residual 2/2 tension values until outcome or reset
- **Resolution**: RESOLVED — fixed in `f645c94d0e7fa7c732d01d41e95bb2da8311dca3`.
- **Evidence**: src/main.gd:1103-1104 zeroes both tension counters alongside `brace_rig_open = false` on successful completion, and tests/verify.gd:371-372 pins the cleared state in the same assertion that verifies the unchanged one-minute cost, integrity/coherence effects, disabled completed control, and braced map state. Suite passes at 141; completed-brace capture unchanged in substance.

### What I did NOT check (round 2)

- Everything listed in the Round 1 "What I did NOT check" section still stands unchanged (other platforms/renderers/scales, real interactive input, focus-navigation ergonomics, gamepad/audio/locales, GitHub branch-protection settings, the author's local-stash claim); the delta gives no reason to revisit any of it.
- I did not re-run the Round 1 seven-check gameplay probe in full — Round 2 verification was scoped to the delta: the 141-check suite, the rerun captures, the mutation probe, and a code read of the four changed hunks. The delta touches only the completion-clear path and the pre-event test block, both of which the suite now covers directly.
- Of the eleven regenerated capture frames I visually inspected only the two rig-related ones; the other nine were verified solely by the script's exit 0 and `CAPTURE PASS` summary.
- No CI exists to validate (`statusCheckRollup: null`), so merge-time verification remains local-only evidence, as in Round 1.
