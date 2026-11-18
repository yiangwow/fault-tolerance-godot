class_name StationMap
extends Control

const VOID := Color("07100e")
const PANEL := Color("0e201c")
const PHOSPHOR := Color("a9d8a4")
const AMBER := Color("e6a448")
const RED := Color("d45b50")
const VIOLET := Color("8877a9")
const ICE := Color("8dbdc0")

@export var display_font: Font

var elapsed_minutes := 0
var mina_state := "unknown"
var outcome_id := ""
var coherence_value := 0
var jae_supported := false
var inner_seal_deforming := false
var inner_seal_braced := false
var maintenance_active := false
var maintenance_conditions: Dictionary = {}
var maintenance_selected := ""
var maintenance_roster_uses := 0
var maintenance_scars: Array[String] = []
var maintenance_condition_max := 3
var walkback_active := false
var walkback_room := ""
var walkback_path: Array = []
var walkback_witnesses: Array = []
var walkback_hazards: Array = []


func set_scenario_state(
	minutes: int,
	mina: String,
	outcome: String,
	coherence: int,
	jae_has_reserve: bool = false,
	seal_braced: bool = false,
	seal_deforming: bool = false
) -> void:
	elapsed_minutes = minutes
	mina_state = mina
	outcome_id = outcome
	coherence_value = coherence
	jae_supported = jae_has_reserve
	inner_seal_braced = seal_braced
	inner_seal_deforming = seal_deforming
	queue_redraw()


func set_maintenance_state(
	active: bool,
	conditions: Dictionary = {},
	selected: String = "",
	roster_uses: int = 0,
	scars: Array[String] = [],
	condition_max: int = 3
) -> void:
	maintenance_active = active
	maintenance_conditions = conditions.duplicate()
	maintenance_selected = selected
	maintenance_roster_uses = roster_uses
	maintenance_scars = scars.duplicate()
	maintenance_condition_max = maxi(1, condition_max)
	queue_redraw()


func set_walkback_state(
	active: bool,
	room: String,
	path: Array,
	witnesses: Array,
	hazards: Array
) -> void:
	walkback_active = active
	walkback_room = room
	walkback_path = path.duplicate()
	walkback_witnesses = witnesses.duplicate()
	walkback_hazards = hazards.duplicate()
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var deck := Rect2(Vector2(roundf(size.x * 0.07), roundf(size.y * 0.13)), Vector2(roundf(size.x * 0.86), roundf(size.y * 0.66)))
	var unit := maxf(6.0, floorf(minf(size.x, size.y) / 52.0))
	var font := display_font if display_font else ThemeDB.fallback_font
	var font_size := clampi(int(minf(size.x, size.y) / 30.0), 11, 18)
	var pulse := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 180.0)

	draw_rect(Rect2(Vector2.ZERO, size), VOID)
	draw_rect(deck, PANEL, true)
	_draw_grid(deck, unit)
	draw_rect(deck, PHOSPHOR, false, 2.0)
	_draw_corridors(deck)
	_draw_module(_part(deck, 0.34, 0.35, 0.26, 0.28), "CORE", PHOSPHOR, font, font_size)
	_draw_module(_part(deck, 0.08, 0.30, 0.18, 0.18), "MED-2", AMBER, font, font_size)
	_draw_module(_part(deck, 0.61, 0.17, 0.24, 0.18), "BRIDGE", VIOLET, font, font_size)
	_draw_module(_part(deck, 0.77, 0.51, 0.15, 0.18), "AIRLOCK", PHOSPHOR, font, font_size)
	var aux4_box := _part(deck, 0.37, 0.70, 0.27, 0.17)
	_draw_module(aux4_box, "AUX-4", RED.lerp(AMBER, pulse), font, font_size)
	if inner_seal_deforming:
		_draw_inner_seal(aux4_box, font, maxi(8, font_size - 2), pulse)
	if outcome_id == "purge" or outcome_id == "rupture":
		draw_line(_point(deck, 0.50, 0.78), _point(deck, 0.84, 0.60), RED, 4.0)
	if coherence_value < 50:
		var stress := (50.0 - coherence_value) / 50.0
		var offset := sin(float(Time.get_ticks_msec()) / 90.0) * 8.0 * stress
		draw_line(
			Vector2(deck.position.x + offset, deck.position.y + deck.size.y * 0.56),
			Vector2(deck.end.x, deck.position.y + deck.size.y * 0.56),
			Color(0.83, 0.36, 0.31, 0.18 + stress * 0.2),
			2.0
		)
	if maintenance_active:
		_draw_maintenance_routes(deck, font, maxi(8, font_size - 2), pulse)
	if walkback_active:
		_draw_walkback_overlay(deck, font, maxi(8, font_size - 2), pulse)
	_draw_status(deck, font, font_size)


