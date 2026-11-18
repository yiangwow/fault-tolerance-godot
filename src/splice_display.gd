class_name SpliceDisplay
extends Control

const VOID := Color("07100e")
const PANEL := Color("0e201c")
const PHOSPHOR := Color("a9d8a4")
const AMBER := Color("e6a448")
const RED := Color("d45b50")
const VIOLET := Color("8877a9")
const ICE := Color("8dbdc0")

@export var display_font: Font

var splice_active := false
var target_codes: Array = []
var feed_codes: Dictionary = {}
var splice_index := 0
var choices: Array = []
var tension := 0
var misfeeds := 0
var low_coherence := false


func set_splice_state(
	active: bool,
	target_codes_input: Array,
	feed_codes_input: Dictionary,
	splice_index_input: int,
	choices_input: Array,
	tension_input: int,
	misfeeds_input: int,
	low_coherence_input: bool
) -> void:
	splice_active = active
	target_codes = target_codes_input.duplicate(true)
	feed_codes = feed_codes_input.duplicate(true)
	splice_index = splice_index_input
	choices = choices_input.duplicate(true)
	tension = tension_input
	misfeeds = misfeeds_input
	low_coherence = low_coherence_input
	queue_redraw()


func _process(_delta: float) -> void:
	if splice_active:
		queue_redraw()


func _draw() -> void:
	if not splice_active:
		return

	var panel := Rect2(Vector2(4, 4), size - Vector2(8, 8))
	if panel.size.x <= 0.0 or panel.size.y <= 0.0:
		return
	var font := display_font if display_font else ThemeDB.fallback_font
	var text_size := clampi(int(minf(size.x, size.y) / 30.0), 8, 12)
	var small_text := maxi(7, text_size - 2)
	var pulse := 0.55 + 0.45 * sin(float(Time.get_ticks_msec()) / 150.0)
	var feed_names := ["CORE", "TETHER", "BADGE"]
	var feed_keys := ["core", "tether", "badge"]

	draw_rect(Rect2(Vector2.ZERO, size), VOID)
	draw_rect(panel, PANEL, true)
	draw_rect(panel, PHOSPHOR, false, 1.0)
	_draw_panel_marks(panel)
	draw_string(font, panel.position + Vector2(8, 13), "M12 / WO-018 / DUPLEX LOG SPLICER", HORIZONTAL_ALIGNMENT_LEFT, -1, small_text, ICE)

	var tape_top := panel.position.y + 31.0
	var tape_bottom := panel.end.y - 13.0
	var row_height := maxf(14.0, (tape_bottom - tape_top) / 6.0)
	var tape_height := row_height * 6.0
	var tape_width := clampf(panel.size.x * 0.135, 30.0, 52.0)
	var left := panel.position.x + 9.0
	var gap := maxf(5.0, panel.size.x * 0.025)
	var gate_width := clampf(panel.size.x * 0.15, 38.0, 60.0)
	var gate := Rect2(Vector2(panel.end.x - gate_width - 9.0, tape_top), Vector2(gate_width, tape_height))

	for feed_index in feed_names.size():
		var tape := Rect2(Vector2(left + feed_index * (tape_width + gap), tape_top), Vector2(tape_width, tape_height))
		_draw_tape(tape, feed_names[feed_index], _feed_rows(feed_keys[feed_index]), feed_keys[feed_index], font, small_text, row_height)

	_draw_gate(gate, font, small_text, row_height, pulse)
	_draw_completed_splices(left, tape_top, tape_width, gap, gate, row_height, pulse)
	_draw_gate_damage(gate, row_height)

	var tension_color := RED if tension <= 0 else (AMBER if tension == 1 else ICE)
	var status := "TENSION %d  /  MISFEEDS %d" % [maxi(0, tension), maxi(0, misfeeds)]
	draw_string(font, Vector2(panel.position.x + 8.0, panel.end.y - 4.0), status, HORIZONTAL_ALIGNMENT_LEFT, -1, small_text, tension_color)


func _draw_panel_marks(panel: Rect2) -> void:
	var line_color := Color(PHOSPHOR, 0.13)
	for column in 3:
		var x := panel.position.x + 6.0 + float(column) * 3.0
		draw_line(Vector2(x, panel.position.y + 20.0), Vector2(x, panel.end.y - 9.0), line_color, 1.0)


func _draw_tape(tape: Rect2, label: String, rows: Array, feed_key: String, font: Font, text_size: int, row_height: float) -> void:
	draw_string(font, Vector2(tape.position.x, tape.position.y - 5.0), label, HORIZONTAL_ALIGNMENT_LEFT, tape.size.x, text_size, PHOSPHOR)
	draw_rect(tape, Color(VOID, 0.78), true)
	draw_rect(tape, PHOSPHOR, false, 1.0)
	for row in 6:
		var row_rect := Rect2(Vector2(tape.position.x, tape.position.y + float(row) * row_height), Vector2(tape.size.x, row_height))
		var completed := _completed_choice_for_feed_row(feed_key, row) >= 0
		if completed:
			var impression := Color(VIOLET, 0.12 if not low_coherence else 0.28)
			draw_rect(Rect2(row_rect.position + Vector2(3.0, 1.0), row_rect.size - Vector2(2.0, 2.0)), impression, true)
		if row == splice_index and not completed:
			var current := Color(AMBER, 0.18 + 0.22 * (0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 150.0)))
			draw_rect(row_rect.grow(-1.0), current, true)
		draw_line(Vector2(row_rect.position.x, row_rect.end.y), Vector2(row_rect.end.x, row_rect.end.y), Color(PHOSPHOR, 0.25), 1.0)
		_draw_perforations(row_rect, _code_at(rows, row), PHOSPHOR if not completed else AMBER)
		_draw_sprockets(row_rect)


