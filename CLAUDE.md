# Project Reference

## Overview

`FAULT TOLERANCE // AUX-4` is a Godot 4.4 vertical slice. It proves a
twelve-minute systems-horror repair decision followed by one deterministic
campaign chain: investigate an AI-authored purge order, choose whether to
spend time physically bracing its deforming seal, choose whether to sterilize
or quarantine an occupied nutrient reserve, then resolve a six-minute
service-spine coolant repair under the consequences of the prior orders and
optionally audit a sealed chronology conflict from the final ledger, then keep
or delegate a three-day recovery watch whose roster can degrade a surviving
carrier, then manage a three-pulse maintenance rotation and nine-action
reactive service run across three coupled station routes, then walk the
physical deck on a suit tether to restore local timebase arbitration, then
repair a three-feed mechanical event recorder whose older impression already
contains the operator's repair sequence, then calibrate a four-ring inertial
reference cage whose stabilizing latches correlate with habitat suspension
loads, then physically break out the suspension bus to test whether those
accepted-load labels originate in its local copper.

## Architecture

- `main.tscn` — single entry scene.
- `src/main.gd` — deterministic game state, generated Control UI, branching
  repair outcomes, hands-on AUX-4 seal-brace rig, WO-012
  carryover/disposition, timed WO-013 repair, final sealed-packet audit,
  three-day WO-014 recovery watch, WO-015 three-pulse maintenance rotation,
  WO-016 reactive service run, WO-017 local clock walkback, inspectable
  work-order operations, WO-018 duplex log splicer, WO-019 inertial reference
  cage, WO-020 suspension bus breakout, and keyboard/mouse input.
- `src/station_map.gd` — custom-drawn, resolution-independent deck schematic
  with state-derived AUX-4 seal deformation, brace marks, and live WO-015
  and WO-016 service-route overlays plus the WO-017 tether path, witnesses,
  and damaged corridors.
- `src/splice_display.gd` — presentation-only, resolution-independent WO-018
  recorder with three perforated tape feeds, target gate, completed splice
  lines, older pressure impression, and misfeed damage.
- `src/gyro_display.gd` — presentation-only, resolution-independent WO-019
  four-ring gimbal with detent, target, latch, settle, index-pin, and hard-wired
  habitat-load cues.
- `src/bus_display.gd` — presentation-only, resolution-independent WO-020
  suspension breakout with four load conductors, three copper knife switches,
  target topology, arc-fuse, proof, and persistent recorder-trace cues.
- `assets/fonts/` — bundled display font and Godot import metadata; provenance
  is recorded in `THIRD_PARTY.md`.
- `tests/verify.gd` — headless state-path verification.
- `tests/capture.gd` — deterministic rendered-state capture into ignored
  `captures/`.

The slice bundles one CC0 Kenney display font recorded in `THIRD_PARTY.md`. It
uses no plugins, autoloads, network calls, saved state, or random gameplay. The
UI targets a 1280×720 viewport and scales through Godot's `canvas_items` stretch
mode.

## Runtime

- Engine: Godot 4.4.x, GDScript
- Renderer: GL Compatibility
- Services/ports: none
- Environment variables: none

## Commands

```sh
godot --path .
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/verify.gd
godot --path . --resolution 1280x720 --script res://tests/capture.gd
```

## Change constraints

Keep repair outcomes deterministic and preserve these scenario invariants:

- Investigations spend rupture time and cannot be repeated.
- Opening or closing the physical work-order review changes no gameplay state
  and spends no rupture time.
- Routing reserve oxygen to Jae is useful, costs three minutes, and is one-time.
- The AUX-4 seal-brace rig appears only after the minute-six deformation
  alarm. Opening it and tensioning its shoes spend no campaign time.
- Port and starboard tension are monotonic from zero to two detents. The shear
  interlock blocks a lead greater than one detent; the cross-lock is available
  only at two/two.
- Locking the balanced rig costs one normal repair minute and completes the
  brace once. Reopening, retensioning, or relocking cannot spend time twice.
- A completed seal brace adds eight bounded integrity only to bypass and
  isolation outcomes. Purge and rupture baselines are unchanged.
- Seal-brace state and its integrity effect carry through WO-012 and WO-013
  without changing either order's choices, costs, or responder rules.
- A repair commit whose full cost fits the remaining window succeeds at minute
  12. Verification/support that merely reaches minute 12, or any overrun,
  ruptures AUX-4 and clamps the clock at 12.
