class_name BusDisplay
extends Control

const VOID := Color("07100e")
const PANEL := Color("0e201c")
const GRID := Color("2b4a40")
const PHOSPHOR := Color("a9d8a4")
const AMBER := Color("e6a448")
const RED := Color("d45b50")
const VIOLET := Color("8877a9")
const ICE := Color("8dbdc0")

@export var display_font: Font

var bus_active := false
var bar_states: Array = []
var target_states: Array = []
var proof_stage := 0
var accepted_proofs: Array = []
var fuse_count := 0
var low_coherence := false
var rejected_count := 0


func set_bus_state(
	active: bool,
	bars: Array,
	target: Array,
	proof_index: int,
	proofs: Array,
	fuses: int,
	low_coherence_input: bool,
	rejected: int
) -> void:
	bus_active = active
	bar_states = bars.duplicate(true)
	target_states = target.duplicate(true)
	proof_stage = proof_index
	accepted_proofs = proofs.duplicate(true)
	fuse_count = fuses
	low_coherence = low_coherence_input
	rejected_count = rejected
	queue_redraw()


func _process(_delta: float) -> void:
	if bus_active:
		queue_redraw()


func _draw() -> void:
	if not bus_active:
		return
	var panel := Rect2(Vector2(4.0, 4.0), size - Vector2(8.0, 8.0))
	if panel.size.x <= 0.0 or panel.size.y <= 0.0:
		return

	var font := display_font if display_font else ThemeDB.fallback_font
	var text_size := clampi(int(minf(size.x, size.y) / 30.0), 8, 12)
	var small_text := maxi(7, text_size - 2)
	var pulse := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 170.0)
	var bus_rect := Rect2(
		panel.position + Vector2(panel.size.x * 0.08, 31.0),
		Vector2(panel.size.x * 0.63, panel.size.y - 49.0)
	)

	draw_rect(Rect2(Vector2.ZERO, size), VOID)
	draw_rect(panel, PANEL, true)
	draw_rect(panel, PHOSPHOR, false, 1.0)
	_draw_panel_marks(panel)
	draw_string(font, panel.position + Vector2(8.0, 13.0), "M14 / WO-020 / SUSPENSION BUS BREAKOUT", HORIZONTAL_ALIGNMENT_LEFT, -1, small_text, ICE)
	_draw_bus(bus_rect, font, text_size, small_text, pulse)
	_draw_readout(panel, font, small_text)


func _draw_panel_marks(panel: Rect2) -> void:
	for row in 4:
		var y := panel.position.y + 20.0 + float(row) * 3.0
		draw_line(Vector2(panel.position.x + 7.0, y), Vector2(panel.end.x - 7.0, y), Color(GRID, 0.58), 1.0)


func _draw_bus(bus_rect: Rect2, font: Font, text_size: int, small_text: int, pulse: float) -> void:
	var labels := ["HAB-A", "MED-2", "AUX-4", "HAB-C"]
	var conductors: Array[Vector2] = []
	var top := bus_rect.position.y + 18.0
	var bottom := bus_rect.end.y - 12.0
	for index in 4:
		var point := Vector2(bus_rect.position.x + bus_rect.size.x * (0.12 + float(index) * 0.255), 0.0)
		conductors.append(point)
		var conductor_color := PHOSPHOR if _has_accepted_load() else ICE
		draw_line(Vector2(point.x, top), Vector2(point.x, bottom), Color(conductor_color, 0.76), 2.0)
		draw_circle(Vector2(point.x, top), 3.0, conductor_color)
		draw_circle(Vector2(point.x, bottom), 3.0, conductor_color, false, 1.2)
		draw_string(font, Vector2(point.x - 18.0, bus_rect.position.y + 8.0), labels[index], HORIZONTAL_ALIGNMENT_CENTER, 36.0, small_text, conductor_color)

	var switch_ys := [
		bus_rect.position.y + bus_rect.size.y * 0.30,
		bus_rect.position.y + bus_rect.size.y * 0.53,
		bus_rect.position.y + bus_rect.size.y * 0.76,
	]
	for index in 3:
		var left: Vector2 = conductors[index]
		var right: Vector2 = conductors[index + 1]
		var switch_y: float = switch_ys[index]
		var closed := _state_at(bar_states, index)
		var target_closed := _state_at(target_states, index)
		_draw_switch(Vector2(left.x, switch_y), Vector2(right.x, switch_y), closed, target_closed, font, small_text, pulse)

	if _has_accepted_load():
		_draw_impossible_trace(conductors, switch_ys, pulse)


