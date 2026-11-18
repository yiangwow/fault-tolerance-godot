# Review Request: AUX-4 Godot vertical slice

- **Author**: Codex
- **Repository**: `/home/unix/tmp/fault-tolerance-godot-origin.git` (local canonical bare remote)
- **Branch**: `feature/aux4-vertical-slice`
- **Base**: review baseline @ `87e278f393bb3d9271e7a78d2ecf7ed557f9e37f`
- **Implementation head**: `56f9791dbec6618a579a6096a0bd18630dfa99cd`
- **PR**: N/A — this is a local scratch prototype with no hosted forge
- **Risk level**: 1
- **Scope**: Build one self-contained Godot 4.4 AUX-4 decision slice; this does not implement the wider campaign, persistence, audio, deployment, or external services.
- **Source of truth**: User requirements: “make it in godot please”; use the available Windows-integrated Godot run and capture images; ask Claude to peer review the completed slice.
- **Risk rationale**: New local gameplay logic and UI with no public API, schema, security, deployment, or external-consumer impact.

## Acceptance criteria

1. Godot 4.4 imports and starts the project without parser or resource errors.
2. The player can begin the shift, investigate four evidence sources, and spend three minutes routing reserve oxygen to Jae.
3. Investigation and support costs are deterministic and one-time; the rupture clock cannot exceed minute 12.
4. Isolation remains locked until both optical occupancy and order-provenance evidence are attached.
5. Purge, manual bypass, isolation, and player-reachable rupture conclusions all work.
6. Executing the purge kills Mina; if Mina was verified first, the outcome retains one unverified occupant and names her in the reveal.
7. The 1280×720 boot, active, purge, and next-order states render without clipping.
8. The project has no external assets, network calls, services, ports, persistence, or random gameplay. A full campaign is an explicit non-goal.

## What changed

- Added `project.godot` and `main.tscn`.
- Added `src/main.gd` for the deterministic clock, evidence, crew state, choices, outcomes, input, and generated terminal UI.
- Added `src/station_map.gd` for the animated, custom-drawn deck schematic.
- Added `tests/verify.gd` with deterministic gameplay-path checks.
- Added `tests/capture.gd` for four rendered acceptance frames.
- Added `README.md`, `CLAUDE.md`, ignore rules, and Godot UID files.

## How to verify

Run from the repository root:

```sh
rtk godot --headless --path . --editor --quit
rtk godot --headless --path . --script res://tests/verify.gd
rtk godot --path . --resolution 1280x720 --script res://tests/capture.gd
rtk proxy git diff --check 87e278f393bb3d9271e7a78d2ecf7ed557f9e37f..56f9791dbec6618a579a6096a0bd18630dfa99cd
```

Expected:

- Editor import exits 0 with no parser/resource errors.
- Verification prints `VERIFY PASS: 25 deterministic gameplay checks`.
- Capture prints `CAPTURE PASS` and writes four PNGs under ignored `captures/`.
- Diff check exits 0 with no output.

## Author verification evidence

1. **Tests** — `rtk godot --headless --path . --script res://tests/verify.gd`; exit 0; `VERIFY PASS: 25 deterministic gameplay checks`.
2. **Build/import** — `rtk godot --headless --path . --editor --quit`; exit 0; filesystem scan, global-class registration, and editor load completed with no script/resource errors.
3. **Clean implementation state** — `rtk git status --porcelain=v1`; exit 0; no output before this request was written.
4. **End-to-end self-review** — reviewed the complete 14-file `base..implementation-head` diff; `rtk proxy git diff --check 87e278f393bb3d9271e7a78d2ecf7ed557f9e37f..56f9791dbec6618a579a6096a0bd18630dfa99cd`; exit 0; no output. `rtk godot --path . --resolution 1280x720 --script res://tests/capture.gd`; exit 0; `CAPTURE PASS` for boot, active, purge, and next-order frames. A focused logic audit found an unreachable timeout and a `T+13` overrun; both were fixed and rechecked before the implementation head was frozen.
5. **Scope** — `rtk git diff --name-only 87e278f393bb3d9271e7a78d2ecf7ed557f9e37f..56f9791dbec6618a579a6096a0bd18630dfa99cd`; only the 14 project, source, test, documentation, ignore, and UID files listed under “What changed”.
6. **Authorship** — `rtk git show -s --format='%H%n%an <%ae>%n%B' 56f9791dbec6618a579a6096a0bd18630dfa99cd`; the owner's git identity; no `Co-Authored-By` trailer.
7. **Project reference** — `CLAUDE.md` records architecture, runtime, commands, constraints, and the absence of services/ports/environment variables. No ADR is needed for this isolated prototype.
8. **Cycle allocation** — `.peer-review/` did not exist, so the synchronized incremental rule and the user’s explicit direction both select `001`; `.peer-review/001-aux4-godot-slice/` was created without collision.

## Known limitations / open questions

- This repository and its canonical bare remote are local-only, so PR and hosted CI evidence are N/A. The reviewer has a clean exact-SHA worktree and must run the checks locally.
- The GUI run uses WSLg’s OpenGL compatibility path on a Microsoft D3D12 device. Godot reports that changing V-Sync is unsupported, but rendering and capture complete successfully.
- The slice uses generated UI and geometry only. Audio, save/load, controller-specific navigation, multiple repair cycles, and the wider sanity campaign are not implemented.