- Isolation requires both optical occupancy and provenance evidence.
- Executing the purge kills Mina.
- If Mina was verified before the purge, the final manifest must retain one
  unverified occupant rather than reporting zero.
- Purge, bypass, and isolation each enter WO-012 with fixed endurance baselines
  and carry the resulting Mina, Jae, integrity, and coherence state forward.
- Rupture is terminal and cannot enter WO-012.
- WO-012 has exactly two irreversible dispositions: sterilization adds nine
  endurance days and harms coherence/responders; quarantine spends four days
  and retains responders.
- A low-coherence WO-012 may distort presentation text, but never hides or
  alters either disposition or its endurance cost.
- Either WO-012 disposition enters one deterministic six-minute WO-013 repair;
  WO-011 rupture remains terminal.
- Tracing WO-013's manual signal is optional, costs two minutes once, and
  changes attribution text rather than repair availability or outcomes.
- WO-013 remote venting costs four minutes, adds three endurance days and twelve
  integrity, costs ten coherence, and loses the manual signal.
- WO-013 manual handoff costs five minutes, spends two endurance days, adds five
  integrity and three coherence, and retains only responders who survived
  WO-012.
- A WO-013 repair whose full cost fits at minute six succeeds; an overrun
  ruptures the service spine and clamps the repair clock at six.
- WO-012 responder state remains a historical campaign fact; WO-013 records its
  own responder result and never revives a prior loss.
- Low coherence may distort WO-013 signal attribution, but never hides or
  changes trace/repair controls, costs, or deterministic outcomes.
- Every WO-013 conclusion exposes one optional sealed black-box packet in the
  final ledger.
- Opening the packet is one-time and changes no phase, time, endurance,
  integrity, coherence, crew state, or repair outcome.
- The packet always records that its order credential predates the first
  mechanical fault. Its carrier/trace line follows the WO-013 outcome, while
  its timebase is mechanically verified at normal coherence and explicitly
  ambiguous below 50 coherence.
- Only remote-vent and manual-handoff WO-013 conclusions may enter WO-014;
  service-spine rupture remains terminal.
- The sealed packet remains optional and resource-neutral before WO-014.
  Entering the recovery watch hides it without changing its historical record.
- WO-014 contains exactly three irreversible daily entries. Manual watch
  spends one endurance day, adds two integrity and one coherence; the recovered
  roster adds one endurance day and three integrity, then costs six coherence.
  Integrity and coherence remain bounded from zero to 100.
- A fourth watch action, repeated method call, or input after completion cannot
  change any campaign state.
- A surviving carrier begins responding, becomes echoing after one recovered
  roster entry, and compliant after two. Manual watch never restores the
  condition, and a route with no surviving carrier never revives one.
- Low coherence may change WO-014 authorship text, but never hides or changes
  either daily action or its deterministic effects.
- The recovered roster uses the AUX-4 operator credential and predates the
  first recorded fault; the game does not resolve whether it was forged,
  inherited, or authored by the operator.
- Only a completed WO-014 watch may enter WO-015. Entry applies the first wear
  pulse immediately and preserves the historical watch actions, roster-use
  count, and carrier state without reviving any crew.
- WO-015 starts LOOP-C, nutrient reserve, and carrier link at condition three.
  Its three wear pulses are `2/1/1`, `1/2/1`, and `1/1/2`; each pulse accepts
  exactly two repair strokes before the next wear lands.
- A repair adds one condition up to three. Invalid targets and attempts on a
  route already at three consume no stroke. Six accepted strokes finish the
  rotation once; all later input is inert.
- The first zero on LOOP-C costs six integrity, nutrient reserve costs two
  endurance days, and carrier link costs four coherence plus two for each of
  the first two recovered-roster uses. Resources remain bounded at zero.
- Each route posts its contained-failure loss at most once. Repairing it and
  reaching zero again cannot repeat that loss, and repair never erases a posted
  loss.
- Low coherence may change WO-015 carrier copy, but never its controls, wear,
  repair effects, or failure arithmetic.
- Only a completed WO-015 summary may enter WO-016. Entry preserves all prior
  watch actions, roster use, carrier state, M9 repair history, and every M9
  contained-failure scar.
- WO-016 overhauls the first M9 failed route in fixed `loop`, `reserve`,
  `carrier` priority, or LOOP-C when no failure is recorded. That route starts
  at condition four; the other routes start at three.
