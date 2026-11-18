# Review: M9 maintenance rotation
- **Reviewer**: Claude
- **Verdict**: APPROVE

## Verification performed

All commands were run in a clean detached worktree at the implementation head (`rtk git worktree add --detach /home/unix/tmp/review-009-m9 aa05924...`, removed after review); the author's shared worktree was not switched or modified.

- `rtk git fetch github` / `rtk git fetch origin` — both fetched. `rtk git cat-file -t` on `c8f78e44950ef7ab9e4a829c1bcda3f30d23a6f8` and `aa05924ea58c90ce3d7b4156c70e4b88701212e7` → both `commit`. Local, `github/`, and `origin/feature/m9-maintenance-rotation` all at `ca85697e0137a45887a2021c354dfab77959f327`.
- Request exclusivity: `rtk git log c8f78e4..feature/m9-maintenance-rotation` shows exactly two commits — the implementation head and `ca85697` ("docs: request M9 peer review"). `rtk git diff --name-only aa05924..ca85697` → only `.peer-review/009-m9-maintenance-rotation/REQUEST.md`. No implementation commits after handoff.
- Authorship: `rtk git show -s --format='%an <%ae>%n%B' aa05924` → the owner's git identity, message "feat: add M9 maintenance rotation", no Co-Authored-By trailer.
- PR: `rtk gh pr view 5 --json state,isDraft,mergeable,mergeStateStatus,statusCheckRollup` → `OPEN`, non-draft, base `main`, head branch tip `ca85697` (via `--json commits`), `statusCheckRollup: null` (no CI configured, matching the request).
- Review worktree: `HEAD (no branch)` at exactly `aa05924ea58c90ce3d7b4156c70e4b88701212e7`, `rtk git status --short` clean.
- `rtk godot --headless --path . --editor --quit` → exit 0, no parser/resource errors.
- `rtk godot --headless --path . --script res://tests/verify.gd` → exit 0, `VERIFY PASS: 194 deterministic gameplay checks` (matches the request's expected count).
- `rtk godot --path . --resolution 1280x720 --script res://tests/capture.gd` → exit 0, `CAPTURE PASS: ... maintenance frames written to res://captures`; `file` confirms `11-maintenance-active.png`, `12-maintenance-contained-failure.png`, and `13-maintenance-ledger.png` are all `1280 x 720, 8-bit/color RGBA`.
- Visual inspection of all three new PNGs: frame 11 shows pulse 01/03, conditions 01/02/02 after the entry `2/1/1` wear, the landed-surge line plus next-surge forecast, the exact two-stroke rule, per-route selection with failure effects, and phase-local footer controls `[1–3] SELECT ROUTE [SPACE] APPLY REPAIR STROKE`. Frame 12 shows the contained LOOP-C failure (`00/03 / LOSS POSTED`, `-06 INTEGRITY`, integrity 63→57) with the map route red. Frame 13 shows the sealed ledger: all six allocations (`P1 L-C>N-R / P2 L-C>N-R / P3 L-C>N-R`), per-route disposition, endurance/integrity/coherence deltas (093%→089% for the carrier failure at zero roster uses), and the six-strokes/twelve-wear line. No clipping at 1280×720.
- `rtk git diff --check c8f78e4..aa05924` → exit 0, empty. `--name-only` → exactly `CLAUDE.md`, `README.md`, `src/main.gd`, `src/station_map.gd`, `tests/capture.gd`, `tests/verify.gd`. `project.godot` untouched.
- Full read of the reviewed diff (1062 insertions across the six files). Hand-traced all three two-route protection policies against the `2/1/1 → 1/2/1 → 1/1/2` schedule: protect loop+reserve → carrier fails at pulse 3; protect loop+carrier → reserve fails at pulse 2; protect reserve+carrier → loop fails at pulse 2; each exactly once, matching `tests/verify.gd`'s policy loop and the carrier penalty `4 + 2 * min(watch_roster_uses, 2)` (`src/main.gd:2058`). Also confirmed an all-routes-at-limit stroke deadlock is arithmetically unreachable, so a pulse window can always accept two strokes.
- Checked the console-swap regression risk: `_set_maintenance_console(false)` force-shows every direct child of the work-order/action sections on each `_refresh_all`. Confirmed the conditionally hidden controls (`followup_action_box`, `wo013_action_box`, `watch_action_box` — outcome-overlay children; `seal_action_panel` — map section, phase-guarded at `src/main.gd:2745`; `order_review_panel` — nested and guarded at `src/main.gd:2643`) are not in those lists or are re-guarded afterward, so no earlier-phase UI is un-hidden.
- Confirmed maintenance code only reads `watch_actions`/`watch_roster_uses`/`_watch_survivor_state()` and never writes them; coherence influences only the carrier label copy (`src/main.gd:2203`), not controls, wear, repair effects, or failure arithmetic.
- Re-verified immediately before writing this review: `rtk git fetch github`; branch tips still `ca85697`, review-worktree head still `aa05924`, PR #5 still `OPEN`, non-draft, `MERGEABLE`/`CLEAN`. The request is not stale.

## Findings

### [MINOR-1] Repeat-failure test never actually re-zeros a failed route
- File: tests/verify.gd:1067
- Problem: The check labeled "repairing a zero route allows later wear without a second contained-failure penalty" manually sets `maintenance_conditions.loop = 1` and `reserve = 3` after the LOOP-C failure, then applies a (loop, carrier) pair. Tracing it: loop goes 1→2 by repair, then pulse-3 wear brings it to 1 — it never reaches zero a second time, so the assertion passes without exercising the invariant "reaching zero again cannot repeat that loss."
- Evidence: State trace from `_enter_maintenance_rotation`: P1 wear → L1/R2/C2; pair (reserve, carrier) → R3/C3; P2 wear → L0 (failure posted)/R1/C2; after the manual sets (L1/R3/C2), pair (loop, carrier) → L2/C3; P3 wear `1/1/2` → L1/R2/C1. No route hits zero after the posted failure. The production guard (`src/main.gd:2032`, `condition == 0 and not maintenance_failures.has(key)`) is correct by inspection, and a realistic re-zero path exists (repair loop once in the P2 window, spend the other stroke elsewhere, and P3 wear re-zeros it), but the test as written does not cover it.
- Suggestion: In the P2 window repair loop once and a protected route once, letting P3 wear drive loop back to 0; assert `maintenance_failures` and integrity are unchanged by the second zero.

### [NIT-1] Map route label collides with the CORE room label
- File: src/station_map.gd:158
- Problem: The `N-R` route label at the reserve route midpoint overlaps the CORE room label in the active-maintenance frames (visible in `11-maintenance-active.png` and `12-maintenance-contained-failure.png` as "N-R"/"CORE" colliding). Still legible; purely cosmetic.
- Suggestion: Nudge the reserve route's label offset a few pixels down-left.

## What I did NOT check

- Platforms, renderers, window sizes, or display scales other than Linux/WSL2, Godot 4.4.1 GL Compatibility (Mesa/D3D12), 1280×720.
- Physical keyboard focus traversal, key repeat, IME, gamepad, accessibility tooling, or a complete mouse/keyboard-only playthrough of the whole campaign; input verification relies on the test suite's synthesized events, direct calls, and button signals plus the rendered captures.
- Exact rendered copy of every low-coherence variant: the `coherence < 50` carrier-label branch (`src/main.gd:2203`) was verified by code inspection and by the coherence-0 arithmetic tests, but no test or capture asserts the "TWO VALID TIMEBASES" string itself.
- Behavior of WO-011 through WO-014 beyond the paths the 194-check suite and the thirteen capture frames exercise; I reviewed the M9 diff's interactions with them (console swap, history immutability) rather than re-reviewing the prior milestones.
- PR #5's merged result against `main` (no CI is configured on the repository; local verification is the delivery gate, and the owner merges).
Round 2 verification is complete: both findings are genuinely fixed at the new head `20dee53`, all checks pass (import, 194-check suite, 1280×720 capture), the branch tips and PR #5 (OPEN, MERGEABLE/CLEAN) were re-verified immediately before output, and the review worktree was removed. Verdict: **APPROVE**.

## Round 2
- **Reviewer**: Claude
- **Verdict**: APPROVE
- **New implementation head**: 20dee53c83cb221ecbbebeaade6dcc127ebf7e22

### Verification performed

All commands ran in a clean detached worktree at the new head (`rtk git worktree add --detach /home/unix/tmp/review-009-m9-r2 20dee53...`, `rtk git status --short` clean, removed after review); the author's shared worktree was not switched or modified.

- `rtk git fetch github` / `rtk git fetch origin`; `rtk git cat-file -t` on both `aa05924ea58c90e...` and `20dee53c83cb221ecbbebeaade6dcc127ebf7e22` → `commit`. Reviewed exactly the focused delta: `rtk git diff --name-only aa05924..20dee53` → the two `.peer-review/009` docs files plus `src/station_map.gd` and `tests/verify.gd` only; `src/main.gd` and all other implementation files untouched, so no production gameplay behavior changed in this round. `rtk git diff --name-only 20dee53..947699b` → only `.peer-review/009-m9-maintenance-rotation/RESPONSE.md`, so `20dee53` is the last implementation commit and handoff exclusivity held.
- Authorship: `rtk git show -s` on `20dee53` → the owner's git identity, message `fix: [MINOR-1][NIT-1] close M9 review findings`, no Co-Authored-By trailer. `rtk git diff --check aa05924..20dee53` → exit 0, empty.
- `rtk godot --headless --path . --editor --quit` → exit 0, no parser/resource errors.
- `rtk godot --headless --path . --script res://tests/verify.gd` → exit 0, `VERIFY PASS: 194 deterministic gameplay checks` (matches RESPONSE.md).
- `rtk godot --path . --resolution 1280x720 --script res://tests/capture.gd` → exit 0, `CAPTURE PASS`; `file` confirms `11-maintenance-active.png`, `12-maintenance-contained-failure.png`, and `13-maintenance-ledger.png` are `1280 x 720, 8-bit/color RGBA`. Visually inspected frames 11 and 12.
- Re-verified immediately before writing this section: `rtk git fetch github`; `github/` and `origin/feature/m9-maintenance-rotation` both at `947699bab209334fffae8f5cc7d49300b945a808` (the RESPONSE.md docs commit atop `20dee53`); PR #5 head commit `947699b`, state `OPEN`, non-draft, `MERGEABLE`/`CLEAN`, `statusCheckRollup: null` (no CI configured, matching the request). The response is not stale.

### Resolution of Round 1 findings

- **[MINOR-1] Repeat-failure test never actually re-zeros a failed route — resolved (fixed in 20dee53).** The revised test (`tests/verify.gd:1077`) starts a fresh rotation at integrity 20 and drives a real second zero instead of hand-set conditions. Hand-traced against the `2/1/1 → 1/2/1 → 1/1/2` schedule: entry wear → L1/R2/C2; pair (reserve, carrier) lands pulse-2 wear → LOOP-C 0, first failure posts −6 (integrity 20→14, captured as `integrity_after_loop_failure`); pair (loop, carrier) repairs LOOP-C 0→1, then pulse-3 wear re-zeros it. The assertion pins `maintenance_conditions.loop == 0`, `maintenance_failures.loop == 6`, and integrity exactly 14 — a reposted penalty would yield 8 and fail. The prior bounded-loss case at integrity 4 is preserved above it (`tests/verify.gd:1066`), and the suite passes at 194 checks.
- **[NIT-1] Map route label collides with the CORE room label — resolved (fixed in 20dee53).** `src/station_map.gd:155` now gives the reserve route a route-specific `Vector2(-12, 14)` label offset while the other two routes keep `Vector2(5, -6)`. In the regenerated frames 11 and 12 the `N-R x/3` label sits below-left of the CORE room label, clearly separated and legible with no clipping; frame content is otherwise unchanged.

No new findings in the Round 2 delta. No BLOCKER or MAJOR remains and the risk-level-required verification ran, so the verdict is APPROVE.

### What I did NOT check

- Everything listed in Round 1's "What I did NOT check" still applies (other platforms/renderers/scales, physical-input paths, exact low-coherence copy, full re-review of WO-011–WO-014, merged result against `main`); Round 2 re-reviewed only the `aa05924..20dee53` delta and the two findings.
- Frame 13 (`13-maintenance-ledger.png`) was regenerated and size-verified but not re-inspected visually; the fix commit does not touch ledger rendering.
- Label placement at map sizes other than the 1280×720 layout's route geometry; the offset is fixed-pixel, and only the two captured maintenance frames were inspected.
