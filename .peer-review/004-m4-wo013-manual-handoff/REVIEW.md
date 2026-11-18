# Review: M4 timed WO-013 manual handoff
- **Reviewer**: Claude
- **Verdict**: APPROVE

## Verification performed

All checks ran in a fresh detached worktree at the implementation head (`git worktree add --detach /tmp/ft-review-004 bbb28c34c1f3d9b778699b8731c6a26edd6d538` — full SHA `bbb28c34c1f3d9b778699b8731c6a26ed6f6d538`), Godot 4.4.1.stable.mono.official.49a5bc7b6, Linux/WSL2.

- **SHA and branch state**: `git rev-parse` confirmed base `c485a44464c0451e0f2e21526e8379c` → full `c485a44464c0451e0fa4ac1432f7e21526e8379c` and implementation head `bbb28c34c1f3d9b778699b8731c6a26ed6f6d538` both exist; branch `feature/m4-wo013-manual-handoff` at `fe1c381565406a13ec20cb9261bc9719023a84ae`; `git merge-base --is-ancestor` confirmed HEAD contains the implementation head. Re-verified immediately before writing this review: head unchanged, and `git diff --name-only bbb28c3..HEAD` lists only `.peer-review/004-m4-wo013-manual-handoff/REQUEST.md`.
- **Fresh-checkout import**: `godot --headless --path . --editor --quit` in the clean worktree (no pre-existing `.godot/`) exited 0; log shows `reimport: step 0: Kenney Future Narrow.ttf` and documentation registration for all four scripts (`main.gd`, `station_map.gd`, `capture.gd`, `verify.gd`). No parser or resource errors.
- **Deterministic tests**: `godot --headless --path . --script res://tests/verify.gd` exited 0 with `VERIFY PASS: 107 deterministic gameplay checks`.
- **Captures**: `godot --path . --resolution 1280x720 --script res://tests/capture.gd` exited 0 with `CAPTURE PASS: boot, active, order-review, purge, follow-up, campaign-summary, WO-013, and final-ledger frames written to res://captures`; eight PNGs written.
- **Visual inspection** of `01-boot.png`, `02-active-investigation.png`, `06-wo013-repair.png`, `07-campaign-ledger.png`: the bundled display face renders consistently in headers and titles; the WO-013 decision frame (purge/sterilize lineage, coherence 27%) shows the `SOURCE ECHO 02` kicker, `TRACED / SOURCE ABSENT` attribution, and both repair buttons fully disclosing time/END/INT/COH/signal effects (`SIGNAL UNRESOLVED` on handoff — no responder promise on a sterilization path); the final ledger frame shows the WO-011 → WO-012 → WO-013 chain, `QUARANTINE / RESPONDERS RETAINED`, `HANDOFF / RETAINED / T+05m`, and 08 → 06 days / 052% → 057% / 087% → 090% deltas. No clipped rows or controls in any inspected frame.
- **Font hash**: `sha256sum "assets/fonts/Kenney Future Narrow.ttf"` = `572a3fc36adedf951365f77fa37011115363c7e8a537a308e563abdb299d7477`, matching both REQUEST.md and `THIRD_PARTY.md`.
- **Diff hygiene**: `git diff --check c485a44..bbb28c3` exited 0 with no output; `git diff --stat` lists exactly the eight files stated in REQUEST.md (no drive-by changes). `captures/` contains only a tracked `.gdignore`; no binary capture artifacts committed.
- **Authorship**: `git show -s --format='%an <%ae>%n%B' bbb28c3` = the owner's git identity, message `feat: add timed WO-013 manual handoff`, no `Co-Authored-By` trailer.
- **Code review of the full diff** (`src/main.gd:1169-1341`, `tests/verify.gd:271-486`, `tests/capture.gd`, docs): verified against all 14 acceptance criteria. Key confirmations: exact-fit success vs. overrun uses `wo013_elapsed_minutes + cost > WO013_WINDOW` (`src/main.gd:1234`), so trace+remote = 6 succeeds and trace+handoff = 7 ruptures with the clock clamped at 6 and ledger damage; all effects are bounded with `mini/maxi` (`src/main.gd:1237-1254`); handoff retains a responder only when `responders_retained` (set solely by quarantine at `resolve_followup`, `src/main.gd:1123`) — never revives a WO-012 loss; trace is one-shot (`wo013_verified` guard, `src/main.gd:1214`) and changes attribution text only; low coherence alters only the kicker text (`src/main.gd:1180-1186`), never controls, costs, or outcomes; resolved choices are irreversible (phase guard `src/main.gd:1231`, covered by the `"a resolved WO-013 choice cannot be replaced"` check); WO-011 rupture cannot reach WO-013 (`next_order_button` hidden on rupture, `open_next_order` guard, and the explicit rupture-terminal test at `tests/verify.gd:465-480`); keyboard V/E/H paths guarded by `event.pressed`/`event.echo`. Test coverage includes all six route×disposition entries, untraced repair, exact deadline, overrun, bounded effects, responder history, full-label disclosure under low coherence, keyboard and button paths, and irreversibility.

## Findings

None. This is a verified empty list, not a skimmed one: every "How to verify" command was re-run independently in a fresh checkout with the expected results, the representative captures were visually inspected, and the full diff was read against the acceptance criteria and the repository's deterministic-invariant list.

## What I did NOT check

- Upstream provenance of the font: I did not download Kenney's official archive to confirm the bundled TTF matches the distributed `Fonts/Kenney Future Narrow.ttf`; I verified the file hash only against the values recorded in REQUEST.md and `THIRD_PARTY.md`, and did not independently confirm the CC0 licensing claim.
- Interactive human play: mouse/keyboard flows were exercised through the deterministic test harness and synthesized `InputEventKey` events, not a live windowed play session.
- Captures `02b-work-order-review.png`, `03-purge-outcome.png`, `04-follow-up-decision.png`, and `05-campaign-summary.png` (pre-existing milestone frames) were regenerated but not visually re-inspected this cycle; only 01, 02, 06, and 07 were inspected.
- Rendering on platforms other than Linux/WSL2 (D3D12-backed Mesa GL Compatibility), window sizes other than 1280×720, or Godot versions other than 4.4.1.stable.mono.
- Glyph coverage of the bundled font beyond the ASCII visible in the inspected captures.
- Long-session behavior across repeated `RESTART CAMPAIGN` scene reloads (single reload path only, via code review).