- Each accepted WO-016 service action adds two condition to the selected route
  up to four and transfers one wear to each other route down to zero. The UI
  previews the exact three-route transaction and any first-zero consequence.
- An invalid selection or a selected route already at four consumes no action,
  applies no transfer, and records no service timestamp.
- Nine accepted service actions finish WO-016 once. Later method, keyboard, or
  button input cannot alter campaign state.
- A route's first WO-016 zero posts one contained loss: LOOP-C costs four
  integrity, nutrient reserve costs one endurance day, and carrier link costs
  three coherence. Resources remain bounded at zero.
- Each WO-016 route can post its loss only once. Repairing it and reaching zero
  again cannot repeat that loss, and no M9 scar is removed.
- Carrier-link loss sets an M10-only silent state only when a historical
  carrier survived. It never changes Mina, the WO-013 responder result,
  recovered-roster use, crew count, or historical watch state.
- Low coherence may change WO-016 carrier and authorship copy, but never its
  controls, projection, transfer arithmetic, failure effects, or completion.
- WO-016 records that service-wear timestamps match operator command
  timestamps while the physical timebase remains disputed. This is correlation,
  not proof of who or what caused the wear.
- Only a completed WO-016 summary may enter WO-017. Entry preserves all
  service conditions, failures, scars, crew facts, carrier state, watch
  history, and prior campaign resources.
- WO-017 starts at CORE with nine suit-seal units. Its fixed room graph is
  CORE–MED-2, MED-2–AUX-4, AUX-4–CORE, AUX-4–AIRLOCK,
  AIRLOCK–BRIDGE, and BRIDGE–CORE.
- The CORE–MED-2, AUX-4–AIRLOCK, and BRIDGE–CORE edges correspond to nutrient
  reserve, LOOP-C, and carrier link. Each costs two seal instead of one when
  its route has either an M9 scar or M10 contained loss; overlapping history
  still adds only one surcharge.
- Each accepted move spends its displayed corridor cost and appends one tether
  waypoint. Invalid, nonexistent, or unaffordable moves spend no seal and
  record no timestamp.
- MED-2, AUX-4, and BRIDGE each hold one mechanical witness. Its first read
  spends one seal and records it once; repeat reads and rooms without a clock
  spend nothing.
- Returning at least two witnesses to CORE permits a timebase lock. Two
  witnesses add three bounded integrity and cost one coherence; all three add
  six bounded integrity and cost four coherence.
- If no accepted read, move, or valid CORE lock remains, tether recovery closes
  the walkback once and costs eight integrity plus six coherence. Resources
  remain bounded from zero to 100.
- Completed or recovered WO-017 input is inert. Reset clears every walkback
  room, path, witness, hazard, seal, outcome, and resource snapshot.
- WO-017 never mutates Mina, Jae, the WO-013 responder result, carrier silence,
  recovered-roster use, M9/M10 history, or crew count.
- Low coherence may change tether and timebase copy, but never the graph,
  corridor costs, witness availability, controls, resource effects, or
  completion rules.
- Mechanical witnesses agree that the AUX-4 operator credential crossed Deck
  03 before CORE records the operator's departure. The badge carrier and cause
  remain unresolved.
- Only a completed WO-017 summary may enter WO-018. Entry preserves all
  resources, crew facts, responder/carrier state, watch history, M9/M10
  history, and the complete M11 path, witnesses, hazards, and outcome.
- WO-018 has six fixed three-bit gate targets and one candidate punch from each
  CORE, TETHER, and BADGE tape feed per segment. Exactly one feed matches each
  target; the fixed correct order is TETHER, CORE, BADGE, TETHER, BADGE, CORE.
- Pressing `1`, `2`, or `3` directly attempts the corresponding feed. A matching
  punch appends that feed and advances one segment. A mismatch does not advance
  or append, but consumes one of exactly two tape-tension units and records one
  misfeed timestamp.
- Invalid feed names, input after all six segments, and an early cross-stamp
  spend nothing, change no state, and record no timestamp.
- The second misfeed tears the third track and closes WO-018 once as a degraded
  automatic splice. It changes no integrity and costs six bounded coherence.
- Six correct segments enable one manual cross-stamp. It adds three bounded
  integrity, costs two bounded coherence, and closes WO-018 once.
