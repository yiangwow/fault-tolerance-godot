class_name GyroDisplay
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

var gyro_active := false
var angles: Array = []
var targets: Array = []
var ring_index := 0
var latches: Array = []
var settle := 0
var pins := 0
var low_coherence := false
var load_count := 0


func set_gyro_state(
	active: bool,
	angles_input: Array,
	targets_input: Array,
	ring_index_input: int,
	latches_input: Array,
	settle_input: int,
	pins_input: int,
	low_coherence_input: bool,
	load_count_input: int
) -> void:
	gyro_active = active
	if not active:
		angles.clear()
		targets.clear()
		latches.clear()
		ring_index = 0
		settle = 0
		pins = 0
		low_coherence = false
		load_count = 0
		queue_redraw()
		return
	angles = angles_input.duplicate(true)
	targets = targets_input.duplicate(true)
	ring_index = ring_index_input
	latches = latches_input.duplicate(true)
	settle = settle_input
	pins = pins_input
	low_coherence = low_coherence_input
	load_count = load_count_input
	queue_redraw()


func _process(_delta: float) -> void:
	if gyro_active and ring_index >= 0 and ring_index < 4:
		queue_redraw()


func _draw() -> void:
	if not gyro_active:
		return
	var panel := Rect2(Vector2(4, 4), size - Vector2(8, 8))
	if panel.size.x <= 0.0 or panel.size.y <= 0.0:
		return
	var font := display_font if display_font else ThemeDB.fallback_font
	var text_size := clampi(int(minf(size.x, size.y) / 29.0), 8, 12)
	var small_text := maxi(7, text_size - 2)
	var center := Vector2(panel.position.x + panel.size.x * 0.48, panel.position.y + panel.size.y * 0.54)
	var outer_radius := minf(panel.size.x * 0.34, panel.size.y * 0.38)
	var pulse := 0.52 + 0.48 * sin(float(Time.get_ticks_msec()) / 175.0)

	draw_rect(Rect2(Vector2.ZERO, size), VOID)
	draw_rect(panel, PANEL, true)
	draw_rect(panel, PHOSPHOR, false, 1.0)
	_draw_panel_marks(panel)
	draw_string(font, panel.position + Vector2(8.0, 13.0), "M13 / WO-019 / INERTIAL CAGE", HORIZONTAL_ALIGNMENT_LEFT, -1, small_text, ICE)
	_draw_load_trace(panel, center, outer_radius)

	for ring in 4:
		var radius := outer_radius - float(ring) * maxf(13.0, outer_radius * 0.18)
		if radius < 18.0:
			continue
		_draw_ring(center, radius, ring, font, pulse)

	_draw_ring_ledger(panel, font, small_text)
	_draw_center_hub(center, font, small_text)
	_draw_readout(panel, font, small_text)


func _draw_panel_marks(panel: Rect2) -> void:
	var mark_color := Color(GRID, 0.64)
	for row in 4:
		var y := panel.position.y + 22.0 + float(row) * 3.0
		draw_line(Vector2(panel.position.x + 7.0, y), Vector2(panel.end.x - 7.0, y), mark_color, 1.0)
	for x in [panel.position.x + 8.0, panel.end.x - 8.0]:
		draw_line(Vector2(x, panel.position.y + 20.0), Vector2(x, panel.end.y - 8.0), Color(PHOSPHOR, 0.2), 1.0)


func _draw_load_trace(panel: Rect2, center: Vector2, outer_radius: float) -> void:
	var trace_rect := Rect2(Vector2(panel.end.x - panel.size.x * 0.22, panel.position.y + 29.0), Vector2(panel.size.x * 0.18, panel.size.y * 0.56))
	draw_rect(trace_rect, Color(VOID, 0.45), true)
	draw_rect(trace_rect, Color(VIOLET, 0.7), false, 1.0)
	var opacity := 0.3 if not low_coherence else 0.6
	var points := PackedVector2Array()
	for point_index in 8:
		var ratio := float(point_index) / 7.0
		var heading := _angle_at(angles, point_index % 4)
		var displaced := sin(deg_to_rad(float(heading) * 45.0) + float(point_index) * 1.7) * trace_rect.size.x * 0.22
		var x := trace_rect.get_center().x + displaced
		var y := trace_rect.position.y + 8.0 + ratio * (trace_rect.size.y - 16.0)
		points.append(Vector2(x, y))
	if points.size() > 1:
		draw_polyline(points, Color(VIOLET, opacity), 1.4, true)
	for point in points:
		draw_circle(point, 1.4, Color(VIOLET, opacity + 0.2))
	draw_string(display_font if display_font else ThemeDB.fallback_font, trace_rect.position + Vector2(3.0, trace_rect.size.y + 10.0), "LOAD %02d" % maxi(0, load_count), HORIZONTAL_ALIGNMENT_LEFT, trace_rect.size.x, 7, VIOLET)
	var memory_arc := Rect2(center - Vector2(outer_radius + 7.0, outer_radius + 7.0), Vector2((outer_radius + 7.0) * 2.0, (outer_radius + 7.0) * 2.0))
	draw_arc(memory_arc.get_center(), outer_radius + 7.0, deg_to_rad(200.0), deg_to_rad(326.0), 20, Color(VIOLET, opacity), 1.0, true)