func _draw_switch(left: Vector2, right: Vector2, closed: bool, target_closed: bool, font: Font, text_size: int, pulse: float) -> void:
	var terminal_radius := 3.0
	var actual_color := AMBER if closed else RED
	var target_color := ICE if target_closed else Color(ICE, 0.55)
	var span := right.x - left.x
	draw_circle(left, terminal_radius, AMBER)
	draw_circle(right, terminal_radius, AMBER)

	if closed:
		draw_line(left + Vector2(terminal_radius, 0.0), right - Vector2(terminal_radius, 0.0), actual_color, 3.0)
	else:
		var knife_end := left + Vector2(span * 0.58, -maxf(10.0, span * 0.12))
		draw_line(left + Vector2(terminal_radius, 0.0), knife_end, actual_color, 3.0)
		draw_circle(knife_end, 2.0, actual_color)
		draw_line(right - Vector2(terminal_radius + 8.0, 0.0), right - Vector2(terminal_radius, 0.0), Color(AMBER, 0.52), 2.0)

	if target_closed != closed:
		var ghost_y := left.y + 7.0
		for segment in 4:
			var start := left.x + 7.0 + float(segment) * span * 0.23
			draw_line(Vector2(start, ghost_y), Vector2(start + span * 0.12, ghost_y), Color(target_color, 0.72), 1.0)
		draw_string(font, Vector2(left.x, left.y - 7.0), "TGT %s" % ("CLS" if target_closed else "OPEN"), HORIZONTAL_ALIGNMENT_LEFT, span, text_size, target_color)

	var state_label := "CLOSED" if closed else "OPEN"
	var label_color := actual_color.lerp(PHOSPHOR, pulse * 0.12) if closed else actual_color
	draw_string(font, Vector2(left.x, left.y + 15.0), state_label, HORIZONTAL_ALIGNMENT_CENTER, span, text_size, label_color)


func _draw_impossible_trace(conductors: Array[Vector2], switch_ys: Array, pulse: float) -> void:
	var trace_alpha := 0.58 if low_coherence else 0.82
	for index in range(mini(3, switch_ys.size())):
		var y := float(switch_ys[index]) - 5.0
		var left := Vector2(conductors[index].x, y)
		var right := Vector2(conductors[index + 1].x, y)
		draw_line(left, right, Color(VIOLET, trace_alpha), 2.0)
		if low_coherence:
			draw_line(left + Vector2(0.0, 3.0), right + Vector2(0.0, 3.0), Color(VIOLET, 0.28), 1.0)
		for node in 3:
			var trace_node := left.lerp(right, float(node + 1) / 4.0)
			draw_circle(trace_node, 2.0 + pulse, Color(VIOLET, trace_alpha + 0.1))


func _draw_readout(panel: Rect2, font: Font, text_size: int) -> void:
	var readout := Rect2(
		Vector2(panel.end.x - panel.size.x * 0.23, panel.position.y + 31.0),
		Vector2(panel.size.x * 0.19, panel.size.y - 44.0)
	)
	draw_rect(readout, Color(VOID, 0.60), true)
	draw_rect(readout, Color(VIOLET, 0.72), false, 1.0)
	draw_string(font, readout.position + Vector2(5.0, 12.0), "PROOF LOG", HORIZONTAL_ALIGNMENT_LEFT, readout.size.x - 10.0, text_size, VIOLET)
	var stage_color := PHOSPHOR if _has_accepted_load() else AMBER
	draw_string(font, readout.position + Vector2(5.0, 31.0), "STAGE %02d/03" % mini(proof_stage + 1, 3), HORIZONTAL_ALIGNMENT_LEFT, readout.size.x - 10.0, text_size, stage_color)
	draw_string(font, readout.position + Vector2(5.0, 44.0), "ACCEPTED %02d" % accepted_proofs.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, VIOLET)
	var fuse_color := RED if fuse_count <= 0 else (AMBER if fuse_count == 1 else PHOSPHOR)
	draw_string(font, readout.position + Vector2(5.0, 61.0), "FUSES %02d" % maxi(0, fuse_count), HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, fuse_color)
	draw_string(font, readout.position + Vector2(5.0, 74.0), "REJECTED %02d" % maxi(0, rejected_count), HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, RED)

	var trace := Rect2(readout.position + Vector2(5.0, 88.0), Vector2(readout.size.x - 10.0, readout.size.y - 96.0))
	if trace.size.y <= 8.0:
		return
	draw_rect(trace, Color(VOID, 0.40), true)
	for row in 4:
		var y := trace.position.y + trace.size.y * float(row + 1) / 5.0
		draw_line(Vector2(trace.position.x, y), Vector2(trace.end.x, y), Color(GRID, 0.52), 1.0)
	if _has_accepted_load():
		var trace_points := PackedVector2Array()
		for index in 6:
			var x := trace.position.x + trace.size.x * float(index) / 5.0
			var y := trace.position.y + trace.size.y * (0.30 + 0.11 * float((index + proof_stage) % 3))
			trace_points.append(Vector2(x, y))
		draw_polyline(trace_points, VIOLET, 1.5, true)
		draw_string(font, Vector2(trace.position.x, readout.end.y - 6.0), "LOAD PERSISTS", HORIZONTAL_ALIGNMENT_LEFT, trace.size.x, 7, VIOLET)
	else:
		draw_string(font, Vector2(trace.position.x, trace.position.y + 10.0), "NO LOAD", HORIZONTAL_ALIGNMENT_LEFT, trace.size.x, 7, ICE)


func _state_at(source: Array, index: int) -> bool:
	return index >= 0 and index < source.size() and bool(source[index])


func _has_accepted_load() -> bool:
	return proof_stage > 0 or not accepted_proofs.is_empty()