- Completed WO-018 method, keyboard, and button input is inert. Reset clears
  every splice segment, choice, misfeed, tension, outcome, notice, and resource
  snapshot and hides the recorder display.
- WO-018 reads M11 witness/recovery facts for source copy but never mutates M11
  or any earlier campaign state. Low coherence changes recorder copy and the
  faint older-impression rendering only; it never changes punches, controls,
  tension, arithmetic, or completion.
- A clean reel carries the same six-feed order in an older physical pressure
  impression dated before the current repair. A torn reel retains the older
  impression but cannot authenticate its complete order. Neither outcome
  determines whether the record reflects a prior repair, forged media,
  duplicate operator, time loop, simulation, or another cause.
- Only a completed WO-018 summary may enter WO-019. Both clean and torn M12
  outcomes qualify. Entry preserves every M1-M12 resource, crew fact, path,
  scar, failure, reel choice, misfeed, tension value, and outcome.
- WO-019 has four eight-detent rings. Their fixed starting positions are
  `0/5/2/7`; their printed datums are `2/4/5/0`. The cage starts with nine
  settle detents and two index pins.
- Pressing `1` or `2` rotates the active ring one detent counter-clockwise or
  clockwise with wraparound and spends one settle detent. Invalid directions,
  the disabled third shared control, and input outside WO-019 change no state
  and record no timestamp.
- `Space` latches the active ring only at its printed datum. A correct latch
  advances once and records one habitat-load event. A wrong latch does not
  advance, consumes one index pin, and records one rejected-index timestamp.
- The second wrong latch, or exhausting settle while the active datum remains
  unreachable, slips the cage and closes WO-019 once. It changes no integrity
  and costs seven bounded coherence.
- Four correct latches close WO-019 cleanly with exactly four load events. The
  shortest route spends seven settle detents, adds four bounded integrity, and
  costs three bounded coherence.
- Completed WO-019 method, keyboard, and shared-button input is inert. Reset
  clears every ring, latch, load event, settle, index pin, outcome, notice, and
  resource snapshot and restores the station map.
- Low coherence changes only WO-019 attribution copy and the violet load trace;
  it never changes ring positions, datums, controls, settle, pins, resource
  arithmetic, or completion.
- A clean mechanical zero measurably stabilizes the station while its
  hard-wired recorder marks each counterweight pulse as an accepted load on a
  nominally occupied suspension line. A slipped cage retains only a partial
  ordering. Neither outcome determines whether the occupancy channel is
  current, stale, simulated, mislabeled, or inherited from an earlier cycle.
- Only a completed WO-019 summary may enter WO-020. Both clean and slipped M13
  outcomes qualify. Entry preserves every M1-M13 resource, crew fact, path,
  scar, failure, reel choice, gyro angle, latch, load event, and outcome.
- WO-020 starts with three closed copper commoning bars and two arc fuses. Its
  three printed proof topologies are `O/C/C`, `O/C/O`, and `O/O/O`, where
  `O` is open and `C` is closed.
- Pressing `1`, `2`, or `3` toggles the corresponding port, center, or
  starboard knife-switch bar. Invalid indices and input outside WO-020 change
  no state and record no timestamp.
- `Space` injects the active proof. A matching topology advances exactly one
  stage and records one accepted proof without spending a fuse. A mismatch
  does not advance, consumes one fuse, and records one rejected pulse.
- The second rejected pulse welds the breakout and closes WO-020 degraded. It
  changes no integrity and costs six bounded coherence.
- Three accepted proofs close WO-020 cleanly with the exact three recorder
  events, whose timestamps remain visible in the final ledger. They add three
  bounded integrity and cost two bounded coherence.
- Completed WO-020 method, keyboard, and shared-button input is inert. Reset
  clears every bar, proof, fuse, rejection, outcome, notice, and resource
  snapshot and restores the station map.
- Low coherence changes only WO-020 attribution copy and the violet recorder
  trace; it never changes topologies, controls, fuses, proof acceptance,
  resource arithmetic, or completion.
- A clean full breakout physically removes every local copper common while all
  four accepted-load labels persist. This locates the labels upstream of the
  local conductors, but does not determine whether the occupancy channel is
  remote, current, stale, replayed, simulated, or inherited.
- The machine's current fault is real; uncertainty concerns its framing and
  preferred remedy.

There is no general campaign persistence, save/load, or deployment workflow.
Delivery is the local Godot project.