func _draw_ring(
	center: Vector2,
	radius: float,
	ring: int,
	font: Font,
	pulse: float
) -> void:
	var latched := _has_latch(ring)
	var current := _angle_at(angles, ring)
	var target := _angle_at(targets, ring)
	var active_ring := ring == ring_index
	var ring_color := PHOSPHOR if latched else GRID.lerp(PHOSPHOR, 0.55)
	if active_ring and not latched:
		ring_color = AMBER
	draw_arc(center, radius, 0.0, TAU, 64, ring_color, 1.5 if active_ring else 1.0, true)
	for tooth in 8:
		var tooth_angle := TAU * float(tooth) / 8.0 - PI * 0.5
		var direction := Vector2(cos(tooth_angle), sin(tooth_angle))
		var tooth_start := center + direction * (radius - 3.0)
		var tooth_end := center + direction * (radius + 3.0)
		draw_line(tooth_start, tooth_end, ring_color, 1.0)
		if radius > 35.0:
			var label_position := center + direction * (radius + 10.0) + Vector2(-3.0, 3.0)
			draw_string(font, label_position, str(tooth), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(ring_color, 0.82))

	var target_direction := _heading_vector(target)
	var target_tip := center + target_direction * (radius - 5.0)
	draw_line(center + target_direction * (radius - 11.0), target_tip, ICE, 1.0)
	draw_circle(target_tip, 2.0, ICE, false, 1.0)

	var pointer_color := PHOSPHOR if latched else AMBER
	var pointer_direction := _heading_vector(current)
	var pointer_tip := center + pointer_direction * (radius - 5.0)
	draw_line(center + pointer_direction * 5.0, pointer_tip, pointer_color, 1.6 if active_ring else 1.2)
	draw_circle(pointer_tip, 2.4 + (0.8 * pulse if active_ring else 0.0), pointer_color)
	if active_ring:
		draw_circle(pointer_tip, 5.0 + pulse * 2.0, Color(AMBER, 0.12), false, 1.0)


func _draw_ring_ledger(panel: Rect2, font: Font, text_size: int) -> void:
	var ledger := Rect2(panel.position + Vector2(8.0, 42.0), Vector2(panel.size.x * 0.17, 51.0))
	draw_rect(ledger, Color(VOID, 0.48), true)
	draw_rect(ledger, Color(GRID, 0.86), false, 1.0)
	for ring in 4:
		var latched := _has_latch(ring)
		var line_color := PHOSPHOR if latched else (AMBER if ring == ring_index else ICE)
		var line := "R%d %03d>%03d" % [ring + 1, _angle_at(angles, ring), _angle_at(targets, ring)]
		draw_string(font, ledger.position + Vector2(4.0, 10.0 + float(ring) * 10.0), line, HORIZONTAL_ALIGNMENT_LEFT, ledger.size.x - 6.0, text_size, line_color)


func _draw_center_hub(center: Vector2, font: Font, text_size: int) -> void:
	draw_circle(center, 15.0, Color(VOID, 0.9))
	draw_circle(center, 15.0, AMBER, false, 1.0)
	draw_circle(center, 3.0, AMBER)
	draw_line(center - Vector2(10.0, 0.0), center + Vector2(10.0, 0.0), Color(AMBER, 0.65), 1.0)
	draw_line(center - Vector2(0.0, 10.0), center + Vector2(0.0, 10.0), Color(AMBER, 0.65), 1.0)
	draw_string(font, center + Vector2(-10.0, 29.0), "DATUM", HORIZONTAL_ALIGNMENT_LEFT, 34.0, text_size, AMBER)


func _draw_readout(panel: Rect2, font: Font, text_size: int) -> void:
	var readout := Rect2(Vector2(panel.position.x + 9.0, panel.end.y - 33.0), Vector2(panel.size.x * 0.66, 24.0))
	draw_rect(readout, Color(VOID, 0.54), true)
	draw_rect(readout, Color(GRID, 0.9), false, 1.0)
	var settle_color := RED if settle <= 0 else (AMBER if settle == 1 else PHOSPHOR)
	draw_string(font, readout.position + Vector2(5.0, 10.0), "SETTLE %02d" % maxi(0, settle), HORIZONTAL_ALIGNMENT_LEFT, readout.size.x * 0.45, text_size, settle_color)
	draw_string(font, readout.position + Vector2(readout.size.x * 0.5, 10.0), "INDEX PINS %02d" % maxi(0, pins), HORIZONTAL_ALIGNMENT_LEFT, readout.size.x * 0.5 - 4.0, text_size, ICE)
	var cage_zeroed := not targets.is_empty() and ring_index >= targets.size()
	draw_string(font, readout.position + Vector2(5.0, 20.0), _readout_state_line(), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, PHOSPHOR if cage_zeroed or _has_latch(ring_index) else AMBER)


func _readout_state_line() -> String:
	if not targets.is_empty() and ring_index >= targets.size():
		return "CAGE ZEROED"
	return "RING %d  %s" % [
		clampi(ring_index + 1, 1, 4),
		"LATCHED" if _has_latch(ring_index) else "SEEKING",
	]


func _heading_vector(detent: int) -> Vector2:
	var degrees := float(posmod(detent, 8)) * 45.0 - 90.0
	return Vector2(cos(deg_to_rad(degrees)), sin(deg_to_rad(degrees)))


func _angle_at(source: Array, index: int) -> int:
	if index < 0 or index >= source.size():
		return 0
	return posmod(int(source[index]), 8)


func _has_latch(ring: int) -> bool:
	return ring in latches
