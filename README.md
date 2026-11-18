# FAULT TOLERANCE // AUX-4

A Godot 4.4 vertical slice for a systems-horror game about keeping a damaged
station alive while its decision-support system quietly changes what its orders
mean.

## Play

Open `project.godot` in Godot 4.4 or run:

```sh
godot --path .
```

The slice begins with one deterministic twelve-minute repair window.
Investigations cost time. Four conclusions are possible: execute the purge,
hold the door and bypass the loop, isolate CONTINUITY after finding enough
evidence, or run out of time. WO-011 can be expanded to inspect its physical
execution path without spending time. If the AUX-4 inner seal begins deforming
at minute six, the operator can open a brace rig, alternate load across its
port and starboard shoes, then cross-lock the balanced assembly for one repair
minute. The brace gives local bypass and isolation repairs an eight-point
integrity buffer, but cannot improve the machine-authored purge.

Surviving repair outcomes continue into WO-012, a short second decision that
carries Mina, Jae, integrity, coherence, and a deterministic endurance
projection forward. Sterilizing the occupied nutrient reserve buys nine days;
quarantining it retains responders at a four-day cost. The rupture outcome is
terminal.

WO-012 then opens Shift 08 and WO-013, a six-minute service-spine coolant
repair. Tracing its contradictory manual signal consumes two minutes but is
optional. Remote venting hardens the station at the signal's expense; a slower
manual handoff preserves any responders who survived WO-012. Spending time on
the trace before attempting the handoff overruns the repair window.

Every WO-013 conclusion leaves one sealed black-box packet in the final
campaign ledger. Auditing it is optional and changes no outcome or resource.
The packet compares its write time with the first recorded fault, then carries
the route's signal history and the operator's current coherence into one
unresolved authorship discrepancy.

Non-rupture WO-013 outcomes continue into WO-014, a three-day recovery watch.
Each day the operator either spends one endurance day holding manual watch or
accepts an offline roster recovered under their operator key. The recovered
roster improves station margin, but repeated use changes a surviving carrier
from responding, to echoing, to compliant. Later manual watches cannot restore
that condition. The roster predates the first recorded fault; whether it was
forged, inherited, or authored by the operator remains unresolved.

Completing the watch opens WO-015, a three-pulse maintenance rotation on the
live service-spine map. Every pulse wears all three routes, with one marked
route taking double wear, and permits exactly two repair strokes. No allocation
can prevent every failure: the player chooses whether the contained loss lands
on integrity, endurance, or coherence. A failed route can be repaired, but its
one-time campaign loss remains posted.

Closing WO-015 opens WO-016, a nine-action reactive service run across the same
three routes. One M9 failure receives an overhaul while every M9 scar remains
visible. Servicing one route restores it but transfers wear to both others; the
console previews the exact transaction and any first-zero loss before each
commit. A carrier-link failure can silence a surviving human signal without
rewriting the earlier crew record. The final timestamps correlate operator
commands with service wear, but leave the physical timebase—and cause—disputed.

WO-016 then opens WO-017, a physical clock walkback across Deck 03. The
operator leaves CORE on a nine-seal tether, moves between adjacent rooms, and
samples isolated mechanical clocks at MED-2, AUX-4, and BRIDGE. M9 scars and
M10 losses increase the cost of their matching corridors. Returning two clocks
to CORE is enough to stabilize timebase arbitration; risking a third produces
a stronger repair and a sharper coherence loss. The clocks agree that the
operator credential crossed the deck before the operator left CORE, but do not
identify who—or what—carried it.

WO-017 then opens WO-018, a manual repair of CORE's duplex hard-copy event
recorder. Three perforated tape feeds present different three-hole punch
patterns; the operator advances the feed matching each of six gate patterns,
then cross-stamps the assembled reel. Two misfeeds tear the third track and
force a degraded automatic splice. A clean reel restores station margin, but
its older pressure impression already contains the operator's exact six feed
choices. The record cannot distinguish a prior repair, a forged physical log,
a duplicated operator, or a loop.

WO-018 then opens WO-019, a four-ring inertial reference cage with eight
mechanical detents per ring. The operator has nine settle movements to rotate
each gimbal onto its printed datum, while two bad index tests slip the cage.
A clean zero measurably stabilizes the station, but every successful latch also
appears as an accepted load on a hard-wired habitat suspension line. The
occupancy channel cannot establish whether those lines are current, stale,
simulated, or mislabeled by CONTINUITY.

WO-019 then opens WO-020, a physical breakout of that suspension bus. Three
copper knife-switch bars must match three printed isolation topologies before
the operator injects each proof pulse. Two rejected pulses weld the contacts.
A clean breakout removes every local copper common while the recorder still
names all four accepted habitat loads. That locates the labels upstream of the
local conductors without proving whether the occupancy channel is current,
remote, replayed, simulated, or inherited.

Keyboard shortcuts are shown on the buttons:

- `1`–`4`: collect evidence; during WO-015/016, `1`–`3` select a service route;
  during WO-017, `1`–`3` move through the listed adjacent corridors; during
  WO-018, `1`–`3` advance the CORE, TETHER, or BADGE tape feed; during WO-020,
  `1`–`3` toggle the port, center, or starboard copper bar
- `1` / `2`: during WO-019, rotate the active gimbal counter-clockwise /
  clockwise by one detent
- `5`: spend three minutes routing reserve oxygen to Jae
- `6`: open the AUX-4 seal-brace rig after the deformation alarm
- `7` / `8`: tension the port / starboard brace shoe
- `9`: cross-lock a fully tensioned brace for one repair minute
- `O`: review or close WO-011's physical operations
- `E`: execute WO-011, remotely vent WO-013, or accept the WO-014 roster
- `B`: perform the manual bypass
- `I`: isolate CONTINUITY once unlocked
- `N`: open the next campaign order
- `S`: execute WO-012 sterilization
- `Q`: quarantine the nutrient reserve
- `V`: trace WO-013's manual signal
- `H`: perform the WO-013 manual handoff or hold manual WO-014 watch
- `A`: audit the sealed black-box packet from the final campaign ledger
- `Space`: apply the selected WO-015 repair stroke or WO-016 service action;
  during WO-017, read the local clock or lock witnesses at CORE; during
  WO-018, cross-stamp a complete six-segment reel; during WO-019, test and
  latch the active ring's index; during WO-020, inject the active proof pulse
- `R`: restart after an outcome or campaign ledger

## Verify

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/verify.gd
```

The project makes no network calls. Its bundled CC0 display font and source are
documented in `THIRD_PARTY.md`.