func _draw_gate(gate: Rect2, font: Font, text_size: int, row_height: float, pulse: float) -> void:
	draw_string(font, Vector2(gate.position.x, gate.position.y - 5.0), "GATE", HORIZONTAL_ALIGNMENT_LEFT, gate.size.x, text_size, AMBER)
	draw_rect(gate, Color(VOID, 0.82), true)
	draw_rect(gate, AMBER, false, 1.0)
	for row in 6:
		var row_rect := Rect2(Vector2(gate.position.x, gate.position.y + float(row) * row_height), Vector2(gate.size.x, row_height))
		var completed := row < choices.size()
		if row == splice_index and not completed:
			draw_rect(row_rect.grow(-1.0), Color(AMBER, 0.13 + 0.24 * pulse), true)
		draw_line(Vector2(row_rect.position.x, row_rect.end.y), Vector2(row_rect.end.x, row_rect.end.y), Color(AMBER, 0.32), 1.0)
		_draw_perforations(row_rect.grow_individual(-7.0, 0.0, -7.0, 0.0), _code_at(target_codes, row), AMBER)
		if completed:
			draw_line(row_rect.position + Vector2(4.0, 3.0), row_rect.end - Vector2(4.0, 3.0), Color(PHOSPHOR, 0.7), 1.0)


func _draw_perforations(row_rect: Rect2, code: int, color: Color) -> void:
	var spacing := row_rect.size.x / 4.0
	var radius := clampf(minf(2.4, row_rect.size.y * 0.16), 1.2, 2.4)
	for bit in 3:
		var center := Vector2(row_rect.position.x + spacing * float(bit + 1), row_rect.position.y + row_rect.size.y * 0.5)
		var punched := (code & (1 << (2 - bit))) != 0
		draw_circle(center, radius, VOID if punched else Color(color, 0.18))
		if not punched:
			draw_circle(center, radius, color, false, 0.7)


func _draw_sprockets(row_rect: Rect2) -> void:
	for x in [row_rect.position.x + 2.5, row_rect.end.x - 2.5]:
		draw_circle(Vector2(x, row_rect.position.y + 3.0), 0.9, PHOSPHOR)
		draw_circle(Vector2(x, row_rect.end.y - 3.0), 0.9, PHOSPHOR)


func _draw_completed_splices(left: float, tape_top: float, tape_width: float, gap: float, gate: Rect2, row_height: float, pulse: float) -> void:
	for choice_index in choices.size():
		if choice_index >= 6:
			break
		var source_key := _choice_feed(choices[choice_index])
		var feed_index := ["core", "tether", "badge"].find(source_key)
		if feed_index < 0:
			continue
		var source_row := _choice_row(choices[choice_index], choice_index)
		if source_row < 0 or source_row >= 6:
			continue
		var source := Vector2(left + float(feed_index) * (tape_width + gap) + tape_width, tape_top + (float(source_row) + 0.5) * row_height)
		var target := Vector2(gate.position.x, tape_top + (float(choice_index) + 0.5) * row_height)
		var splice_color := PHOSPHOR.lerp(AMBER, 0.45 + 0.25 * pulse)
		draw_line(source, target, splice_color, 1.5)
		draw_circle(source, 2.1, AMBER)
		draw_circle(target, 2.1, AMBER)


func _draw_gate_damage(gate: Rect2, row_height: float) -> void:
	var damage_count := mini(6, maxi(0, misfeeds))
	for damage in damage_count:
		var y := gate.position.y + (float(damage) + 0.5) * row_height
		var x := gate.end.x - 4.0 - float(damage % 2) * 5.0
		draw_line(Vector2(x - 4.0, y - 3.0), Vector2(x + 3.0, y + 3.0), RED, 1.4)
		draw_line(Vector2(x - 2.0, y + 4.0), Vector2(x + 4.0, y - 4.0), Color(RED, 0.7), 1.0)


func _feed_rows(feed_key: String) -> Array:
	var rows: Variant = feed_codes.get(feed_key, feed_codes.get(feed_key.to_upper(), []))
	return rows if rows is Array else []


func _code_at(codes: Array, row: int) -> int:
	if row < 0 or row >= codes.size():
		return 0
	var value = codes[row]
	if value is String:
		var binary_code := 0
		for digit in value:
			binary_code = (binary_code << 1) | (1 if digit == "1" else 0)
		return binary_code & 7
	return int(value) & 7


func _completed_choice_for_feed_row(feed_key: String, row: int) -> int:
	for choice_index in choices.size():
		var choice = choices[choice_index]
		if _choice_feed(choice) == feed_key and _choice_row(choice, choice_index) == row:
			return choice_index
	return -1


func _choice_feed(choice) -> String:
	if choice is Dictionary:
		return str(choice.get("feed", choice.get("source", choice.get("channel", "")))).to_lower()
	if choice is Array and not choice.is_empty():
		return str(choice[0]).to_lower()
	if choice is String:
		return choice.to_lower()
	return ""


func _choice_row(choice, fallback: int) -> int:
	if choice is Dictionary:
		return int(choice.get("row", choice.get("feed_row", fallback)))
	if choice is Array and choice.size() > 1:
		return int(choice[1])
	return fallback