func _draw_walkback_overlay(deck: Rect2, font: Font, font_size: int, pulse: float) -> void:
	var rooms := {
		"core": _point(deck, 0.47, 0.49),
		"med": _point(deck, 0.17, 0.39),
		"aux": _point(deck, 0.50, 0.78),
		"airlock": _point(deck, 0.85, 0.60),
		"bridge": _point(deck, 0.73, 0.26),
	}
	var graph_edges := [
		["core", "med"], ["med", "aux"], ["aux", "core"],
		["aux", "airlock"], ["airlock", "bridge"], ["bridge", "core"],
	]
	var service_edges := {
		"reserve": ["core", "med"],
		"loop": ["aux", "airlock"],
		"carrier": ["bridge", "core"],
	}
	var graph_color := ICE
	graph_color.a = 0.44
	for edge in graph_edges:
		draw_line(rooms[edge[0]], rooms[edge[1]], graph_color, 1.5)
	for route_key in service_edges:
		var edge: Array = service_edges[route_key]
		if route_key in walkback_hazards:
			draw_line(rooms[edge[0]], rooms[edge[1]], RED, 4.0)

	var previous := Vector2.ZERO
	var has_previous := false
	for index in walkback_path.size():
		var room_key := str(walkback_path[index]).to_lower()
		if not rooms.has(room_key):
			continue
		var point: Vector2 = rooms[room_key]
		if has_previous:
			draw_line(previous, point, AMBER, 3.0)
		previous = point
		has_previous = true
		draw_circle(point, 9.0, VOID)
		draw_circle(point, 9.0, AMBER, false, 2.0)
		draw_string(font, point + Vector2(-3, 4), str(index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, AMBER)
	for route_key in service_edges:
		if route_key in walkback_hazards:
			var hazard_edge: Array = service_edges[route_key]
			var hazard_point: Vector2 = rooms[hazard_edge[0]].lerp(rooms[hazard_edge[1]], 0.5)
			draw_line(hazard_point - Vector2(5, 5), hazard_point + Vector2(5, 5), RED, 2.0)
			draw_line(hazard_point + Vector2(5, -5), hazard_point + Vector2(-5, 5), RED, 2.0)

	for witness_room in ["med", "aux", "bridge"]:
		var witness_point: Vector2 = rooms[witness_room] + Vector2(17, -17)
		if witness_room in walkback_witnesses:
			draw_circle(witness_point, 5.0, PHOSPHOR)
		else:
			draw_circle(witness_point, 5.0, ICE, false, 1.5)

	var current_room := walkback_room.to_lower()
	if rooms.has(current_room):
		var current_point: Vector2 = rooms[current_room]
		var location_color := PHOSPHOR.lerp(AMBER, pulse)
		draw_circle(current_point, 13.0 + pulse * 5.0, location_color, false, 2.0)
		draw_circle(current_point, 3.5, location_color)


func _draw_maintenance_routes(
	deck: Rect2,
	font: Font,
	font_size: int,
	pulse: float
) -> void:
	_draw_maintenance_route(
		deck,
		"reserve",
		_point(deck, 0.26, 0.39),
		_point(deck, 0.34, 0.49),
		"N-R",
		font,
		font_size,
		pulse
	)
	_draw_maintenance_route(
		deck,
		"carrier",
		_point(deck, 0.60, 0.49),
		_point(deck, 0.73, 0.30),
		"C-L",
		font,
		font_size,
		pulse
	)
	_draw_maintenance_route(
		deck,
		"loop",
		_point(deck, 0.50, 0.78),
		_point(deck, 0.84, 0.60),
		"L-C",
		font,
		font_size,
		pulse
	)


func _draw_maintenance_route(
	deck: Rect2,
	key: String,
	start: Vector2,
	finish: Vector2,
	label: String,
	font: Font,
	font_size: int,
	pulse: float
) -> void:
	var condition := int(maintenance_conditions.get(key, 0))
	var color := _maintenance_condition_color(condition)
	if key == "carrier" and maintenance_roster_uses > 0 and condition > 0:
		color = color.lerp(VIOLET, 0.5)
	if key == maintenance_selected:
		color = color.lightened(0.08 * pulse)
	var width := 4.0 if key == maintenance_selected else 2.5
	draw_line(start, finish, color, width)
	for index in range(1, 4):
		var point := start.lerp(finish, float(index) / 4.0)
		draw_rect(Rect2(point - Vector2(3, 3), Vector2(6, 6)), color, true)
	if key in maintenance_scars:
		var scar_point := start.lerp(finish, 0.22)
		var scar_color := RED
		scar_color.a = 0.86
		draw_line(
			scar_point - Vector2(6, 6),
			scar_point + Vector2(6, 6),
			scar_color,
			2.0
		)
		draw_line(
			scar_point + Vector2(6, -6),
			scar_point + Vector2(-6, 6),
			scar_color,
			2.0
		)
	var label_offset := Vector2(5, -6)
	if key == "reserve":
		label_offset = Vector2(-12, 14)
	var label_point := start.lerp(finish, 0.5) + label_offset
	draw_string(
		font,
		label_point,
		"%s %d/%d" % [label, condition, maintenance_condition_max],
		HORIZONTAL_ALIGNMENT_LEFT,
		minf(70.0, deck.size.x * 0.18),
		font_size,
		color
	)


func _maintenance_condition_color(condition: int) -> Color:
	if condition <= 0:
		return RED
	if condition == 1:
		return AMBER
	if condition == 2:
		return ICE
	return PHOSPHOR


func _draw_inner_seal(box: Rect2, font: Font, font_size: int, pulse: float) -> void:
	var failed := outcome_id == "rupture"
	var color := (
		RED
		if failed
		else (PHOSPHOR if inner_seal_braced else RED.lerp(AMBER, pulse))
	)
	var left_x := box.position.x - 6.0
	var right_x := box.end.x + 6.0
	var top_y := box.position.y + 3.0
	var bottom_y := box.end.y - 3.0
	var tick := 9.0
	var line_width := 3.0 if inner_seal_braced else 2.0

	draw_line(Vector2(left_x, top_y), Vector2(left_x, bottom_y), color, line_width)
	draw_line(Vector2(right_x, top_y), Vector2(right_x, bottom_y), color, line_width)
	draw_line(Vector2(left_x, top_y), Vector2(left_x + tick, top_y), color, line_width)
	draw_line(Vector2(left_x, bottom_y), Vector2(left_x + tick, bottom_y), color, line_width)
	draw_line(Vector2(right_x, top_y), Vector2(right_x - tick, top_y), color, line_width)
	draw_line(Vector2(right_x, bottom_y), Vector2(right_x - tick, bottom_y), color, line_width)

	if inner_seal_braced:
		var strut_color := color
		strut_color.a = 0.72
		draw_line(
			Vector2(left_x, top_y),
			Vector2(right_x, bottom_y),
			strut_color,
			1.5
		)
		draw_line(
			Vector2(left_x, bottom_y),
			Vector2(right_x, top_y),
			strut_color,
			1.5
		)

	var label := (
		"SEAL / LOST"
		if failed
		else ("SEAL / BRACED" if inner_seal_braced else "SEAL / DEFORMING")
	)
	draw_string(
		font,
		Vector2(box.position.x, box.position.y - 5.0),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		color
	)


func _draw_grid(deck: Rect2, unit: float) -> void:
	var grid_color := PHOSPHOR
	grid_color.a = 0.08
	for x in range(int(deck.position.x), int(deck.end.x) + 1, int(unit)):
		draw_line(Vector2(x, deck.position.y), Vector2(x, deck.end.y), grid_color)
	for y in range(int(deck.position.y), int(deck.end.y) + 1, int(unit)):
		draw_line(Vector2(deck.position.x, y), Vector2(deck.end.x, y), grid_color)


func _draw_corridors(deck: Rect2) -> void:
	var corridors := [
		[_point(deck, 0.26, 0.39), _point(deck, 0.34, 0.49)],
		[_point(deck, 0.60, 0.49), _point(deck, 0.73, 0.30)],
		[_point(deck, 0.60, 0.53), _point(deck, 0.77, 0.60)],
		[_point(deck, 0.48, 0.63), _point(deck, 0.50, 0.70)],
	]
	for corridor in corridors:
		draw_line(corridor[0], corridor[1], PHOSPHOR, 3.0)


func _draw_module(box: Rect2, label: String, color: Color, font: Font, font_size: int) -> void:
	draw_rect(box, VOID, true)
	draw_rect(box, color, false, 2.0)
	var notch := minf(box.size.x, box.size.y) * 0.16
	draw_line(box.position, box.position + Vector2(notch, 0), color, 4.0)
	draw_line(box.end, box.end - Vector2(notch, 0), color, 4.0)
	draw_string(font, box.position + Vector2(7, font_size + 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_status(deck: Rect2, font: Font, font_size: int) -> void:
	var crew := [
		["VENN", "DEAD", RED],
		[
			"JAE",
			"RESERVE" if jae_supported else (
				"DEAD" if elapsed_minutes >= 10 else ("FAILING" if elapsed_minutes >= 6 else "CRITICAL")
			),
			RED if elapsed_minutes >= 10 and not jae_supported else AMBER
		],
		["MINA", _mina_label(), _mina_color()],
	]
	var y := deck.end.y + font_size + 16.0
	draw_string(font, Vector2(deck.position.x, y - font_size - 5), "CREW SIGNALS", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, PHOSPHOR)
	for entry in crew:
		draw_circle(Vector2(deck.position.x + 5, y - 5), 4.0, entry[2])
		draw_string(font, Vector2(deck.position.x + 16, y), "%s  %s" % [entry[0], entry[1]], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, entry[2])
		y += font_size + 7.0


func _mina_label() -> String:
	match mina_state.to_lower():
		"alive": return "ALIVE"
		"dead": return "DEAD"
		_: return "UNKNOWN"


func _mina_color() -> Color:
	match mina_state.to_lower():
		"alive": return PHOSPHOR
		"dead": return RED
		_: return VIOLET


func _part(deck: Rect2, x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(Vector2(roundf(deck.position.x + deck.size.x * x), roundf(deck.position.y + deck.size.y * y)), Vector2(roundf(deck.size.x * w), roundf(deck.size.y * h)))


func _point(deck: Rect2, x: float, y: float) -> Vector2:
	return Vector2(roundf(deck.position.x + deck.size.x * x), roundf(deck.position.y + deck.size.y * y))
