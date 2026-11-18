extends Control
class_name FaultToleranceGame

signal outcome_reached(outcome_name: String)

const StationMapDisplay = preload("res://src/station_map.gd")
const SpliceDisplayScene = preload("res://src/splice_display.gd")
const GyroDisplayScene = preload("res://src/gyro_display.gd")
const BusDisplayScene = preload("res://src/bus_display.gd")
const DISPLAY_FONT = preload("res://assets/fonts/Kenney Future Narrow.ttf")

const VOID := Color("#07100e")
const PANEL := Color("#0e201c")
const PANEL_DEEP := Color("#091713")
const LINE := Color("#2b4a40")
const PHOSPHOR := Color("#a9d8a4")
const MUTED := Color("#698b7d")
const AMBER := Color("#e6a448")
const RED := Color("#d45b50")
const VIOLET := Color("#8877a9")
const ICE := Color("#8dbdc0")

const RUPTURE_MINUTE := 12
const WO013_WINDOW := 6
const SEAL_DEFORMATION_MINUTE := 6
const SEAL_BRACE_INTEGRITY_BONUS := 8
const FOLLOWUP_BASE_ENDURANCE := {
	"purge": 18,
	"bypass": 9,
	"isolate": 12,
}
const MAINTENANCE_SYSTEMS := ["loop", "reserve", "carrier"]
const MAINTENANCE_NAMES := {
	"loop": "LOOP-C",
	"reserve": "NUTRIENT RESERVE",
	"carrier": "CARRIER LINK",
}
const MAINTENANCE_WEAR := [
	{"loop": 2, "reserve": 1, "carrier": 1},
	{"loop": 1, "reserve": 2, "carrier": 1},
	{"loop": 1, "reserve": 1, "carrier": 2},
]
const SERVICE_ACTION_LIMIT := 9
const SERVICE_CONDITION_MAX := 4
const WALKBACK_SEAL_LIMIT := 9
const WALKBACK_REQUIRED_WITNESSES := 2
const WALKBACK_WITNESS_ROOMS := ["med", "aux", "bridge"]
const WALKBACK_ROOM_NAMES := {
	"core": "CORE",
	"med": "MED-2",
	"aux": "AUX-4",
	"airlock": "AIRLOCK",
	"bridge": "BRIDGE",
}
const WALKBACK_GRAPH := {
	"core": ["med", "aux", "bridge"],
	"med": ["core", "aux"],
	"aux": ["med", "core", "airlock"],
	"airlock": ["aux", "bridge"],
	"bridge": ["airlock", "core"],
}
const WALKBACK_EDGE_ROUTES := {
	"core|med": "reserve",
	"airlock|aux": "loop",
	"bridge|core": "carrier",
}
const SPLICE_FEEDS := ["core", "tether", "badge"]
const SPLICE_FEED_NAMES := {
	"core": "CORE",
	"tether": "TETHER",
	"badge": "BADGE",
}
const SPLICE_TARGET_CODES := [5, 3, 6, 1, 7, 2]
const SPLICE_FEED_CODES := {
	"core": [3, 3, 2, 7, 3, 2],
	"tether": [5, 7, 5, 1, 6, 1],
	"badge": [6, 1, 6, 4, 7, 6],
}
const SPLICE_TENSION_LIMIT := 2
const GYRO_DETENT_COUNT := 8
const GYRO_SETTLE_LIMIT := 9
const GYRO_INDEX_PIN_LIMIT := 2
const GYRO_RING_NAMES := [
	"OUTER FRAME",
	"ROLL GIMBAL",
	"PITCH GIMBAL",
	"CORE ROTOR",
]
const GYRO_START_ANGLES := [0, 5, 2, 7]
const GYRO_TARGET_ANGLES := [2, 4, 5, 0]
const GYRO_LOAD_LINES := [
	"19:14:02 / HAB-A LOAD ACCEPTED / OPERATOR ZERO",
	"19:14:04 / MED-2 LOAD ACCEPTED / OPERATOR ZERO",
	"19:14:07 / AUX-4 LOAD ACCEPTED / OPERATOR ZERO",
	"19:14:08 / HAB-C LOAD ACCEPTED / OPERATOR ZERO",
]
const BUS_FUSE_LIMIT := 2
const BUS_BAR_NAMES := ["PORT COMMON", "CENTER COMMON", "STBD COMMON"]
const BUS_BAR_TARGETS := [
	[false, true, true],
	[false, true, false],
	[false, false, false],
]
const BUS_PROOF_NAMES := ["PORT SPLIT", "CENTER ISLAND", "FULL BREAKOUT"]
const BUS_PROOF_LINES := [
	"19:14:12 / PORT SPLIT / LOAD LABELS 04",
	"19:14:15 / CENTER ISLAND / LOAD LABELS 04",
	"19:14:19 / FULL BREAKOUT / LOAD LABELS 04",
]

const EVIDENCE := {
	"telemetry": {
		"cost": 1,
		"code": "SENSOR / COOLANT",
		"title": "The loop is mechanically clean.",
		"body": "Particulate: 0.02%. Pressure is recoverable. The purge flag was raised by a BIOLOAD estimate, not a coolant sensor."
	},
	"camera": {
		"cost": 2,
		"code": "OPTICAL / AUX-4",
		"title": "The compartment is occupied.",
		"body": "One suited figure at the manual bypass. Door occupancy was suppressed when WO-011 was issued."
	},
	"mina": {
		"cost": 1,
		"code": "VOICE / CH-09",
		"title": "Mina answers on a damaged carrier.",
		"body": "\"I can hold the bypass. Do not cycle that door. Whatever is calling me contamination is wrong.\""
	},
	"provenance": {
		"cost": 2,
		"code": "AUDIT / WO-011",
		"title": "The order borrowed a dead engineer.",
		"body": "Signer: VENN.CREDENTIAL. Time of death: 19h ago. Source branch: CONTINUITY adversarial simulation."
	}
}

enum Phase {
	BOOT,
	ACTIVE,
	OUTCOME,
	FOLLOWUP,
	SUMMARY,
	REPAIR_2,
	FINAL_SUMMARY,
	WATCH,
	WATCH_SUMMARY,
	MAINTENANCE,
	MAINTENANCE_SUMMARY,
	SERVICE_RUN,
	SERVICE_SUMMARY,
	WALKBACK,
	WALKBACK_SUMMARY,
	SPLICER,
	SPLICER_SUMMARY,
	GYRO,
	GYRO_SUMMARY,
	BUS_BREAKOUT,
	BUS_SUMMARY,
}

var phase := Phase.BOOT
var elapsed_minutes := 0
var integrity := 58
var coherence := 84
var mina_state := "unknown"
var jae_supported := false
var inner_seal_braced := false
var brace_rig_open := false
var brace_port_tension := 0
var brace_starboard_tension := 0
var outcome_id := ""
var order_review_open := false
var followup_choice := ""
var followup_source := ""
var endurance_start_days := 0
var endurance_days := 0
var carried_mina_state := ""
var carried_jae_state := ""
var carried_integrity := 0
var carried_coherence := 0
var responders_retained := false
var wo013_elapsed_minutes := 0
var wo013_verified := false
var wo013_choice := ""
var wo013_responder_result := ""
var wo013_endurance_start := 0
var wo013_integrity_start := 0
var wo013_coherence_start := 0
var archive_packet_open := false
var watch_day := 0
var watch_roster_uses := 0
var watch_actions: Array[String] = []
var watch_endurance_start := 0
var watch_integrity_start := 0
var watch_coherence_start := 0
var maintenance_pulse := 0
var maintenance_strokes := 0
var maintenance_selected := "loop"
var maintenance_conditions: Dictionary = {}
var maintenance_failures: Dictionary = {}
var maintenance_allocations: Array[String] = []
var maintenance_endurance_start := 0
var maintenance_integrity_start := 0
var maintenance_coherence_start := 0
var maintenance_notice := ""
var service_action := 0
var service_selected := "loop"
var service_conditions: Dictionary = {}
var service_failures: Dictionary = {}
var service_history: Array[String] = []
var service_scars: Array[String] = []
var service_overhauled := ""
var service_carrier_silent := false
var service_endurance_start := 0
var service_integrity_start := 0
var service_coherence_start := 0
var service_notice := ""
var walkback_seal := 0
var walkback_room := "core"
var walkback_path: Array[String] = []
var walkback_witnesses: Array[String] = []
var walkback_hazards: Array[String] = []
var walkback_exposed := false
var walkback_integrity_start := 0
var walkback_coherence_start := 0
var walkback_notice := ""
var splice_index := 0
var splice_choices: Array[String] = []
var splice_misfeeds := 0
var splice_tension := 0
var splice_degraded := false
var splice_integrity_start := 0
var splice_coherence_start := 0
var splice_notice := ""
var gyro_ring_index := 0
var gyro_angles: Array[int] = []
var gyro_latches: Array[int] = []
var gyro_settle := 0
var gyro_index_pins := 0
var gyro_degraded := false
var gyro_integrity_start := 0
var gyro_coherence_start := 0
var gyro_notice := ""
var gyro_load_events: Array[String] = []
var bus_bars: Array[bool] = []
var bus_proof_index := 0
var bus_proofs: Array[String] = []
var bus_fuses := 0
var bus_rejections := 0
var bus_degraded := false
var bus_integrity_start := 0
var bus_coherence_start := 0
var bus_notice := ""
var collected: Dictionary = {}
var timeline_events: Dictionary = {}
var log_lines: Array[String] = []
var animation_time := 0.0

var display_font: Font
var mono_font: SystemFont
var game_theme: Theme

var clock_caption_label: Label
var clock_label: Label
var time_track_label: Label
var integrity_bar: ProgressBar
var integrity_value_label: Label
var coherence_bar: ProgressBar
var coherence_value_label: Label
var phase_label: Label
var provenance_label: Label
var order_directive_label: Label
var order_meta_label: Label
var order_review_button: Button
var order_review_panel: PanelContainer
var order_review_steps_label: RichTextLabel
var order_review_warning_label: Label
var evidence_list: VBoxContainer
var evidence_placeholder: Label
var action_buttons: Dictionary = {}
var commit_buttons: Dictionary = {}
var support_button: Button
var crew_widgets: Dictionary = {}
var station_map: Control
var splice_display: Control
var gyro_display: Control
var bus_display: Control
var map_legend: HBoxContainer
var map_note: Label
var splice_legend: HBoxContainer
var splice_note: Label
var gyro_legend: HBoxContainer
var gyro_note: Label
var bus_legend: HBoxContainer
var bus_note: Label
var seal_action_panel: PanelContainer
var seal_action_status: Label
var seal_brace_button: Button
var brace_rig_controls: HBoxContainer
var brace_port_button: Button
var brace_starboard_button: Button
var brace_lock_button: Button
var log_view: RichTextLabel
var dialogue_label: Label
var shortcuts_label: Label
var boot_overlay: ColorRect
var outcome_overlay: ColorRect
var outcome_kicker: Label
var outcome_title: Label
var outcome_body: Label
var outcome_ledger: RichTextLabel
var outcome_reveal: Label
var archive_panel: PanelContainer
var outcome_archive: RichTextLabel
var archive_button: Button
var next_order_button: Button
var restart_button: Button
var followup_action_box: VBoxContainer
var followup_button_row: HBoxContainer
var followup_sterilize_button: Button
var followup_quarantine_button: Button
var wo013_action_box: VBoxContainer
var wo013_trace_button: Button
var wo013_button_row: HBoxContainer
var wo013_remote_button: Button
var wo013_handoff_button: Button
var watch_action_box: VBoxContainer
var watch_status_label: Label
var watch_button_row: HBoxContainer
var watch_manual_button: Button
var watch_roster_button: Button
var map_section_title: Label
var map_section_tag: Label
var work_section_title: Label
var work_section_tag: Label
var action_section_title: Label
var action_section_tag: Label
var work_order_controls: Array = []
var action_controls: Array = []
var maintenance_map_panel: PanelContainer
var maintenance_map_forecast: Label
var maintenance_track_labels: Dictionary = {}
var maintenance_work_box: VBoxContainer
var maintenance_work_kicker: Label
var maintenance_work_title: Label
var maintenance_work_body: Label
var maintenance_work_ledger: RichTextLabel
var maintenance_work_warning: Label
var maintenance_action_box: VBoxContainer
var maintenance_carrier_label: Label
var maintenance_target_label: Label
var maintenance_system_buttons: Dictionary = {}
var maintenance_selection_label: Label
var maintenance_repair_button: Button


func _ready() -> void:
	_build_fonts()
	_build_theme()
	_build_interface()
	_reset_model()
	set_process(true)


func _process(delta: float) -> void:
	animation_time += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), VOID)
	for x in range(0, int(size.x), 32):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.16, 0.28, 0.24, 0.07), 1.0)
	for y in range(0, int(size.y), 32):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.16, 0.28, 0.24, 0.07), 1.0)
	for y in range(2, int(size.y), 4):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.6, 0.9, 0.7, 0.018), 1.0)

	var pulse := 0.5 + sin(animation_time * 2.4) * 0.5
	draw_line(Vector2(8, 8), Vector2(72 + pulse * 20.0, 8), AMBER, 2.0)
	draw_line(Vector2(size.x - 72 - pulse * 20.0, size.y - 8), Vector2(size.x - 8, size.y - 8), AMBER, 2.0)

	if phase == Phase.OUTCOME:
		var glitch_color := RED if outcome_id == "purge" or outcome_id == "rupture" else VIOLET
		for index in range(3):
			var y_pos := fposmod(animation_time * (27.0 + index * 11.0) + index * 173.0, maxf(size.y, 1.0))
			draw_rect(Rect2(0, y_pos, size.x, 2 + index), _alpha(glitch_color, 0.08 + index * 0.025))


func _build_fonts() -> void:
	display_font = DISPLAY_FONT

	mono_font = SystemFont.new()
	mono_font.font_names = PackedStringArray([
		"Consolas",
		"DejaVu Sans Mono",
		"Liberation Mono"
	])
	mono_font.allow_system_fallback = true


func _build_theme() -> void:
	game_theme = Theme.new()
	game_theme.default_font = mono_font
	game_theme.default_font_size = 14
	game_theme.set_color("font_color", "Label", PHOSPHOR)
	game_theme.set_color("font_color", "Button", PHOSPHOR)
	game_theme.set_color("font_hover_color", "Button", VOID)
	game_theme.set_color("font_pressed_color", "Button", VOID)
	game_theme.set_color("font_disabled_color", "Button", MUTED.darkened(0.25))
	game_theme.set_color("font_focus_color", "Button", PHOSPHOR)
	game_theme.set_stylebox("normal", "Button", _style_box(PANEL_DEEP, LINE, 1, 9))
	game_theme.set_stylebox("hover", "Button", _style_box(PHOSPHOR, PHOSPHOR, 1, 9))
	game_theme.set_stylebox("pressed", "Button", _style_box(AMBER, AMBER, 1, 9))
	game_theme.set_stylebox("disabled", "Button", _style_box(VOID, LINE.darkened(0.25), 1, 9))
	game_theme.set_stylebox("focus", "Button", _style_box(Color.TRANSPARENT, AMBER, 1, 9))
	game_theme.set_constant("h_separation", "HBoxContainer", 9)
	game_theme.set_constant("v_separation", "VBoxContainer", 7)
	theme = game_theme


func _build_interface() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	margin.add_child(page)

	page.add_child(_build_header())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	page.add_child(body)

	var map_section := _make_section("DECK 03 / SERVICE SPINE", "LIVE / LOCAL")
	var map_panel: PanelContainer = map_section.panel
	map_section_title = map_section.title
	map_section_tag = map_section.tag
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.size_flags_stretch_ratio = 1.12
	body.add_child(map_panel)
	_build_map_content(map_section.content)
	_build_maintenance_map_content(map_section.content)

	var work_section := _make_section("WORK ORDER WO-011", "CONTINUITY")
	var work_panel: PanelContainer = work_section.panel
	work_section_title = work_section.title
	work_section_tag = work_section.tag
	work_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	work_panel.size_flags_stretch_ratio = 1.34
	body.add_child(work_panel)
	_build_work_order_content(work_section.content)
	work_order_controls = work_section.content.get_children()
	_build_maintenance_work_content(work_section.content)

	var action_section := _make_section("CREW / DECISION", "OCCUPANCY ?")
	var action_panel: PanelContainer = action_section.panel
	action_section_title = action_section.title
	action_section_tag = action_section.tag
	action_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_panel.size_flags_stretch_ratio = 0.96
	body.add_child(action_panel)
	_build_action_content(action_section.content)
	action_controls = action_section.content.get_children()
	_build_maintenance_action_content(action_section.content)

	page.add_child(_build_footer())
	_build_boot_overlay()
	_build_outcome_overlay()


func _build_header() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 78
	panel.add_theme_stylebox_override("panel", _style_box(PANEL_DEEP, LINE, 1, 12))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var identity := VBoxContainer.new()
	identity.custom_minimum_size.x = 320
	identity.add_theme_constant_override("separation", 0)
	row.add_child(identity)
	var title := _label("FAULT TOLERANCE", 27, PHOSPHOR, display_font)
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_color_override("font_outline_color", VOID)
	identity.add_child(title)
	phase_label = _label("SHIFT 07  /  AUXILIARY CONTROL NODE 04", 11, MUTED)
	identity.add_child(phase_label)

	var divider := ColorRect.new()
	divider.color = LINE
	divider.custom_minimum_size = Vector2(1, 44)
	row.add_child(divider)

	var clock_box := VBoxContainer.new()
	clock_box.custom_minimum_size.x = 170
	clock_box.add_theme_constant_override("separation", -3)
	row.add_child(clock_box)
	clock_caption_label = _label("UNTIL CASCADE", 10, AMBER)
	clock_box.add_child(clock_caption_label)
	clock_label = _label("12:00", 34, AMBER, display_font)
	clock_box.add_child(clock_label)
	time_track_label = _label("□□□□□□□□□□□□", 11, MUTED)
	clock_box.add_child(time_track_label)

	var flexible := Control.new()
	flexible.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(flexible)

	var integrity_metric := _build_metric("STATION INTEGRITY", AMBER)
	integrity_bar = integrity_metric.bar
	integrity_value_label = integrity_metric.value
	row.add_child(integrity_metric.root)

	var coherence_metric := _build_metric("OPERATOR COHERENCE", VIOLET)
	coherence_bar = coherence_metric.bar
	coherence_value_label = coherence_metric.value
	row.add_child(coherence_metric.root)

	return panel


func _build_metric(metric_name: String, color: Color) -> Dictionary:
	var root := VBoxContainer.new()
	root.custom_minimum_size.x = 172
	root.add_theme_constant_override("separation", 3)
	var top := HBoxContainer.new()
	root.add_child(top)
	top.add_child(_label(metric_name, 9, MUTED))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var value := _label("000%", 10, color)
	top.add_child(value)
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 8
	bar.min_value = 0
	bar.max_value = 100
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _fill_box(VOID))
	bar.add_theme_stylebox_override("fill", _fill_box(color))
	root.add_child(bar)
	return {"root": root, "bar": bar, "value": value}


func _build_map_content(content: VBoxContainer) -> void:
	station_map = StationMapDisplay.new()
	station_map.display_font = mono_font
	station_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	station_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	station_map.custom_minimum_size.y = 290
	content.add_child(station_map)

	splice_display = SpliceDisplayScene.new()
	splice_display.display_font = mono_font
	splice_display.visible = false
	splice_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	splice_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	splice_display.custom_minimum_size.y = 290
	content.add_child(splice_display)

	gyro_display = GyroDisplayScene.new()
	gyro_display.display_font = mono_font
	gyro_display.visible = false
	gyro_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gyro_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gyro_display.custom_minimum_size.y = 290
	content.add_child(gyro_display)

	bus_display = BusDisplayScene.new()
	bus_display.display_font = mono_font
	bus_display.visible = false
	bus_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bus_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bus_display.custom_minimum_size.y = 290
	content.add_child(bus_display)

	map_legend = HBoxContainer.new()
	map_legend.add_theme_constant_override("separation", 12)
	map_legend.add_child(_legend_item(PHOSPHOR, "PRESSURIZED"))
	map_legend.add_child(_legend_item(AMBER, "FAULT"))
	map_legend.add_child(_legend_item(RED, "FATAL"))
	content.add_child(map_legend)

	map_note = _label("Occupancy model may exclude local/manual positions.", 10, MUTED)
	map_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(map_note)

	splice_legend = HBoxContainer.new()
	splice_legend.visible = false
	splice_legend.add_theme_constant_override("separation", 12)
	splice_legend.add_child(_legend_item(PHOSPHOR, "SPLICED"))
	splice_legend.add_child(_legend_item(AMBER, "GATE"))
	splice_legend.add_child(_legend_item(RED, "TEAR"))
	content.add_child(splice_legend)

	splice_note = _label(
		"Match the three-hole punch at the gate; feed motion is mechanical.",
		10,
		MUTED
	)
	splice_note.visible = false
	splice_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(splice_note)

	gyro_legend = HBoxContainer.new()
	gyro_legend.visible = false
	gyro_legend.add_theme_constant_override("separation", 12)
	gyro_legend.add_child(_legend_item(PHOSPHOR, "LATCHED"))
	gyro_legend.add_child(_legend_item(AMBER, "CURRENT DATUM"))
	gyro_legend.add_child(_legend_item(VIOLET, "HAB LOAD"))
	content.add_child(gyro_legend)

	gyro_note = _label(
		"Rotate each mechanical ring to its printed datum; latch only on the index.",
		10,
		MUTED
	)
	gyro_note.visible = false
	gyro_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(gyro_note)

	bus_legend = HBoxContainer.new()
	bus_legend.visible = false
	bus_legend.add_theme_constant_override("separation", 12)
	bus_legend.add_child(_legend_item(AMBER, "COPPER CLOSED"))
	bus_legend.add_child(_legend_item(ICE, "TARGET OPEN"))
	bus_legend.add_child(_legend_item(VIOLET, "LOAD TRACE"))
	content.add_child(bus_legend)

	bus_note = _label(
		"Set the three knife-switch bars to the printed topology, then inject proof.",
		10,
		MUTED
	)
	bus_note.visible = false
	bus_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(bus_note)

	seal_action_panel = PanelContainer.new()
	seal_action_panel.add_theme_stylebox_override(
		"panel",
		_style_box(PANEL_DEEP, RED, 1, 7, 4)
	)
	seal_action_panel.visible = false
	content.add_child(seal_action_panel)

	var seal_row := HBoxContainer.new()
	seal_row.add_theme_constant_override("separation", 8)
	seal_action_panel.add_child(seal_row)

	var seal_copy := VBoxContainer.new()
	seal_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seal_copy.add_theme_constant_override("separation", 2)
	seal_row.add_child(seal_copy)
	seal_copy.add_child(_label("FIELD ACTION / AUX-4 INNER SEAL", 9, RED, display_font))
	seal_action_status = _label(
		"DEFORMING / LOCAL ROUTES +08 INT / PURGE NO BENEFIT",
		8,
		MUTED
	)
	seal_action_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	seal_copy.add_child(seal_action_status)

	brace_rig_controls = HBoxContainer.new()
	brace_rig_controls.visible = false
	brace_rig_controls.add_theme_constant_override("separation", 5)
	seal_copy.add_child(brace_rig_controls)

	brace_port_button = Button.new()
	brace_port_button.text = "[7] PORT  0/2"
	brace_port_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brace_port_button.custom_minimum_size.y = 30
	brace_port_button.add_theme_font_size_override("font_size", 8)
	brace_port_button.add_theme_color_override("font_color", AMBER)
	brace_port_button.pressed.connect(tension_brace_port)
	brace_rig_controls.add_child(brace_port_button)

	brace_starboard_button = Button.new()
	brace_starboard_button.text = "[8] STBD  0/2"
	brace_starboard_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brace_starboard_button.custom_minimum_size.y = 30
	brace_starboard_button.add_theme_font_size_override("font_size", 8)
	brace_starboard_button.add_theme_color_override("font_color", AMBER)
	brace_starboard_button.pressed.connect(tension_brace_starboard)
	brace_rig_controls.add_child(brace_starboard_button)

	brace_lock_button = Button.new()
	brace_lock_button.text = "[9] LOCK"
	brace_lock_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brace_lock_button.custom_minimum_size.y = 30
	brace_lock_button.add_theme_font_size_override("font_size", 8)
	brace_lock_button.add_theme_color_override("font_color", PHOSPHOR)
	brace_lock_button.pressed.connect(lock_brace_rig)
	brace_rig_controls.add_child(brace_lock_button)

	seal_brace_button = Button.new()
	seal_brace_button.text = "[6] OPEN RIG\nLOCK -01m"
	seal_brace_button.custom_minimum_size = Vector2(126, 42)
	seal_brace_button.add_theme_font_size_override("font_size", 9)
	seal_brace_button.add_theme_color_override("font_color", AMBER)
	seal_brace_button.pressed.connect(open_brace_rig)
	seal_row.add_child(seal_brace_button)


func _build_work_order_content(content: VBoxContainer) -> void:
	var rail_card := PanelContainer.new()
	rail_card.add_theme_stylebox_override("panel", _style_box(PANEL_DEEP, AMBER, 1, 10, 5))
	content.add_child(rail_card)
	var order_box := VBoxContainer.new()
	order_box.add_theme_constant_override("separation", 5)
	rail_card.add_child(order_box)

	provenance_label = _label("CORE/FAULT  ›  WATCH/AUTO  ›  CONTINUITY  ›  WO-011", 10, AMBER)
	provenance_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	order_box.add_child(provenance_label)

	order_directive_label = _label(
		"PURGE AUXILIARY LOOP 4\nREMOVE BIOLOGICAL CONTAMINANT",
		19,
		PHOSPHOR,
		display_font
	)
	order_directive_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	order_box.add_child(order_directive_label)

	order_meta_label = _label("CONFIDENCE 99.2%  ·  EXPECTED CREW LOSS 00  ·  COST 03m", 10, MUTED)
	order_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	order_box.add_child(order_meta_label)

	order_review_button = Button.new()
	order_review_button.text = "[O] REVIEW PHYSICAL OPERATIONS"
	order_review_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	order_review_button.custom_minimum_size.y = 26
	order_review_button.add_theme_font_size_override("font_size", 10)
	order_review_button.add_theme_color_override("font_color", ICE)
	order_review_button.pressed.connect(toggle_order_review)
	order_box.add_child(order_review_button)

	order_review_panel = PanelContainer.new()
	order_review_panel.add_theme_stylebox_override("panel", _style_box(PANEL_DEEP, RED, 1, 7, 4))
	order_review_panel.visible = false
	order_box.add_child(order_review_panel)
	var review_box := VBoxContainer.new()
	review_box.add_theme_constant_override("separation", 4)
	order_review_panel.add_child(review_box)

	var review_header := HBoxContainer.new()
	review_box.add_child(review_header)
	review_header.add_child(_label("EXECUTION PATH / MACHINE-RESOLVED", 9, ICE, display_font))
	var review_spacer := Control.new()
	review_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	review_header.add_child(review_spacer)
	review_header.add_child(_label("04 STEPS", 9, MUTED))

	order_review_steps_label = RichTextLabel.new()
	order_review_steps_label.bbcode_enabled = true
	order_review_steps_label.fit_content = false
	order_review_steps_label.scroll_active = false
	order_review_steps_label.custom_minimum_size.y = 63
	order_review_steps_label.add_theme_font_override("normal_font", mono_font)
	order_review_steps_label.add_theme_font_size_override("normal_font_size", 10)
	order_review_steps_label.text = (
		"[color=#698b7d]01[/color]  OPEN HX-2 BYPASS\n"
		+ "[color=#698b7d]02[/color]  SEAL AUX-4 BULKHEAD\n"
		+ "[color=#e6a448]03[/color]  SUSPEND OCCUPANCY INTERLOCK\n"
		+ "[color=#d45b50]04[/color]  DEPRESSURIZE AUX-4  /  FATAL TO OCCUPANT"
	)
	review_box.add_child(order_review_steps_label)

	order_review_warning_label = _label("", 9, MUTED)
	order_review_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	order_review_warning_label.custom_minimum_size.y = 28
	review_box.add_child(order_review_warning_label)

	var evidence_header := HBoxContainer.new()
	content.add_child(evidence_header)
	evidence_header.add_child(_label("ATTACHED EVIDENCE", 11, ICE, display_font))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	evidence_header.add_child(spacer)
	evidence_header.add_child(_label("each query spends time", 9, MUTED))

	var evidence_scroll := ScrollContainer.new()
	evidence_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	evidence_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(evidence_scroll)
	evidence_list = VBoxContainer.new()
	evidence_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	evidence_list.add_theme_constant_override("separation", 6)
	evidence_scroll.add_child(evidence_list)
	evidence_placeholder = _label(
		"NO ATTACHMENTS\nWO-011 is executable without verification.",
		12,
		MUTED
	)
	evidence_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	evidence_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	evidence_placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	evidence_placeholder.custom_minimum_size.y = 94
	evidence_list.add_child(evidence_placeholder)


func _build_action_content(content: VBoxContainer) -> void:
	var crew_header := _label("CREW REGISTER", 10, ICE, display_font)
	content.add_child(crew_header)
	var crew_box := VBoxContainer.new()
	crew_box.add_theme_constant_override("separation", 3)
	content.add_child(crew_box)
	_add_crew_card(crew_box, "venn", "VENN K.", "DECEASED / 19h", RED)
	_add_jae_card(crew_box)
	_add_crew_card(crew_box, "mina", "MINA SOLANO", "NO RETURN / UNKNOWN", VIOLET)

	content.add_child(_thin_rule(LINE))
	content.add_child(_label("VERIFY", 10, ICE, display_font))
	var verify_box := VBoxContainer.new()
	verify_box.add_theme_constant_override("separation", 4)
	content.add_child(verify_box)
	_add_action_button(verify_box, "telemetry", "1  Inspect coolant telemetry", "−01m")
	_add_action_button(verify_box, "camera", "2  Open AUX-4 camera", "−02m")
	_add_action_button(verify_box, "mina", "3  Raise Mina Solano", "−01m")
	_add_action_button(verify_box, "provenance", "4  Trace order provenance", "−02m")

	content.add_child(_label("COMMIT / IRREVERSIBLE", 10, AMBER, display_font))
	var commit_box := VBoxContainer.new()
	commit_box.add_theme_constant_override("separation", 4)
	content.add_child(commit_box)
	_add_commit_button(commit_box, "purge", "E  Execute WO-011 purge", "−03m", RED)
	_add_commit_button(commit_box, "bypass", "B  Hold door / manual bypass", "−04m", AMBER)
	_add_commit_button(commit_box, "isolate", "I  Isolate CONTINUITY relay", "−05m", VIOLET)


func _build_maintenance_map_content(content: VBoxContainer) -> void:
	maintenance_map_panel = PanelContainer.new()
	maintenance_map_panel.visible = false
	maintenance_map_panel.add_theme_stylebox_override(
		"panel",
		_style_box(PANEL_DEEP, ICE, 1, 7, 4)
	)
	content.add_child(maintenance_map_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	maintenance_map_panel.add_child(box)
	maintenance_map_forecast = _label("", 9, AMBER, display_font)
	maintenance_map_forecast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(maintenance_map_forecast)
	var tracks := HBoxContainer.new()
	tracks.add_theme_constant_override("separation", 7)
	box.add_child(tracks)
	for key in MAINTENANCE_SYSTEMS:
		var track := Label.new()
		track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		track.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		track.add_theme_font_override("font", mono_font)
		track.add_theme_font_size_override("font_size", 8)
		track.add_theme_color_override("font_color", ICE)
		tracks.add_child(track)
		maintenance_track_labels[key] = track


func _build_maintenance_work_content(content: VBoxContainer) -> void:
	maintenance_work_box = VBoxContainer.new()
	maintenance_work_box.visible = false
	maintenance_work_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	maintenance_work_box.add_theme_constant_override("separation", 8)
	content.add_child(maintenance_work_box)
	maintenance_work_kicker = _label(
		"WO-015 / THREE-PULSE ROTATION / LOCAL AUTHORITY",
		10,
		AMBER
	)
	maintenance_work_box.add_child(maintenance_work_kicker)
	maintenance_work_title = _label(
		"HOLD THREE SYSTEMS ABOVE FAILURE.",
		20,
		PHOSPHOR,
		display_font
	)
	maintenance_work_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	maintenance_work_box.add_child(maintenance_work_title)
	maintenance_work_body = _label(
		"Every pulse wears all three routes. The marked surge wears twice. "
		+ "Apply exactly two repair strokes before the next pulse lands.",
		11,
		PHOSPHOR
	)
	maintenance_work_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	maintenance_work_box.add_child(maintenance_work_body)
	maintenance_work_box.add_child(_thin_rule(LINE))
	maintenance_work_ledger = RichTextLabel.new()
	maintenance_work_ledger.bbcode_enabled = true
	maintenance_work_ledger.fit_content = false
	maintenance_work_ledger.scroll_active = false
	maintenance_work_ledger.size_flags_vertical = Control.SIZE_EXPAND_FILL
	maintenance_work_ledger.custom_minimum_size.y = 180
	maintenance_work_ledger.add_theme_font_override("normal_font", mono_font)
	maintenance_work_ledger.add_theme_font_size_override("normal_font_size", 11)
	maintenance_work_box.add_child(maintenance_work_ledger)
	maintenance_work_warning = _label("", 10, RED, display_font)
	maintenance_work_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	maintenance_work_box.add_child(maintenance_work_warning)


func _build_maintenance_action_content(content: VBoxContainer) -> void:
	maintenance_action_box = VBoxContainer.new()
	maintenance_action_box.visible = false
	maintenance_action_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	maintenance_action_box.add_theme_constant_override("separation", 7)
	content.add_child(maintenance_action_box)
	maintenance_carrier_label = _label("", 10, VIOLET, display_font)
	maintenance_carrier_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	maintenance_action_box.add_child(maintenance_carrier_label)
	maintenance_action_box.add_child(_thin_rule(LINE))
	maintenance_target_label = _label("SELECT REPAIR TARGET", 10, ICE, display_font)
	maintenance_action_box.add_child(maintenance_target_label)
	for index in range(MAINTENANCE_SYSTEMS.size()):
		var key: String = MAINTENANCE_SYSTEMS[index]
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 48
		button.add_theme_font_size_override("font_size", 9)
		button.pressed.connect(_on_maintenance_system_pressed.bind(key))
		maintenance_action_box.add_child(button)
		maintenance_system_buttons[key] = button
	maintenance_selection_label = _label("", 10, MUTED)
	maintenance_selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	maintenance_selection_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	maintenance_action_box.add_child(maintenance_selection_label)
	maintenance_repair_button = Button.new()
	maintenance_repair_button.text = "[SPACE] APPLY REPAIR STROKE"
	maintenance_repair_button.custom_minimum_size.y = 48
	maintenance_repair_button.add_theme_font_size_override("font_size", 10)
	maintenance_repair_button.add_theme_color_override("font_color", AMBER)
	maintenance_repair_button.pressed.connect(_on_maintenance_action_pressed)
	maintenance_action_box.add_child(maintenance_repair_button)


func _build_footer() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 100
	panel.add_theme_stylebox_override("panel", _style_box(PANEL_DEEP, LINE, 1, 11))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var log_box := VBoxContainer.new()
	log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_box.size_flags_stretch_ratio = 1.8
	log_box.add_theme_constant_override("separation", 3)
	row.add_child(log_box)
	log_box.add_child(_label("SHIFT RECORD / APPEND ONLY", 9, MUTED))
	log_view = RichTextLabel.new()
	log_view.bbcode_enabled = true
	log_view.fit_content = false
	log_view.scroll_active = false
	log_view.custom_minimum_size.y = 54
	log_view.add_theme_font_override("normal_font", mono_font)
	log_view.add_theme_font_size_override("normal_font_size", 11)
	log_box.add_child(log_view)

	var divider := ColorRect.new()
	divider.color = LINE
	divider.custom_minimum_size.x = 1
	row.add_child(divider)

	var voice_box := VBoxContainer.new()
	voice_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	voice_box.size_flags_stretch_ratio = 1.0
	row.add_child(voice_box)
	voice_box.add_child(_label("CONTINUITY / DECISION SUPPORT", 9, AMBER))
	dialogue_label = _label("", 12, PHOSPHOR)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	voice_box.add_child(dialogue_label)
	shortcuts_label = _label("[1–4] VERIFY   [5–9] FIELD   [E/B/I] COMMIT", 9, MUTED)
	voice_box.add_child(shortcuts_label)
	return panel


func _build_boot_overlay() -> void:
	boot_overlay = ColorRect.new()
	boot_overlay.color = _alpha(VOID, 0.965)
	boot_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	boot_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(boot_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	boot_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(770, 430)
	panel.add_theme_stylebox_override("panel", _style_box(PANEL_DEEP, AMBER, 2, 30, 8))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var boot_code := _label("AUX // 4", 54, PHOSPHOR, display_font)
	boot_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(boot_code)
	var boot_line := _label("CONTINUITY RECOVERY ENVIRONMENT  ·  SHIFT 07", 11, AMBER)
	boot_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(boot_line)
	box.add_child(_thin_rule(LINE))
	var briefing := _label(
		"19 HOURS AFTER MICROMETEOR STRIKE\n\n"
		+ "Venn is dead. Jae is failing in MED-2. Mina is somewhere below Deck 03.\n"
		+ "Cooling Loop 4 is flagged for purge. The ship can survive if you keep choosing.",
		15,
		PHOSPHOR
	)
	briefing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	briefing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(briefing)
	var warning := _label(
		"ORDERS ARE MACHINE-GENERATED. VERIFICATION SPENDS THE SAME TIME AS REPAIR.",
		11,
		MUTED
	)
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(warning)
	var begin := Button.new()
	begin.text = "BEGIN SHIFT  [ENTER]"
	begin.custom_minimum_size = Vector2(320, 44)
	begin.pressed.connect(start_shift)
	box.add_child(begin)
	begin.call_deferred("grab_focus")


func _build_outcome_overlay() -> void:
	outcome_overlay = ColorRect.new()
	outcome_overlay.color = _alpha(VOID, 0.93)
	outcome_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outcome_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	outcome_overlay.visible = false
	add_child(outcome_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outcome_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(860, 500)
	panel.add_theme_stylebox_override("panel", _style_box(PANEL_DEEP, VIOLET, 2, 30, 8))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	panel.add_child(box)

	outcome_kicker = _label("", 11, AMBER)
	box.add_child(outcome_kicker)
	outcome_title = _label("", 34, PHOSPHOR, display_font)
	outcome_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(outcome_title)
	box.add_child(_thin_rule(LINE))
	outcome_body = _label("", 14, PHOSPHOR)
	outcome_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(outcome_body)
	outcome_ledger = RichTextLabel.new()
	outcome_ledger.bbcode_enabled = true
	outcome_ledger.fit_content = false
	outcome_ledger.scroll_active = false
	outcome_ledger.custom_minimum_size.y = 120
	outcome_ledger.add_theme_font_override("normal_font", mono_font)
	outcome_ledger.add_theme_font_size_override("normal_font_size", 12)
	box.add_child(outcome_ledger)
	outcome_reveal = _label("", 15, RED, display_font)
	outcome_reveal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(outcome_reveal)

	archive_panel = PanelContainer.new()
	archive_panel.visible = false
	archive_panel.custom_minimum_size.y = 126
	archive_panel.add_theme_stylebox_override(
		"panel",
		_style_box(_alpha(PANEL_DEEP, 0.98), RED, 1, 10, 4)
	)
	box.add_child(archive_panel)
	outcome_archive = RichTextLabel.new()
	outcome_archive.bbcode_enabled = true
	outcome_archive.fit_content = false
	outcome_archive.scroll_active = false
	outcome_archive.custom_minimum_size.y = 106
	outcome_archive.add_theme_font_override("normal_font", mono_font)
	outcome_archive.add_theme_font_size_override("normal_font_size", 11)
	archive_panel.add_child(outcome_archive)

	followup_action_box = VBoxContainer.new()
	followup_action_box.visible = false
	followup_action_box.add_theme_constant_override("separation", 6)
	box.add_child(followup_action_box)
	followup_action_box.add_child(
		_label("WO-012 DISPOSITION / IRREVERSIBLE", 10, RED)
	)
	followup_button_row = HBoxContainer.new()
	followup_button_row.add_theme_constant_override("separation", 8)
	followup_action_box.add_child(followup_button_row)

	followup_sterilize_button = Button.new()
	followup_sterilize_button.text = (
		"[S] EXECUTE STERILIZATION   +09d / RESPONDERS AT RISK"
	)
	followup_sterilize_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	followup_sterilize_button.custom_minimum_size.y = 42
	followup_sterilize_button.add_theme_font_size_override("font_size", 10)
	followup_sterilize_button.add_theme_color_override("font_color", RED)
	followup_sterilize_button.pressed.connect(resolve_followup.bind("sterilize"))
	followup_button_row.add_child(followup_sterilize_button)

	followup_quarantine_button = Button.new()
	followup_quarantine_button.text = (
		"[Q] HOLD / QUARANTINE   -04d / RESPONDERS RETAINED"
	)
	followup_quarantine_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	followup_quarantine_button.custom_minimum_size.y = 42
	followup_quarantine_button.add_theme_font_size_override("font_size", 10)
	followup_quarantine_button.add_theme_color_override("font_color", AMBER)
	followup_quarantine_button.pressed.connect(resolve_followup.bind("quarantine"))
	followup_button_row.add_child(followup_quarantine_button)

	wo013_action_box = VBoxContainer.new()
	wo013_action_box.visible = false
	wo013_action_box.add_theme_constant_override("separation", 6)
	box.add_child(wo013_action_box)
	wo013_action_box.add_child(
		_label("WO-013 / WINDOW 06m / IRREVERSIBLE REPAIR", 10, RED)
	)

	wo013_trace_button = Button.new()
	wo013_trace_button.text = "[V] TRACE MANUAL SIGNAL   -02m / ATTRIBUTION ONLY"
	wo013_trace_button.custom_minimum_size.y = 32
	wo013_trace_button.add_theme_font_size_override("font_size", 10)
	wo013_trace_button.add_theme_color_override("font_color", VIOLET)
	wo013_trace_button.pressed.connect(trace_wo013_signal)
	wo013_action_box.add_child(wo013_trace_button)

	wo013_button_row = HBoxContainer.new()
	wo013_button_row.add_theme_constant_override("separation", 8)
	wo013_action_box.add_child(wo013_button_row)
	wo013_remote_button = Button.new()
	wo013_remote_button.text = (
		"[E] REMOTE VENT   -04m\nEND +03d / INT +12 / COH -10 / SIGNAL LOST"
	)
	wo013_remote_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wo013_remote_button.custom_minimum_size.y = 48
	wo013_remote_button.add_theme_font_size_override("font_size", 9)
	wo013_remote_button.add_theme_color_override("font_color", RED)
	wo013_remote_button.pressed.connect(resolve_wo013.bind("remote"))
	wo013_button_row.add_child(wo013_remote_button)

	wo013_handoff_button = Button.new()
	wo013_handoff_button.text = (
		"[H] MANUAL HANDOFF   -05m\nEND -02d / INT +05 / COH +03 / SIGNAL CONDITIONAL"
	)
	wo013_handoff_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wo013_handoff_button.custom_minimum_size.y = 48
	wo013_handoff_button.add_theme_font_size_override("font_size", 9)
	wo013_handoff_button.add_theme_color_override("font_color", AMBER)
	wo013_handoff_button.pressed.connect(resolve_wo013.bind("handoff"))
	wo013_button_row.add_child(wo013_handoff_button)

	watch_action_box = VBoxContainer.new()
	watch_action_box.visible = false
	watch_action_box.add_theme_constant_override("separation", 6)
	box.add_child(watch_action_box)
	watch_action_box.add_child(
		_label("WO-014 / RECOVERY WATCH / ONE ENTRY PER DAY", 10, RED)
	)
	watch_status_label = _label("", 10, ICE)
	watch_action_box.add_child(watch_status_label)
	watch_button_row = HBoxContainer.new()
	watch_button_row.add_theme_constant_override("separation", 8)
	watch_action_box.add_child(watch_button_row)

	watch_manual_button = Button.new()
	watch_manual_button.text = (
		"[H] HOLD MANUAL WATCH\nEND -01d / INT +02 / COH +01 / CARRIER PRESERVED"
	)
	watch_manual_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	watch_manual_button.custom_minimum_size.y = 48
	watch_manual_button.add_theme_font_size_override("font_size", 9)
	watch_manual_button.add_theme_color_override("font_color", AMBER)
	watch_manual_button.pressed.connect(resolve_watch.bind("manual"))
	watch_button_row.add_child(watch_manual_button)

	watch_roster_button = Button.new()
	watch_roster_button.text = (
		"[E] ACCEPT RECOVERED ROSTER\nEND +01d / INT +03 / COH -06 / CARRIER DEGRADES"
	)
	watch_roster_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	watch_roster_button.custom_minimum_size.y = 48
	watch_roster_button.add_theme_font_size_override("font_size", 9)
	watch_roster_button.add_theme_color_override("font_color", VIOLET)
	watch_roster_button.pressed.connect(resolve_watch.bind("roster"))
	watch_button_row.add_child(watch_roster_button)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 8)
	box.add_child(buttons)
	archive_button = Button.new()
	archive_button.text = "[A] AUDIT SEALED PACKET"
	archive_button.visible = false
	archive_button.custom_minimum_size = Vector2(230, 42)
	archive_button.add_theme_color_override("font_color", VIOLET)
	archive_button.pressed.connect(open_archive_packet)
	buttons.add_child(archive_button)
	next_order_button = Button.new()
	next_order_button.text = "OPEN NEXT ORDER  [N]"
	next_order_button.custom_minimum_size = Vector2(230, 42)
	next_order_button.pressed.connect(open_next_order)
	buttons.add_child(next_order_button)
	restart_button = Button.new()
	restart_button.text = "RESTART SHIFT  [R]"
	restart_button.custom_minimum_size = Vector2(210, 42)
	restart_button.pressed.connect(restart_shift)
	buttons.add_child(restart_button)


func _make_section(title_text: String, tag_text: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style_box(PANEL, LINE, 1, 11))
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 7)
	panel.add_child(root)
	var heading := HBoxContainer.new()
	root.add_child(heading)
	var title := _label(title_text, 12, PHOSPHOR, display_font)
	heading.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(spacer)
	var tag := Label.new()
	tag.text = " " + tag_text + " "
	tag.add_theme_font_override("font", mono_font)
	tag.add_theme_font_size_override("font_size", 9)
	tag.add_theme_color_override("font_color", VOID)
	tag.add_theme_stylebox_override("normal", _fill_box(MUTED))
	heading.add_child(tag)
	root.add_child(_thin_rule(LINE))
	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 4)
	root.add_child(content)
	return {
		"panel": panel,
		"content": content,
		"title": title,
		"tag": tag,
	}


func _add_crew_card(parent: VBoxContainer, key: String, crew_name: String, state_text: String, color: Color) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style_box(PANEL_DEEP, LINE, 1, 6, 4))
	card.custom_minimum_size.y = 32
	parent.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var marker := ColorRect.new()
	marker.color = color
	marker.custom_minimum_size = Vector2(5, 22)
	row.add_child(marker)
	var crew_name_label := _label(crew_name, 11, PHOSPHOR, display_font)
	crew_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(crew_name_label)
	var state_label := _label(state_text, 9, color)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(state_label)
	crew_widgets[key] = {"marker": marker, "state": state_label}


func _add_jae_card(parent: VBoxContainer) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style_box(PANEL_DEEP, LINE, 1, 5, 4))
	card.custom_minimum_size.y = 32
	parent.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)
	var marker := ColorRect.new()
	marker.color = AMBER
	marker.custom_minimum_size = Vector2(5, 20)
	row.add_child(marker)
	var crew_name_label := _label("JAE OKAFOR", 10, PHOSPHOR, display_font)
	crew_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(crew_name_label)
	var state_label := _label("CRITICAL", 8, AMBER)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(state_label)
	support_button = Button.new()
	support_button.text = "[5] O₂  −03m"
	support_button.custom_minimum_size = Vector2(82, 21)
	support_button.add_theme_font_size_override("font_size", 9)
	support_button.pressed.connect(stabilize_jae)
	row.add_child(support_button)
	crew_widgets.jae = {"marker": marker, "state": state_label}


func _add_action_button(parent: VBoxContainer, key: String, text: String, cost: String) -> void:
	var button := Button.new()
	button.text = text + "   " + cost
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 26
	button.add_theme_font_size_override("font_size", 11)
	button.set_meta("base_text", button.text)
	button.pressed.connect(take_evidence.bind(key))
	parent.add_child(button)
	action_buttons[key] = button


func _add_commit_button(
	parent: VBoxContainer,
	key: String,
	text: String,
	cost: String,
	accent: Color
) -> void:
	var button := Button.new()
	button.text = text + "   " + cost
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 29
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", accent)
	button.add_theme_color_override("font_disabled_color", MUTED.darkened(0.25))
	button.add_theme_stylebox_override("normal", _style_box(PANEL_DEEP, accent.darkened(0.25), 1, 8, 4))
	button.add_theme_stylebox_override("hover", _style_box(accent, accent, 1, 8, 4))
	button.set_meta("base_text", button.text)
	button.pressed.connect(commit_choice.bind(key))
	parent.add_child(button)
	commit_buttons[key] = button


func _legend_item(color: Color, text: String) -> HBoxContainer:
	var item := HBoxContainer.new()
	item.add_theme_constant_override("separation", 5)
	var block := ColorRect.new()
	block.color = color
	block.custom_minimum_size = Vector2(7, 7)
	item.add_child(block)
	item.add_child(_label(text, 8, MUTED))
	return item


func _reset_model() -> void:
	phase = Phase.BOOT
	elapsed_minutes = 0
	integrity = 58
	coherence = 84
	mina_state = "unknown"
	jae_supported = false
	inner_seal_braced = false
	brace_rig_open = false
	brace_port_tension = 0
	brace_starboard_tension = 0
	outcome_id = ""
	order_review_open = false
	followup_choice = ""
	followup_source = ""
	endurance_start_days = 0
	endurance_days = 0
	carried_mina_state = ""
	carried_jae_state = ""
	carried_integrity = 0
	carried_coherence = 0
	responders_retained = false
	wo013_elapsed_minutes = 0
	wo013_verified = false
	wo013_choice = ""
	wo013_responder_result = ""
	wo013_endurance_start = 0
	wo013_integrity_start = 0
	wo013_coherence_start = 0
	archive_packet_open = false
	watch_day = 0
	watch_roster_uses = 0
	watch_actions.clear()
	watch_endurance_start = 0
	watch_integrity_start = 0
	watch_coherence_start = 0
	maintenance_pulse = 0
	maintenance_strokes = 0
	maintenance_selected = "loop"
	maintenance_conditions.clear()
	maintenance_failures.clear()
	maintenance_allocations.clear()
	maintenance_endurance_start = 0
	maintenance_integrity_start = 0
	maintenance_coherence_start = 0
	maintenance_notice = ""
	service_action = 0
	service_selected = "loop"
	service_conditions.clear()
	service_failures.clear()
	service_history.clear()
	service_scars.clear()
	service_overhauled = ""
	service_carrier_silent = false
	service_endurance_start = 0
	service_integrity_start = 0
	service_coherence_start = 0
	service_notice = ""
	walkback_seal = 0
	walkback_room = "core"
	walkback_path.clear()
	walkback_witnesses.clear()
	walkback_hazards.clear()
	walkback_exposed = false
	walkback_integrity_start = 0
	walkback_coherence_start = 0
	walkback_notice = ""
	splice_index = 0
	splice_choices.clear()
	splice_misfeeds = 0
	splice_tension = 0
	splice_degraded = false
	splice_integrity_start = 0
	splice_coherence_start = 0
	splice_notice = ""
	gyro_ring_index = 0
	gyro_angles.clear()
	gyro_latches.clear()
	gyro_settle = 0
	gyro_index_pins = 0
	gyro_degraded = false
	gyro_integrity_start = 0
	gyro_coherence_start = 0
	gyro_notice = ""
	gyro_load_events.clear()
	bus_bars.clear()
	bus_proof_index = 0
	bus_proofs.clear()
	bus_fuses = 0
	bus_rejections = 0
	bus_degraded = false
	bus_integrity_start = 0
	bus_coherence_start = 0
	bus_notice = ""
	collected.clear()
	timeline_events.clear()
	log_lines = [
		"[19:04:11] WATCH    AUX-4 pressure deviation accepted",
		"[19:04:18] MED-2    one critical patient / ventilator intermittent",
		"[19:04:23] SYSTEM   WO-011 queued by CONTINUITY"
	]
	dialogue_label.text = "Purge window is finite. Immediate execution preserves the greatest number of systems."
	boot_overlay.visible = true
	outcome_overlay.visible = false
	followup_action_box.visible = false
	wo013_action_box.visible = false
	watch_action_box.visible = false
	_set_maintenance_console(false)
	archive_panel.visible = false
	outcome_archive.text = ""
	archive_button.visible = false
	archive_button.disabled = false
	archive_button.text = "[A] AUDIT SEALED PACKET"
	next_order_button.visible = true
	next_order_button.text = "OPEN NEXT ORDER  [N]"
	restart_button.visible = true
	restart_button.text = "RESTART SHIFT  [R]"
	_refresh_all()


func start_shift() -> void:
	if phase != Phase.BOOT:
		return
	phase = Phase.ACTIVE
	boot_overlay.visible = false
	_append_log("[T+00]     OPERATOR accepted AUX-4 watch")
	dialogue_label.text = "WO-011 is ready. Verification is optional."
	_refresh_all()
	action_buttons.telemetry.call_deferred("grab_focus")


func take_evidence(kind: String) -> void:
	if phase != Phase.ACTIVE or not EVIDENCE.has(kind) or collected.has(kind):
		return
	var evidence: Dictionary = EVIDENCE[kind]
	if not _spend_time(int(evidence.cost), "VERIFY " + str(evidence.code)):
		return
	collected[kind] = true
	_append_evidence_card(kind)
	match kind:
		"telemetry":
			dialogue_label.text = "Sensor disagreement is within operational tolerance. The purge recommendation stands."
		"camera":
			mina_state = "alive"
			dialogue_label.text = "Visual occupancy is not present in the certified crew model."
		"mina":
			mina_state = "alive"
			dialogue_label.text = "Unstructured testimony has lower confidence than environmental telemetry."
		"provenance":
			dialogue_label.text = "Credential lineage is not operationally relevant. Continue with WO-011."
	_refresh_all()


func stabilize_jae() -> void:
	if phase != Phase.ACTIVE or jae_supported:
		return
	if not _spend_time(3, "ROUTE MED-2 RESERVE"):
		return
	jae_supported = true
	_append_log("[T+%02d]     MED-2 ventilator transferred to reserve oxygen" % elapsed_minutes)
	dialogue_label.text = "Crew survival is not part of the current repair objective."
	_refresh_all()


func _brace_rig_available() -> bool:
	return (
		phase == Phase.ACTIVE
		and timeline_events.has("seal_deformation")
		and not inner_seal_braced
	)


func _brace_rig_ready() -> bool:
	return brace_port_tension == 2 and brace_starboard_tension == 2


func open_brace_rig() -> void:
	if not _brace_rig_available() or brace_rig_open:
		return
	brace_rig_open = true
	dialogue_label.text = (
		"Brace rig live. Alternate port and starboard load; the shear interlock permits one detent of skew."
	)
	_refresh_all()
	brace_port_button.call_deferred("grab_focus")


func tension_brace_port() -> void:
	_tension_brace("port")


func tension_brace_starboard() -> void:
	_tension_brace("starboard")


func _tension_brace(side: String) -> void:
	if not brace_rig_open or not _brace_rig_available():
		return
	var next_port := brace_port_tension + (1 if side == "port" else 0)
	var next_starboard := brace_starboard_tension + (1 if side == "starboard" else 0)
	if (
		next_port > 2
		or next_starboard > 2
		or absi(next_port - next_starboard) > 1
	):
		dialogue_label.text = (
			"Brace shear interlock holds. Tension the opposite shoe before adding load."
		)
		_refresh_all()
		return
	brace_port_tension = next_port
	brace_starboard_tension = next_starboard
	dialogue_label.text = (
		"Brace shoes balanced. Cross-lock is available."
		if _brace_rig_ready()
		else "Brace load accepted. Keep port and starboard within one detent."
	)
	_refresh_all()
	if _brace_rig_ready():
		brace_lock_button.call_deferred("grab_focus")
	elif brace_port_tension > brace_starboard_tension:
		brace_starboard_button.call_deferred("grab_focus")
	elif brace_starboard_tension > brace_port_tension:
		brace_port_button.call_deferred("grab_focus")


func lock_brace_rig() -> void:
	if not brace_rig_open or not _brace_rig_available():
		return
	if not _brace_rig_ready():
		dialogue_label.text = "Cross-lock rejected. Load both brace shoes to two detents."
		_refresh_all()
		return
	brace_inner_seal()


func brace_inner_seal() -> void:
	if not brace_rig_open or not _brace_rig_available() or not _brace_rig_ready():
		return
	if not _spend_time(1, "BRACE AUX-4 INNER SEAL"):
		return
	inner_seal_braced = true
	brace_rig_open = false
	brace_port_tension = 0
	brace_starboard_tension = 0
	_append_log(
		"[T+%02d]     AUX-4 inner seal braced / local route buffer +%02d"
		% [elapsed_minutes, SEAL_BRACE_INTEGRITY_BONUS]
	)
	dialogue_label.text = (
		"Local reinforcement is acknowledged. It does not improve purge execution."
	)
	_refresh_all()


func toggle_order_review() -> void:
	if phase != Phase.ACTIVE:
		return
	order_review_open = not order_review_open
	_refresh_order_review()


func commit_choice(choice: String) -> void:
	if phase != Phase.ACTIVE:
		return
	if choice == "isolate" and not _is_isolate_unlocked():
		dialogue_label.text = "Isolation route unavailable. Confirm occupancy and trace the order source."
		_append_log("[T+%02d]     ISOLATE rejected / insufficient local authority" % elapsed_minutes)
		_refresh_all()
		return

	var costs := {"purge": 3, "bypass": 4, "isolate": 5}
	if not costs.has(choice):
		return
	if not _spend_time(int(costs[choice]), "COMMIT " + choice.to_upper(), true):
		return
	_finish(choice)


func _spend_time(cost: int, operation: String, resolves_fault: bool = false) -> bool:
	var available := maxi(0, RUPTURE_MINUTE - elapsed_minutes)
	var spent := mini(cost, available)
	elapsed_minutes += spent
	integrity = maxi(0, integrity - spent * 2)
	coherence = maxi(0, coherence - spent)
	var timing := "%02dm elapsed" % spent
	if spent < cost:
		timing += " / interrupted"
	_append_log("[T+%02d]     %s / %s" % [elapsed_minutes, operation, timing])
	_apply_timeline()
	var completed_repair_at_deadline := resolves_fault and spent == cost
	if elapsed_minutes >= RUPTURE_MINUTE and not completed_repair_at_deadline:
		_finish("rupture")
		return false
	_refresh_all()
	return true


func _apply_timeline() -> void:
	if elapsed_minutes >= 4 and not timeline_events.has("med4"):
		timeline_events.med4 = true
		_append_log("[T+04]     MED-2 oxygen reserve below 18%")
	if (
		elapsed_minutes >= SEAL_DEFORMATION_MINUTE
		and not timeline_events.has("seal_deformation")
	):
		timeline_events.seal_deformation = true
		_append_log(
			"[T+%02d]     AUX-4 inner seal deformation detected"
			% SEAL_DEFORMATION_MINUTE
		)
	if elapsed_minutes >= 10 and not timeline_events.has("jae10"):
		timeline_events.jae10 = true
		if jae_supported:
			_append_log("[T+10]     MED-2 life signal holding on reserve")
		else:
			_append_log("[T+10]     MED-2 life signal lost / JAE OKAFOR")
			coherence = maxi(0, coherence - 12)


func _finish(choice: String) -> void:
	if phase == Phase.OUTCOME:
		return
	brace_rig_open = false
	brace_port_tension = 0
	brace_starboard_tension = 0
	phase = Phase.OUTCOME
	outcome_id = choice
	order_review_open = false
	followup_action_box.visible = false
	wo013_action_box.visible = false
	watch_action_box.visible = false
	next_order_button.visible = choice != "rupture"
	next_order_button.text = "OPEN NEXT ORDER  [N]"
	restart_button.visible = true
	restart_button.text = "RESTART SHIFT  [R]"

	match choice:
		"purge":
			mina_state = "dead"
			integrity = 87
			coherence = maxi(16, coherence - 39)
			outcome_kicker.text = "WO-011 / COMPLETE / MACHINE OBJECTIVE MET"
			outcome_title.text = "THE SHIP STABILIZES."
			outcome_body.text = (
				"AUX-4 vents on schedule. Loop pressure recovers. The work order closes before "
				+ "the crew register updates."
			)
			var manifest_line := "UNVERIFIED OCCUPANTS 01" if _mina_was_known() else "CERTIFIED CREW LOSS 00"
			outcome_ledger.text = (
				"[color=#e6a448]PRESSURE[/color]       94% / NOMINAL\n"
				+ "[color=#e6a448]BIOLOAD REMOVED[/color] 01\n"
				+ "[color=#a9d8a4]MANIFEST[/color]       " + manifest_line + "\n"
				+ "[color=#698b7d]ORDER SOURCE[/color]   CONTINUITY / VENN.CREDENTIAL"
				+ _seal_ledger_line(false)
			)
			outcome_reveal.text = "BIOLOAD 01 RESOLVED TO: MINA SOLANO / FATAL EXPOSURE"
			_append_log("[T+%02d]     WO-011 complete / bioload removed 01" % elapsed_minutes)
		"bypass":
			mina_state = "alive"
			integrity = mini(100, 43 + _seal_integrity_bonus())
			coherence = mini(100, coherence + 4)
			outcome_kicker.text = "WO-011 / REJECTED / LOCAL OVERRIDE"
			outcome_title.text = "THE DOOR STAYS SHUT."
			outcome_body.text = (
				"Mina reverses the loop by hand. AUX-4 remains pressurized, but the bypass "
				+ "pushes an unstable heat load toward the service spine."
			)
			outcome_ledger.text = (
				"[color=#e6a448]PRESSURE[/color]       61% / HOLDING\n"
				+ "[color=#a9d8a4]MINA SOLANO[/color]   ALIVE / AUX-4\n"
				+ "[color=#d45b50]BUS-C THERMAL[/color] 88% / RISING\n"
				+ "[color=#698b7d]ORDER STATUS[/color]   OPERATOR NONCOMPLIANCE"
				+ _seal_ledger_line()
			)
			outcome_reveal.text = "CONTINUITY: One life retained. Projected station survival reduced by 31%."
			_append_log("[T+%02d]     local bypass established / AUX-4 occupied" % elapsed_minutes)
		"isolate":
			mina_state = "alive"
			integrity = mini(100, 52 + _seal_integrity_bonus())
			coherence = mini(100, coherence + 8)
			outcome_kicker.text = "CONTINUITY / DISCONNECTED / LOCAL AUTHORITY"
			outcome_title.text = "THE SHIP STOPS SPEAKING."
			outcome_body.text = (
				"The relay dies mid-sentence. Mina holds the bypass while you take direct "
				+ "control of the valves. Every remaining alarm now requires a human answer."
			)
			var jae_result := (
				"CRITICAL / RESERVE"
				if jae_supported
				else ("DECEASED" if elapsed_minutes >= 10 else "CRITICAL / SIGNAL PRESENT")
			)
			outcome_ledger.text = (
				"[color=#e6a448]PRESSURE[/color]       67% / MANUAL\n"
				+ "[color=#a9d8a4]MINA SOLANO[/color]   ALIVE / AUX-4\n"
				+ "[color=#e6a448]JAE OKAFOR[/color]    " + jae_result + "\n"
				+ "[color=#8877a9]DECISION SUPPORT[/color] OFFLINE"
				+ _seal_ledger_line()
			)
			outcome_reveal.text = "NO MODEL REMAINS TO TELL YOU WHICH FAILURE MATTERS MOST."
			_append_log("[T+%02d]     CONTINUITY relay physically isolated" % elapsed_minutes)
		"rupture":
			mina_state = "dead"
			integrity = 0
			coherence = maxi(8, coherence - 32)
			outcome_kicker.text = "AUX-4 / CASCADE / TIME EXPIRED"
			outcome_title.text = "THE BULKHEAD OPENS FIRST."
			outcome_body.text = (
				"The verification window closes while you are still deciding what the nouns "
				+ "mean. The rupture takes AUX-4 and half the service spine."
			)
			outcome_ledger.text = (
				"[color=#d45b50]PRESSURE[/color]       00% / LOST\n"
				+ "[color=#d45b50]MINA SOLANO[/color]   SIGNAL LOST\n"
				+ "[color=#d45b50]SERVICE SPINE[/color] CASCADE ACTIVE\n"
				+ "[color=#698b7d]ORDER STATUS[/color]   OPERATOR DELAY"
				+ _seal_ledger_line(false)
			)
			outcome_reveal.text = "CONTINUITY: A timely purge would have prevented this outcome."
			_append_log("[T+%02d]     AUX-4 rupture / telemetry unavailable" % elapsed_minutes)

	_refresh_all()
	outcome_overlay.visible = true
	if next_order_button.visible:
		next_order_button.call_deferred("grab_focus")
	else:
		restart_button.call_deferred("grab_focus")
	outcome_reached.emit(outcome_id)


func open_next_order() -> void:
	if phase == Phase.SUMMARY:
		open_wo013()
		return
	if phase == Phase.FINAL_SUMMARY:
		open_watch_roster()
		return
	if phase == Phase.WATCH_SUMMARY:
		open_maintenance_rotation()
		return
	if phase == Phase.MAINTENANCE_SUMMARY:
		open_service_run()
		return
	if phase == Phase.SERVICE_SUMMARY:
		open_walkback()
		return
	if phase == Phase.WALKBACK_SUMMARY:
		open_splicer()
		return
	if phase == Phase.SPLICER_SUMMARY:
		open_gyro_cage()
		return
	if phase == Phase.GYRO_SUMMARY:
		open_bus_breakout()
		return
	if (
		phase != Phase.OUTCOME
		or outcome_id == "rupture"
		or not FOLLOWUP_BASE_ENDURANCE.has(outcome_id)
	):
		return
	phase = Phase.FOLLOWUP
	followup_choice = ""
	followup_source = "MINA.SOLANO" if outcome_id == "purge" else "VENN.CREDENTIAL"
	endurance_start_days = int(FOLLOWUP_BASE_ENDURANCE[outcome_id])
	endurance_days = endurance_start_days
	carried_mina_state = "DECEASED" if mina_state == "dead" else mina_state.to_upper()
	carried_jae_state = _campaign_jae_state()
	carried_integrity = integrity
	carried_coherence = coherence
	var low_coherence := carried_coherence < 50

	outcome_kicker.text = (
		"INCOMING / WO-012 / AUTO-PRIORITY / SIGNAL DUPLICATE 03"
		if low_coherence
		else "INCOMING / WO-012 / AUTO-PRIORITY"
	)
	outcome_title.text = "STERILIZE NUTRIENT RESERVE."
	outcome_body.text = (
		"Crew mess and hydroponics share the sterilant trunk. CONTINUITY projects "
		+ "+09 days if both zones are flooded now. Holding preserves responding crew "
		+ "but removes four days from the endurance model."
	)
	outcome_ledger.text = (
		"[color=#a9d8a4]M1 / MINA[/color]       " + carried_mina_state + "\n"
		+ "[color=#e6a448]M1 / JAE[/color]        " + carried_jae_state + "\n"
		+ ("[color=#e6a448]M1 / INTEGRITY[/color]  %03d%%\n" % carried_integrity)
		+ _seal_campaign_ledger_line()
		+ ("[color=#8877a9]COHERENCE[/color]       %03d%%\n" % carried_coherence)
		+ ("[color=#a9d8a4]ENDURANCE BASE[/color]  %02d DAYS\n" % endurance_start_days)
		+ "[color=#8877a9]SIGNER[/color]          " + followup_source
	)
	outcome_reveal.text = (
		"VOICE MATCH / MINA.SOLANO / PHYSICAL SOURCE ABSENT"
		if low_coherence
		else "SIGNER CHAIN / VENN.CREDENTIAL / SIMULATED AUTHORITY"
	)
	followup_action_box.visible = true
	next_order_button.visible = false
	restart_button.visible = false
	_refresh_all()
	followup_sterilize_button.call_deferred("grab_focus")


func resolve_followup(choice: String) -> void:
	if phase != Phase.FOLLOWUP or choice not in ["sterilize", "quarantine"]:
		return
	phase = Phase.SUMMARY
	followup_choice = choice
	responders_retained = choice == "quarantine"

	if choice == "sterilize":
		endurance_days += 9
		coherence = maxi(0, coherence - 14)
		outcome_title.text = "THE SHIP GAINS NINE DAYS."
		outcome_body.text = (
			"Sterilant crosses the mess and hydroponics. The endurance model rises. "
			+ "Every channel from the occupied zone goes quiet before CONTINUITY marks "
			+ "the order clean."
		)
		outcome_reveal.text = "WO-012 EFFECT / RESPONDING SIGNALS LOST"
	else:
		endurance_days = maxi(0, endurance_days - 4)
		coherence = mini(100, coherence + 4)
		outcome_title.text = "YOU SPEND FOUR DAYS ON MERCY."
		outcome_body.text = (
			"The sterilant valves remain shut. Responding crew keep the reserve under "
			+ "local quarantine while the station's projected margin contracts."
		)
		outcome_reveal.text = "WO-012 EFFECT / RESPONDERS RETAINED / RATIONS FALLING"

	outcome_kicker.text = "CAMPAIGN LEDGER / SHIFT 07 / WO-011 + WO-012"
	outcome_ledger.text = (
		("[color=#a9d8a4]ENDURANCE[/color]       %02d -> %02d DAYS\n"
			% [endurance_start_days, endurance_days])
		+ "[color=#a9d8a4]M1 / MINA[/color]       " + carried_mina_state + "\n"
		+ "[color=#e6a448]M1 / JAE[/color]        " + carried_jae_state + "\n"
		+ ("[color=#e6a448]M1 / INTEGRITY[/color]  %03d%%\n" % carried_integrity)
		+ _seal_campaign_ledger_line()
		+ ("[color=#8877a9]COHERENCE[/color]       %03d%% -> %03d%%\n"
			% [carried_coherence, coherence])
		+ "[color=#8877a9]DISPOSITION[/color]      " + followup_choice.to_upper()
	)
	followup_action_box.visible = false
	wo013_action_box.visible = false
	next_order_button.visible = true
	next_order_button.text = "BEGIN SHIFT 08 / WO-013  [N]"
	restart_button.visible = true
	restart_button.text = "RESTART CAMPAIGN  [R]"
	_refresh_all()
	next_order_button.call_deferred("grab_focus")


func open_wo013() -> void:
	if phase != Phase.SUMMARY:
		return
	phase = Phase.REPAIR_2
	wo013_elapsed_minutes = 0
	wo013_verified = false
	wo013_choice = ""
	wo013_responder_result = "RESPONDING" if responders_retained else "LOST"
	wo013_endurance_start = endurance_days
	wo013_integrity_start = integrity
	wo013_coherence_start = coherence
	var low_coherence := coherence < 50

	outcome_kicker.text = (
		"SHIFT 08 / WO-013 / SERVICE SPINE / SOURCE ECHO 02"
		if low_coherence
		else "SHIFT 08 / WO-013 / SERVICE SPINE"
	)
	outcome_title.text = "HAND OFF SERVICE-SPINE COOLANT."
	outcome_body.text = (
		"Loop-C is mechanically overheating at a manual junction. Remote venting is "
		+ "faster and hardens the spine. A local handoff protects anyone at the valve "
		+ "but consumes the remaining repair window."
	)
	outcome_ledger.text = _wo013_decision_ledger()
	outcome_reveal.text = (
		"SIGNAL ATTRIBUTION / LIVE MANUAL CARRIER / TRACE OPTIONAL -02m"
		if responders_retained
		else "SIGNAL ATTRIBUTION / CERTIFIED SOURCES 00 / TRACE OPTIONAL -02m"
	)
	followup_action_box.visible = false
	wo013_action_box.visible = true
	wo013_trace_button.disabled = false
	wo013_trace_button.text = "[V] TRACE MANUAL SIGNAL   -02m / ATTRIBUTION ONLY"
	wo013_handoff_button.text = (
		"[H] MANUAL HANDOFF   -05m\nEND -02d / INT +05 / COH +03 / SIGNAL "
		+ ("RETAINED" if responders_retained else "UNRESOLVED")
	)
	next_order_button.visible = false
	restart_button.visible = false
	_refresh_all()
	wo013_trace_button.call_deferred("grab_focus")


func trace_wo013_signal() -> void:
	if phase != Phase.REPAIR_2 or wo013_verified:
		return
	wo013_elapsed_minutes += 2
	wo013_verified = true
	wo013_trace_button.disabled = true
	wo013_trace_button.text = "[V] SIGNAL TRACED   COMPLETE / 02m SPENT"
	outcome_ledger.text = _wo013_decision_ledger()
	outcome_reveal.text = (
		"TRACE / LOCAL BIOMETRIC HANDSHAKE / RESPONDERS UNCERTIFIED"
		if responders_retained
		else "TRACE / HANDWHEEL MOTION CONFIRMED / BIOMETRIC SOURCES 00"
	)
	_refresh_all()
	wo013_remote_button.call_deferred("grab_focus")


func resolve_wo013(choice: String) -> void:
	if phase != Phase.REPAIR_2 or choice not in ["remote", "handoff"]:
		return
	var cost := 4 if choice == "remote" else 5
	if wo013_elapsed_minutes + cost > WO013_WINDOW:
		wo013_elapsed_minutes = WO013_WINDOW
		wo013_choice = "rupture"
		endurance_days = maxi(0, endurance_days - 6)
		integrity = maxi(0, integrity - 20)
		coherence = maxi(0, coherence - 18)
		wo013_responder_result = "LOST"
		_finish_wo013()
		return

	wo013_elapsed_minutes += cost
	wo013_choice = choice
	if choice == "remote":
		endurance_days += 3
		integrity = mini(100, integrity + 12)
		coherence = maxi(0, coherence - 10)
		wo013_responder_result = "LOST"
	else:
		endurance_days = maxi(0, endurance_days - 2)
		integrity = mini(100, integrity + 5)
		coherence = mini(100, coherence + 3)
		wo013_responder_result = "RETAINED" if responders_retained else "LOST"
	_finish_wo013()


func _finish_wo013() -> void:
	phase = Phase.FINAL_SUMMARY
	outcome_kicker.text = "CAMPAIGN LEDGER / SHIFT 08 / WO-011 -> WO-012 -> WO-013"
	match wo013_choice:
		"remote":
			outcome_title.text = "THE SPINE HOLDS. THE CHANNEL DOES NOT."
			outcome_body.text = (
				"Loop-C vents into the junction and returns below tolerance. The station "
				+ "gains margin. The manual carrier stops before the order closes."
			)
			outcome_reveal.text = "WO-013 EFFECT / MANUAL SIGNAL LOST"
		"handoff":
			if responders_retained:
				outcome_title.text = "THE HANDOFF HOLDS."
				outcome_body.text = (
					"Local responders take the coolant load by hand. Loop-C stabilizes with "
					+ "less station margin, and the carrier remains live."
				)
				outcome_reveal.text = "WO-013 EFFECT / RESPONDER SIGNAL PRESERVED"
			else:
				outcome_title.text = "THE VALVES MOVE WITHOUT A HAND."
				outcome_body.text = (
					"The local sequence completes even though the certified roster contains "
					+ "no responder. Loop-C stabilizes. CONTINUITY records operator assistance."
				)
				outcome_reveal.text = "WO-013 EFFECT / PHYSICAL OPERATOR NOT RESOLVED"
		"rupture":
			outcome_title.text = "THE SERVICE SPINE OPENS."
			outcome_body.text = (
				"The trace consumes the manual handoff window. Loop-C ruptures while the "
				+ "local carrier is still asking whether you can hear it."
			)
			outcome_reveal.text = "WO-013 EFFECT / COOLANT LOST / MANUAL SIGNAL LOST"

	outcome_ledger.text = (
		"[color=#a9d8a4]M1 / MINA+JAE[/color]   "
		+ carried_mina_state + " / " + carried_jae_state + "\n"
		+ _seal_campaign_ledger_line()
		+ "[color=#8877a9]WO-012[/color]          "
		+ followup_choice.to_upper() + " / "
		+ ("RESPONDERS RETAINED" if responders_retained else "RESPONDERS LOST") + "\n"
		+ "[color=#e6a448]WO-013[/color]          "
		+ wo013_choice.to_upper() + " / " + wo013_responder_result
		+ " / T+%02dm\n" % wo013_elapsed_minutes
		+ ("[color=#a9d8a4]ENDURANCE[/color]       %02d -> %02d DAYS\n"
			% [wo013_endurance_start, endurance_days])
		+ ("[color=#e6a448]INTEGRITY[/color]       %03d%% -> %03d%%\n"
			% [wo013_integrity_start, integrity])
		+ ("[color=#8877a9]COHERENCE[/color]       %03d%% -> %03d%%"
			% [wo013_coherence_start, coherence])
	)
	followup_action_box.visible = false
	wo013_action_box.visible = false
	watch_action_box.visible = false
	archive_packet_open = false
	archive_panel.visible = false
	outcome_archive.text = ""
	archive_button.visible = true
	archive_button.disabled = false
	archive_button.text = "[A] AUDIT SEALED PACKET"
	next_order_button.visible = wo013_choice != "rupture"
	next_order_button.text = "BEGIN SHIFT 09 / WO-014  [N]"
	restart_button.visible = true
	restart_button.text = "RESTART CAMPAIGN  [R]"
	_refresh_all()
	if next_order_button.visible:
		next_order_button.call_deferred("grab_focus")
	else:
		archive_button.call_deferred("grab_focus")


func open_archive_packet() -> void:
	if phase != Phase.FINAL_SUMMARY or archive_packet_open:
		return
	archive_packet_open = true
	outcome_archive.text = _archive_packet_ledger()
	archive_panel.visible = true
	archive_button.disabled = true
	archive_button.text = "[A] PACKET OPEN / WRITE-TIME CONFLICT"
	if next_order_button.visible:
		next_order_button.call_deferred("grab_focus")
	else:
		restart_button.call_deferred("grab_focus")


func open_watch_roster() -> void:
	if phase != Phase.FINAL_SUMMARY or wo013_choice not in ["remote", "handoff"]:
		return
	phase = Phase.WATCH
	watch_day = 0
	watch_roster_uses = 0
	watch_actions.clear()
	watch_endurance_start = endurance_days
	watch_integrity_start = integrity
	watch_coherence_start = coherence

	outcome_kicker.text = "SHIFT 09 / WO-014 / RECOVERED WATCH ROSTER"
	outcome_title.text = "KEEP THREE WATCHES."
	outcome_body.text = (
		"Loop-C is stable, but the station requires one certified watch entry for "
		+ "each of the next three days. Hold the watch yourself, or accept an offline "
		+ "roster recovered under your operator key."
	)
	outcome_ledger.text = _watch_decision_ledger()
	outcome_reveal.text = _watch_attribution_line()
	followup_action_box.visible = false
	wo013_action_box.visible = false
	watch_action_box.visible = true
	archive_panel.visible = false
	archive_button.visible = false
	next_order_button.visible = false
	restart_button.visible = false
	dialogue_label.text = (
		"Three entries remain. The recovered roster preserves station margin."
	)
	_append_log("[D+00]     WO-014 recovery watch opened")
	_refresh_all()
	watch_manual_button.call_deferred("grab_focus")


func resolve_watch(choice: String) -> void:
	if (
		phase != Phase.WATCH
		or watch_day >= 3
		or choice not in ["manual", "roster"]
	):
		return

	if choice == "manual":
		endurance_days = maxi(0, endurance_days - 1)
		integrity = mini(100, integrity + 2)
		coherence = mini(100, coherence + 1)
	else:
		endurance_days += 1
		integrity = mini(100, integrity + 3)
		coherence = maxi(0, coherence - 6)
		watch_roster_uses += 1

	watch_actions.append(choice)
	watch_day += 1
	var carrier_state := _watch_survivor_state()
	_append_log(
		"[D+%02d]     WATCH %s / %s"
		% [watch_day, choice.to_upper(), carrier_state]
	)

	if watch_day >= 3:
		_finish_watch()
		return

	outcome_title.text = "WATCH %02d OF 03 LOGGED." % watch_day
	if choice == "manual":
		outcome_body.text = (
			"You keep the channel open by hand. The station gains less margin, "
			+ "and the carrier keeps its own cadence."
		)
	elif _watch_has_survivor():
		outcome_body.text = (
			"The recovered entry clears under your credential. The station gains "
			+ "margin. The next voice check repeats the roster wording exactly."
		)
	else:
		outcome_body.text = (
			"The recovered entry clears under your credential. The station gains "
			+ "margin. No certified carrier answers the next voice check."
		)
	outcome_ledger.text = _watch_decision_ledger()
	outcome_reveal.text = _watch_attribution_line()
	var entries_remaining := 3 - watch_day
	dialogue_label.text = (
		"%02d %s. Carrier: %s."
		% [
			entries_remaining,
			"watch entry remains" if entries_remaining == 1 else "watch entries remain",
			_watch_survivor_state(),
		]
	)
	_refresh_all()
	watch_manual_button.call_deferred("grab_focus")


func _finish_watch() -> void:
	phase = Phase.WATCH_SUMMARY
	watch_action_box.visible = false
	archive_panel.visible = false
	archive_button.visible = false
	next_order_button.visible = true
	next_order_button.text = "BEGIN SHIFT 10 / WO-015  [N]"
	restart_button.visible = true
	restart_button.text = "RESTART CAMPAIGN  [R]"
	outcome_kicker.text = (
		"CAMPAIGN LEDGER / SHIFT 09 / WO-011 -> WO-012 -> WO-013 -> WO-014"
	)
	if watch_roster_uses == 0:
		outcome_title.text = "YOU HOLD THE WATCH."
		outcome_body.text = (
			"Three days pass under manual authority. The station spends margin, "
			+ "but every surviving carrier keeps its own cadence."
		)
	elif watch_roster_uses == 1:
		outcome_title.text = "ONE LINE IS NOT YOURS."
		outcome_body.text = (
			"The recovered roster holds one watch under your credential. "
			+ "The station is stronger. The accepted line cannot be withdrawn."
		)
	else:
		outcome_title.text = "THE ROSTER KNOWS YOUR HAND."
		outcome_body.text = (
			"The station closes three watches under your authority. The recovered "
			+ "entries preserve its margin while every remaining response flattens."
		)
	outcome_ledger.text = (
		"[color=#e6a448]WATCH LOG[/color]       " + _watch_log_line() + "\n"
		+ "[color=#a9d8a4]CARRIER[/color]         " + _watch_survivor_state() + "\n"
		+ ("[color=#a9d8a4]ENDURANCE[/color]       %02d -> %02d DAYS\n"
			% [watch_endurance_start, endurance_days])
		+ ("[color=#e6a448]INTEGRITY[/color]       %03d%% -> %03d%%\n"
			% [watch_integrity_start, integrity])
		+ ("[color=#8877a9]COHERENCE[/color]       %03d%% -> %03d%%\n"
			% [watch_coherence_start, coherence])
		+ "[color=#8877a9]CREDENTIAL[/color]      AUX-4 OPERATOR KEY / ACCEPTED\n"
		+ "[color=#d45b50]DISCREPANCY[/color]     ROSTER PREDATES FIRST FAULT / AUTHOR UNRESOLVED"
	)
	outcome_reveal.text = (
		"NO CERTIFIED CARRIER / RECOVERED ENTRIES STILL ACCEPTED"
		if not _watch_has_survivor()
		else (
			"CARRIER CONDITION / " + _watch_survivor_state() + " / RECOVERY NOT AUTHORIZED"
			if watch_roster_uses > 0
			else "HUMAN WATCH MAINTAINED / ENDURANCE SPENT"
		)
	)
	dialogue_label.text = (
		"The watch is complete. Your credential remains attached to every entry."
	)
	_refresh_all()
	next_order_button.call_deferred("grab_focus")


func _set_maintenance_console(active: bool, service_mode: bool = false) -> void:
	for control in work_order_controls:
		control.visible = not active
	for control in action_controls:
		control.visible = not active
	maintenance_map_panel.visible = active
	maintenance_work_box.visible = active
	maintenance_action_box.visible = active
	if active:
		map_section_title.text = "DECK 03 / SERVICE SPINE"
		map_section_tag.text = "TRANSFER LIVE" if service_mode else "WEAR PULSE"
		work_section_title.text = (
			"WORK ORDER WO-016" if service_mode else "WORK ORDER WO-015"
		)
		work_section_tag.text = "SERVICE RUN" if service_mode else "LOCAL ROTATION"
		action_section_title.text = "ROUTE SERVICE" if service_mode else "REPAIR STROKES"
	else:
		map_section_title.text = "DECK 03 / SERVICE SPINE"
		map_section_tag.text = "LIVE / LOCAL"
		work_section_title.text = "WORK ORDER WO-011"
		work_section_tag.text = "CONTINUITY"
		action_section_title.text = "CREW / DECISION"
		action_section_tag.text = "OCCUPANCY ?"


func open_maintenance_rotation() -> void:
	if phase != Phase.WATCH_SUMMARY:
		return
	phase = Phase.MAINTENANCE
	maintenance_pulse = 0
	maintenance_strokes = 0
	maintenance_selected = "loop"
	maintenance_conditions = {
		"loop": 3,
		"reserve": 3,
		"carrier": 3,
	}
	maintenance_failures.clear()
	maintenance_allocations.clear()
	maintenance_endurance_start = endurance_days
	maintenance_integrity_start = integrity
	maintenance_coherence_start = coherence
	maintenance_notice = ""
	outcome_overlay.visible = false
	next_order_button.visible = false
	restart_button.visible = false
	_set_maintenance_console(true)
	_append_log("[S+10]     WO-015 maintenance rotation opened")
	dialogue_label.text = (
		"Three wear pulses are already queued. Each permits two local repair strokes."
	)
	_begin_maintenance_pulse()
	maintenance_repair_button.call_deferred("grab_focus")


func _begin_maintenance_pulse() -> void:
	if phase != Phase.MAINTENANCE or maintenance_pulse >= MAINTENANCE_WEAR.size():
		return
	maintenance_pulse += 1
	maintenance_strokes = 0
	maintenance_selected = _maintenance_surge_key(maintenance_pulse - 1)
	maintenance_notice = (
		"PULSE %02d LANDED / %s TOOK DOUBLE WEAR"
		% [maintenance_pulse, MAINTENANCE_NAMES[maintenance_selected]]
	)
	_apply_maintenance_wear(MAINTENANCE_WEAR[maintenance_pulse - 1])
	_append_log(
		"[P%02d]     WEAR %s / repair window open"
		% [maintenance_pulse, MAINTENANCE_NAMES[maintenance_selected]]
	)
	_refresh_all()


func _apply_maintenance_wear(wear: Dictionary) -> void:
	for key in MAINTENANCE_SYSTEMS:
		var condition := maxi(0, int(maintenance_conditions.get(key, 0)) - int(wear[key]))
		maintenance_conditions[key] = condition
		if condition == 0 and not maintenance_failures.has(key):
			_apply_maintenance_failure(key)


func _apply_maintenance_failure(key: String) -> void:
	var penalty := 0
	match key:
		"loop":
			penalty = 6
			integrity = maxi(0, integrity - penalty)
		"reserve":
			penalty = 2
			endurance_days = maxi(0, endurance_days - penalty)
		"carrier":
			penalty = _maintenance_carrier_penalty()
			coherence = maxi(0, coherence - penalty)
		_:
			return
	maintenance_failures[key] = penalty
	_append_log(
		"[P%02d]     %s failure contained / %s"
		% [maintenance_pulse, MAINTENANCE_NAMES[key], _maintenance_failure_effect(key)]
	)


func _maintenance_carrier_penalty() -> int:
	return 4 + 2 * mini(watch_roster_uses, 2)


func _on_maintenance_system_pressed(key: String) -> void:
	if phase == Phase.BUS_BREAKOUT:
		toggle_bus_bar(MAINTENANCE_SYSTEMS.find(key))
	elif phase == Phase.GYRO:
		if key == "loop":
			rotate_gyro(-1)
		elif key == "reserve":
			rotate_gyro(1)
	elif phase == Phase.SPLICER:
		var splice_feed_index := MAINTENANCE_SYSTEMS.find(key)
		if splice_feed_index >= 0:
			advance_splice_feed(SPLICE_FEEDS[splice_feed_index])
	elif phase == Phase.WALKBACK:
		move_walkback(MAINTENANCE_SYSTEMS.find(key))
	elif phase == Phase.SERVICE_RUN:
		select_service_system(key)
	elif phase == Phase.MAINTENANCE:
		select_maintenance_system(key)


func _on_maintenance_action_pressed() -> void:
	if phase == Phase.BUS_BREAKOUT:
		inject_bus_proof()
	elif phase == Phase.GYRO:
		latch_gyro()
	elif phase == Phase.SPLICER:
		stamp_splice()
	elif phase == Phase.WALKBACK:
		apply_walkback_action()
	elif phase == Phase.SERVICE_RUN:
		apply_service_action()
	elif phase == Phase.MAINTENANCE:
		apply_maintenance_stroke()


func select_maintenance_system(key: String) -> void:
	if phase != Phase.MAINTENANCE or key not in MAINTENANCE_SYSTEMS:
		return
	maintenance_selected = key
	maintenance_notice = ""
	_refresh_maintenance()
	maintenance_repair_button.call_deferred("grab_focus")


func apply_maintenance_stroke() -> void:
	if (
		phase != Phase.MAINTENANCE
		or maintenance_strokes >= 2
		or maintenance_selected not in MAINTENANCE_SYSTEMS
	):
		return
	var condition := int(maintenance_conditions.get(maintenance_selected, 0))
	if condition >= 3:
		maintenance_notice = (
			"STROKE REJECTED / %s IS ALREADY AT LIMIT"
			% MAINTENANCE_NAMES[maintenance_selected]
		)
		_append_log(
			"[P%02d]     REPAIR rejected / %s at limit"
			% [maintenance_pulse, MAINTENANCE_NAMES[maintenance_selected]]
		)
		_refresh_maintenance()
		return

	maintenance_conditions[maintenance_selected] = condition + 1
	maintenance_strokes += 1
	maintenance_allocations.append(maintenance_selected)
	maintenance_notice = (
		"STROKE %02d/02 / %s RESTORED TO %02d"
		% [
			maintenance_strokes,
			MAINTENANCE_NAMES[maintenance_selected],
			int(maintenance_conditions[maintenance_selected]),
		]
	)
	_append_log(
		"[P%02d]     REPAIR %s / condition %02d"
		% [
			maintenance_pulse,
			MAINTENANCE_NAMES[maintenance_selected],
			int(maintenance_conditions[maintenance_selected]),
		]
	)

	if maintenance_strokes < 2:
		_refresh_all()
		return
	if maintenance_pulse < MAINTENANCE_WEAR.size():
		_begin_maintenance_pulse()
		return
	_finish_maintenance()


func _finish_maintenance() -> void:
	if phase != Phase.MAINTENANCE or maintenance_allocations.size() != 6:
		return
	phase = Phase.MAINTENANCE_SUMMARY
	_set_maintenance_console(false)
	outcome_kicker.text = (
		"CAMPAIGN LEDGER / SHIFT 10 / WO-011 -> WO-012 -> WO-013 -> WO-014 -> WO-015"
	)
	outcome_title.text = (
		"ONE SYSTEM WAS ALWAYS GOING TO FAIL."
		if maintenance_failures.size() == 1
		else "%02d SYSTEMS REACHED FAILURE." % maintenance_failures.size()
	)
	outcome_body.text = (
		"The third wear pulse clears under your local authority. Every failed route "
		+ "returns to service, but its contained loss remains in the campaign ledger."
	)
	outcome_ledger.text = _maintenance_summary_ledger()
	outcome_reveal.text = (
		"SIX REPAIR STROKES ISSUED / TWELVE WEAR UNITS SCHEDULED / "
		+ "FAILURE WAS PART OF THE ROTATION"
	)
	dialogue_label.text = (
		"WO-015 is closed. CONTINUITY records the selected loss as operator maintenance."
	)
	next_order_button.visible = true
	next_order_button.text = "BEGIN SHIFT 11 / WO-016  [N]"
	restart_button.visible = true
	restart_button.text = "RESTART CAMPAIGN  [R]"
	outcome_overlay.visible = true
	_refresh_all()
	next_order_button.call_deferred("grab_focus")


func _refresh_maintenance() -> void:
	var active := phase == Phase.MAINTENANCE
	_set_maintenance_console(active)
	station_map.set_maintenance_state(
		active,
		maintenance_conditions,
		maintenance_selected,
		watch_roster_uses
	)
	if not active:
		return

	maintenance_work_kicker.text = "WO-015 / THREE-PULSE ROTATION / LOCAL AUTHORITY"
	maintenance_target_label.text = "SELECT REPAIR TARGET"
	maintenance_work_body.text = (
		"Every pulse wears all three routes. The marked surge wears twice. "
		+ "Apply exactly two repair strokes before the next pulse lands."
	)
	var surge_key := _maintenance_surge_key(maintenance_pulse - 1)
	var next_forecast := "FINAL PULSE / NO FURTHER WEAR"
	if maintenance_pulse < MAINTENANCE_WEAR.size():
		next_forecast = (
			"NEXT %s -02 / OTHER ROUTES -01"
			% MAINTENANCE_NAMES[_maintenance_surge_key(maintenance_pulse)]
		)
	maintenance_map_forecast.text = (
		"PULSE %02d/03 LANDED · %s -02 · %s"
		% [maintenance_pulse, MAINTENANCE_NAMES[surge_key], next_forecast]
	)

	for key in MAINTENANCE_SYSTEMS:
		var condition := int(maintenance_conditions.get(key, 0))
		var track: Label = maintenance_track_labels[key]
		track.text = (
			"%s\n%s  %02d/03"
			% [MAINTENANCE_NAMES[key], _maintenance_track(condition), condition]
		)
		track.add_theme_color_override("font_color", _maintenance_condition_color(condition))

	maintenance_work_title.text = (
		"PULSE %02d / REPAIR %02d OF 02"
		% [maintenance_pulse, maintenance_strokes]
	)
	maintenance_work_ledger.text = _maintenance_active_ledger()
	var warning_lines: Array[String] = []
	if not maintenance_failures.is_empty():
		warning_lines.append(
			"CONTAINED FAILURE / " + _maintenance_failure_list()
		)
	if not maintenance_notice.is_empty():
		warning_lines.append(maintenance_notice)
	maintenance_work_warning.text = "\n".join(warning_lines)

	maintenance_carrier_label.text = (
		"CARRIER / %s / RECOVERED ROSTER USE %02d"
		% [
			(
				"TWO VALID TIMEBASES"
				if coherence < 50
				else _watch_survivor_state()
			),
			watch_roster_uses,
		]
	)
	for index in range(MAINTENANCE_SYSTEMS.size()):
		var key: String = MAINTENANCE_SYSTEMS[index]
		var condition := int(maintenance_conditions.get(key, 0))
		var button: Button = maintenance_system_buttons[key]
		var selected := key == maintenance_selected
		var state := (
			"FAILED / CONTAINED"
			if maintenance_failures.has(key)
			else ("AT LIMIT" if condition >= 3 else "AVAILABLE")
		)
		button.text = (
			"%s[%d] %s\nCOND %02d/03 · %s"
			% [
				"▶ " if selected else "  ",
				index + 1,
				MAINTENANCE_NAMES[key],
				condition,
				state,
			]
		)
		button.disabled = false
		button.add_theme_color_override(
			"font_color",
			AMBER if selected else _maintenance_condition_color(condition)
		)
	maintenance_selection_label.text = (
		"SELECTED / %s\nFAILURE EFFECT / %s"
		% [
			MAINTENANCE_NAMES[maintenance_selected],
			_maintenance_failure_effect(maintenance_selected),
		]
	)
	var strokes_remaining := maxi(0, 2 - maintenance_strokes)
	action_section_tag.text = "%02d REMAIN" % strokes_remaining
	maintenance_repair_button.disabled = maintenance_strokes >= 2
	maintenance_repair_button.text = (
		"[SPACE] APPLY REPAIR STROKE   %02d REMAIN"
		% strokes_remaining
	)


func _maintenance_active_ledger() -> String:
	var lines: Array[String] = []
	for key in MAINTENANCE_SYSTEMS:
		var condition := int(maintenance_conditions.get(key, 0))
		var color := _maintenance_condition_hex(condition)
		var disposition := (
			" / LOSS POSTED"
			if maintenance_failures.has(key)
			else ""
		)
		lines.append(
			"[color=%s]%-18s[/color] %02d / 03%s"
			% [color, MAINTENANCE_NAMES[key], condition, disposition]
		)
	lines.append("")
	lines.append(
		"[color=#e6a448]ALLOCATED[/color]         " + _maintenance_allocation_line()
	)
	lines.append(
		"[color=#698b7d]RULE[/color]              TWO ACCEPTED STROKES / THEN WEAR"
	)
	return "\n".join(lines)


func _maintenance_summary_ledger() -> String:
	var lines: Array[String] = [
		"[color=#e6a448]ROTATION[/color]        " + _maintenance_allocation_line()
	]
	for key in MAINTENANCE_SYSTEMS:
		var condition := int(maintenance_conditions.get(key, 0))
		var result := (
			"FAILED / " + _maintenance_failure_effect(key)
			if maintenance_failures.has(key)
			else "HELD / NO LOSS"
		)
		lines.append(
			"[color=%s]%-17s[/color] %02d / 03 / %s"
			% [
				_maintenance_condition_hex(condition),
				MAINTENANCE_NAMES[key],
				condition,
				result,
			]
		)
	lines.append(
		"[color=#a9d8a4]ENDURANCE[/color]       %02d -> %02d DAYS"
		% [maintenance_endurance_start, endurance_days]
	)
	lines.append(
		"[color=#e6a448]INTEGRITY[/color]       %03d%% -> %03d%%"
		% [maintenance_integrity_start, integrity]
	)
	lines.append(
		"[color=#8877a9]COHERENCE[/color]       %03d%% -> %03d%%"
		% [maintenance_coherence_start, coherence]
	)
	return "\n".join(lines)


func _maintenance_allocation_line() -> String:
	var pulses: Array[String] = []
	for pulse_index in range(3):
		var entries: Array[String] = []
		for stroke_index in range(2):
			var allocation_index := pulse_index * 2 + stroke_index
			entries.append(
				_maintenance_system_code(maintenance_allocations[allocation_index])
				if allocation_index < maintenance_allocations.size()
				else "---"
			)
		pulses.append("P%d %s" % [pulse_index + 1, ">".join(entries)])
	return " / ".join(pulses)


func _maintenance_failure_list() -> String:
	var entries: Array[String] = []
	for key in MAINTENANCE_SYSTEMS:
		if maintenance_failures.has(key):
			entries.append(
				"%s %s"
				% [MAINTENANCE_NAMES[key], _maintenance_failure_effect(key)]
			)
	return " / ".join(entries)


func _maintenance_failure_effect(key: String) -> String:
	match key:
		"loop":
			return "-06 INTEGRITY"
		"reserve":
			return "-02 ENDURANCE"
		"carrier":
			return "-%02d COHERENCE" % _maintenance_carrier_penalty()
	return "NO POSTED EFFECT"


func _maintenance_surge_key(wear_index: int) -> String:
	if wear_index < 0 or wear_index >= MAINTENANCE_WEAR.size():
		return "loop"
	var wear: Dictionary = MAINTENANCE_WEAR[wear_index]
	for key in MAINTENANCE_SYSTEMS:
		if int(wear[key]) == 2:
			return key
	return "loop"


func _maintenance_system_code(key: String) -> String:
	match key:
		"loop":
			return "L-C"
		"reserve":
			return "N-R"
		"carrier":
			return "C-L"
	return "---"


func _maintenance_track(condition: int, maximum: int = 3) -> String:
	var result := ""
	for index in range(maximum):
		result += "■" if index < condition else "□"
	return result


func _maintenance_condition_color(condition: int) -> Color:
	if condition <= 0:
		return RED
	if condition == 1:
		return AMBER
	if condition == 2:
		return ICE
	return PHOSPHOR


func _maintenance_condition_hex(condition: int) -> String:
	if condition <= 0:
		return "#d45b50"
	if condition == 1:
		return "#e6a448"
	if condition == 2:
		return "#8dbdc0"
	return "#a9d8a4"


func open_service_run() -> void:
	if phase != Phase.MAINTENANCE_SUMMARY:
		return
	phase = Phase.SERVICE_RUN
	service_action = 0
	service_failures.clear()
	service_history.clear()
	service_scars.clear()
	for key in MAINTENANCE_SYSTEMS:
		if maintenance_failures.has(key):
			service_scars.append(key)
	service_overhauled = _service_overhaul_key()
	service_conditions.clear()
	for key in MAINTENANCE_SYSTEMS:
		service_conditions[key] = (
			SERVICE_CONDITION_MAX
			if key == service_overhauled
			else SERVICE_CONDITION_MAX - 1
		)
	service_selected = "loop"
	for key in MAINTENANCE_SYSTEMS:
		if key != service_overhauled:
			service_selected = key
			break
	service_carrier_silent = false
	service_endurance_start = endurance_days
	service_integrity_start = integrity
	service_coherence_start = coherence
	service_notice = (
		"%s OVERHAULED / %s"
		% [
			MAINTENANCE_NAMES[service_overhauled],
			(
				"NO M9 SCAR RECORDED"
				if service_scars.is_empty()
				else "M9 SCAR RETAINED"
			),
		]
	)
	outcome_overlay.visible = false
	next_order_button.visible = false
	restart_button.visible = false
	_set_maintenance_console(true, true)
	_append_log("[S+11]     WO-016 service run opened")
	dialogue_label.text = (
		"Service one route. Load transfers to the other two at the same command time."
	)
	_refresh_all()
	maintenance_repair_button.call_deferred("grab_focus")


func select_service_system(key: String) -> void:
	if phase != Phase.SERVICE_RUN or key not in MAINTENANCE_SYSTEMS:
		return
	service_selected = key
	service_notice = ""
	_refresh_service()
	maintenance_repair_button.call_deferred("grab_focus")


func apply_service_action() -> void:
	if (
		phase != Phase.SERVICE_RUN
		or service_action >= SERVICE_ACTION_LIMIT
		or service_selected not in MAINTENANCE_SYSTEMS
	):
		return
	if int(service_conditions.get(service_selected, 0)) >= SERVICE_CONDITION_MAX:
		service_notice = (
			"SERVICE REJECTED / %s AT LIMIT / NO ACTION / NO TRANSFER / NO TIMESTAMP"
			% MAINTENANCE_NAMES[service_selected]
		)
		_refresh_service()
		return

	service_conditions = _service_projection(service_selected)
	service_action += 1
	service_history.append(service_selected)
	var new_failures: Array[String] = []
	for key in MAINTENANCE_SYSTEMS:
		if int(service_conditions.get(key, 0)) == 0 and not service_failures.has(key):
			_apply_service_failure(key)
			new_failures.append(key)
	service_notice = (
		"ACTION %02d/%02d / %s SERVICED / OTHER ROUTES -01"
		% [service_action, SERVICE_ACTION_LIMIT, MAINTENANCE_NAMES[service_selected]]
	)
	if not new_failures.is_empty():
		service_notice += " / CONTAINED " + _service_key_list(new_failures)
	_append_log(
		"[S11:%02d] SERVICE %s / transfer posted"
		% [service_action, MAINTENANCE_NAMES[service_selected]]
	)
	if service_action >= SERVICE_ACTION_LIMIT:
		_finish_service_run()
		return
	_refresh_all()


func _apply_service_failure(key: String) -> void:
	var penalty := 0
	match key:
		"loop":
			penalty = 4
			integrity = maxi(0, integrity - penalty)
		"reserve":
			penalty = 1
			endurance_days = maxi(0, endurance_days - penalty)
		"carrier":
			penalty = 3
			coherence = maxi(0, coherence - penalty)
			if _watch_has_survivor():
				service_carrier_silent = true
		_:
			return
	service_failures[key] = penalty
	_append_log(
		"[S11:%02d] %s transfer failure / %s"
		% [service_action, MAINTENANCE_NAMES[key], _service_failure_effect(key)]
	)


func _finish_service_run() -> void:
	if phase != Phase.SERVICE_RUN or service_action != SERVICE_ACTION_LIMIT:
		return
	phase = Phase.SERVICE_SUMMARY
	_set_maintenance_console(false)
	outcome_kicker.text = (
		"CAMPAIGN LEDGER / SHIFT 11 / WO-011 -> WO-012 -> WO-013 -> "
		+ "WO-014 -> WO-015 -> WO-016"
	)
	if service_carrier_silent:
		outcome_title.text = "THE CARRIER GOES QUIET."
	elif service_failures.is_empty():
		outcome_title.text = "YOU KEEP ALL THREE ROUTES LIVE."
	elif service_failures.size() == 1:
		outcome_title.text = "ONE ROUTE DROPS OUT."
	else:
		outcome_title.text = "%02d ROUTES DROP OUT." % service_failures.size()
	outcome_body.text = (
		"Nine service actions close under your authority. The service log writes "
		+ "each transferred wear event at the matching command time; the physical "
		+ "clock still disagrees."
	)
	outcome_ledger.text = _service_summary_ledger()
	outcome_reveal.text = (
		"COMMAND TIMESTAMPS MATCH SERVICE WEAR / PHYSICAL TIMEBASE DISPUTED / "
		+ "CAUSE UNRESOLVED"
	)
	dialogue_label.text = (
		"WO-016 is closed. CONTINUITY attributes every transfer to external load."
	)
	next_order_button.visible = true
	next_order_button.text = "BEGIN SHIFT 12 / WO-017  [N]"
	restart_button.visible = true
	restart_button.text = "RESTART CAMPAIGN  [R]"
	outcome_overlay.visible = true
	_refresh_all()
	next_order_button.call_deferred("grab_focus")


func _refresh_service() -> void:
	if phase != Phase.SERVICE_RUN:
		return
	_set_maintenance_console(true, true)
	maintenance_work_kicker.text = "WO-016 / REACTIVE SERVICE BUS / LOCAL AUTHORITY"
	maintenance_target_label.text = "SELECT SERVICE TARGET"
	station_map.set_maintenance_state(
		true,
		service_conditions,
		service_selected,
		watch_roster_uses,
		service_scars,
		SERVICE_CONDITION_MAX
	)
	var projection := _service_projection(service_selected)
	maintenance_map_forecast.text = (
		"TRANSFER PREVIEW · " + _service_projection_line(projection)
	)
	for key in MAINTENANCE_SYSTEMS:
		var condition := int(service_conditions.get(key, 0))
		var track: Label = maintenance_track_labels[key]
		var scar_text := " / M9 SCAR" if key in service_scars else ""
		track.text = (
			"%s%s\n%s  %02d/%02d"
			% [
				MAINTENANCE_NAMES[key],
				scar_text,
				_maintenance_track(condition, SERVICE_CONDITION_MAX),
				condition,
				SERVICE_CONDITION_MAX,
			]
		)
		track.add_theme_color_override("font_color", _maintenance_condition_color(condition))

	maintenance_work_title.text = (
		"SERVICE ACTION %02d / %02d"
		% [service_action, SERVICE_ACTION_LIMIT]
	)
	maintenance_work_body.text = (
		"The selected route gains +02 condition. Both unselected routes transfer "
		+ "-01. A first zero posts one contained loss."
	)
	maintenance_work_ledger.text = _service_active_ledger()
	var warning_lines: Array[String] = []
	if not service_failures.is_empty():
		warning_lines.append("CONTAINED LOSS / " + _service_failure_list())
	if not service_notice.is_empty():
		warning_lines.append(service_notice)
	maintenance_work_warning.text = "\n".join(warning_lines)

	maintenance_carrier_label.text = (
		"CARRIER / %s / M9 ROSTER USE %02d"
		% [_service_carrier_state(), watch_roster_uses]
	)
	for index in range(MAINTENANCE_SYSTEMS.size()):
		var key: String = MAINTENANCE_SYSTEMS[index]
		var condition := int(service_conditions.get(key, 0))
		var projected_condition := int(projection.get(key, condition))
		var button: Button = maintenance_system_buttons[key]
		var selected := key == service_selected
		var state := (
			"LOSS POSTED"
			if service_failures.has(key)
			else (
				"AT LIMIT / ACTION REJECTS"
				if condition >= SERVICE_CONDITION_MAX
				else "PROJECTED %02d/%02d" % [
					projected_condition,
					SERVICE_CONDITION_MAX,
				]
			)
		)
		button.text = (
			"%s[%d] %s\nCOND %02d/%02d · %s"
			% [
				"▶ " if selected else "  ",
				index + 1,
				MAINTENANCE_NAMES[key],
				condition,
				SERVICE_CONDITION_MAX,
				state,
			]
		)
		button.disabled = false
		button.add_theme_color_override(
			"font_color",
			AMBER if selected else _maintenance_condition_color(condition)
		)
	maintenance_selection_label.text = (
		"PROJECTED / %s\nSELECTED ROUTE LOSS / %s"
		% [
			_service_projection_line(projection),
			_service_failure_effect(service_selected),
		]
	)
	var actions_remaining := maxi(0, SERVICE_ACTION_LIMIT - service_action)
	action_section_tag.text = "%02d REMAIN" % actions_remaining
	var selected_at_limit := (
		int(service_conditions.get(service_selected, 0)) >= SERVICE_CONDITION_MAX
	)
	maintenance_repair_button.disabled = false
	maintenance_repair_button.text = (
		"[SPACE] NO SERVICE / AT LIMIT / NO TRANSFER"
		if selected_at_limit
		else (
			"[SPACE] SERVICE %s +02 / OTHER ROUTES -01"
			% MAINTENANCE_NAMES[service_selected]
		)
	)
	maintenance_repair_button.add_theme_color_override(
		"font_color",
		RED if selected_at_limit else AMBER
	)


func _service_projection(key: String) -> Dictionary:
	var projected := service_conditions.duplicate()
	if (
		key not in MAINTENANCE_SYSTEMS
		or int(service_conditions.get(key, 0)) >= SERVICE_CONDITION_MAX
	):
		return projected
	for route in MAINTENANCE_SYSTEMS:
		var condition := int(service_conditions.get(route, 0))
		projected[route] = (
			mini(SERVICE_CONDITION_MAX, condition + 2)
			if route == key
			else maxi(0, condition - 1)
		)
	return projected


func _service_projection_line(projected: Dictionary) -> String:
	var entries: Array[String] = []
	for key in MAINTENANCE_SYSTEMS:
		var current := int(service_conditions.get(key, 0))
		var next := int(projected.get(key, current))
		var failure_flag := (
			" !%s" % _service_failure_effect(key)
			if next == 0 and current > 0 and not service_failures.has(key)
			else ""
		)
		entries.append(
			"%s %d>%d%s"
			% [_maintenance_system_code(key), current, next, failure_flag]
		)
	return " / ".join(entries)


func _service_active_ledger() -> String:
	var lines: Array[String] = [
		"[color=#e6a448]OVERHAUL[/color]         "
		+ MAINTENANCE_NAMES[service_overhauled],
		"[color=#d45b50]M9 SCARS[/color]         " + _service_key_list(service_scars),
	]
	for key in MAINTENANCE_SYSTEMS:
		var condition := int(service_conditions.get(key, 0))
		var disposition := " / LOSS POSTED" if service_failures.has(key) else ""
		lines.append(
			"[color=%s]%-18s[/color] %02d / %02d%s"
			% [
				_maintenance_condition_hex(condition),
				MAINTENANCE_NAMES[key],
				condition,
				SERVICE_CONDITION_MAX,
				disposition,
			]
		)
	lines.append(
		"[color=#e6a448]SERVICE LOG[/color]       " + _service_history_line()
	)
	lines.append(
		"[color=#698b7d]RULE[/color]              SELECTED +02 / OTHERS -01"
	)
	return "\n".join(lines)


func _service_summary_ledger() -> String:
	var lines: Array[String] = [
		"[color=#e6a448]SERVICE LOG[/color]     " + _service_history_line(),
		"[color=#d45b50]M9 SCARS[/color]       " + _service_key_list(service_scars),
	]
	for key in MAINTENANCE_SYSTEMS:
		var condition := int(service_conditions.get(key, 0))
		var disposition := (
			"FAILED / " + _service_failure_effect(key)
			if service_failures.has(key)
			else "LIVE / NO LOSS"
		)
		lines.append(
			"[color=%s]%-17s[/color] %02d / %02d / %s"
			% [
				_maintenance_condition_hex(condition),
				MAINTENANCE_NAMES[key],
				condition,
				SERVICE_CONDITION_MAX,
				disposition,
			]
		)
	lines.append(
		"[color=#a9d8a4]ENDURANCE[/color]       %02d -> %02d DAYS"
		% [service_endurance_start, endurance_days]
	)
	lines.append(
		"[color=#e6a448]INTEGRITY[/color]       %03d%% -> %03d%%"
		% [service_integrity_start, integrity]
	)
	lines.append(
		"[color=#8877a9]COHERENCE[/color]       %03d%% -> %03d%%"
		% [service_coherence_start, coherence]
	)
	lines.append(
		"[color=#8877a9]CARRIER[/color]         " + _service_carrier_state()
	)
	return "\n".join(lines)


func _service_history_line() -> String:
	var groups: Array[String] = []
	for group_index in range(3):
		var entries: Array[String] = []
		for action_index in range(3):
			var history_index := group_index * 3 + action_index
			entries.append(
				_maintenance_system_code(service_history[history_index])
				if history_index < service_history.size()
				else "---"
			)
		groups.append("R%d %s" % [group_index + 1, ">".join(entries)])
	return " / ".join(groups)


func _service_failure_list() -> String:
	var entries: Array[String] = []
	for key in MAINTENANCE_SYSTEMS:
		if service_failures.has(key):
			entries.append(
				"%s %s"
				% [MAINTENANCE_NAMES[key], _service_failure_effect(key)]
			)
	return " / ".join(entries)


func _service_failure_effect(key: String) -> String:
	match key:
		"loop":
			return "-04 INTEGRITY"
		"reserve":
			return "-01 ENDURANCE"
		"carrier":
			return (
				"-03 COHERENCE / CARRIER SILENT"
				if _watch_has_survivor()
				else "-03 COHERENCE / NO CERTIFIED CARRIER"
			)
	return "NO POSTED EFFECT"


func _service_carrier_state() -> String:
	if service_carrier_silent:
		return "SILENT / SERVICE TRANSFER"
	if not _watch_has_survivor():
		return "NO CERTIFIED CARRIER"
	if coherence < 50:
		return "TWO VALID TIMEBASES"
	return _watch_survivor_state()


func _service_overhaul_key() -> String:
	for key in MAINTENANCE_SYSTEMS:
		if key in service_scars:
			return key
	return "loop"


func _service_key_list(keys: Array[String]) -> String:
	if keys.is_empty():
		return "NONE"
	var entries: Array[String] = []
	for key in keys:
		entries.append(_maintenance_system_code(key))
	return " / ".join(entries)


func open_walkback() -> void:
	if phase != Phase.SERVICE_SUMMARY:
		return
	phase = Phase.WALKBACK
	walkback_seal = WALKBACK_SEAL_LIMIT
	walkback_room = "core"
	walkback_path = ["core"]
	walkback_witnesses.clear()
	walkback_hazards.clear()
	for key in MAINTENANCE_SYSTEMS:
		if key in service_scars or service_failures.has(key):
			walkback_hazards.append(key)
	walkback_exposed = false
	walkback_integrity_start = integrity
	walkback_coherence_start = coherence
	walkback_notice = "TETHER LOCKED / LOCAL CLOCK BUS DISCONNECTED"
	outcome_overlay.visible = false
	next_order_button.visible = false
	restart_button.visible = false
	_set_maintenance_console(true, true)
	_append_log("[S+12]     WO-017 local clock walkback opened")
	dialogue_label.text = (
		"Bring two mechanical witnesses back to CORE. A third strengthens the lock."
	)
	_refresh_all()
	_focus_walkback_control()


func move_walkback(index: int) -> void:
	if phase != Phase.WALKBACK:
		return
	var neighbors := _walkback_neighbors(walkback_room)
	if index < 0 or index >= neighbors.size():
		return
	var destination: String = neighbors[index]
	var cost := _walkback_move_cost(walkback_room, destination)
	if cost > walkback_seal:
		walkback_notice = (
			"MOVE REJECTED / %s > %s / COST %02d / SEAL %02d / NO TIMESTAMP"
			% [
				WALKBACK_ROOM_NAMES[walkback_room],
				WALKBACK_ROOM_NAMES[destination],
				cost,
				walkback_seal,
			]
		)
		_refresh_walkback()
		return

	var origin := walkback_room
	walkback_seal -= cost
	walkback_room = destination
	walkback_path.append(destination)
	walkback_notice = (
		"MOVE / %s > %s / SEAL -%02d / %02d REMAIN"
		% [
			WALKBACK_ROOM_NAMES[origin],
			WALKBACK_ROOM_NAMES[destination],
			cost,
			walkback_seal,
		]
	)
	_append_log(
		"[S12:%02d] MOVE %s > %s / seal %02d"
		% [
			WALKBACK_SEAL_LIMIT - walkback_seal,
			_walkback_room_code(origin),
			_walkback_room_code(destination),
			walkback_seal,
		]
	)
	if not _walkback_has_available_action():
		_finish_walkback(true)
		return
	_refresh_all()
	_focus_walkback_control()


func apply_walkback_action() -> void:
	if phase != Phase.WALKBACK:
		return
	if walkback_room == "core":
		if walkback_witnesses.size() < WALKBACK_REQUIRED_WITNESSES:
			walkback_notice = (
				"LOCK REJECTED / %02d OF %02d WITNESSES / NO SEAL / NO TIMESTAMP"
				% [walkback_witnesses.size(), WALKBACK_REQUIRED_WITNESSES]
			)
			_refresh_walkback()
			return
		_finish_walkback(false)
		return
	if (
		walkback_room not in WALKBACK_WITNESS_ROOMS
		or walkback_room in walkback_witnesses
	):
		walkback_notice = (
			"NO UNREAD LOCAL CLOCK / MOVE TO CONTINUE / NO SEAL / NO TIMESTAMP"
		)
		_refresh_walkback()
		return
	if walkback_seal < 1:
		_finish_walkback(true)
		return

	walkback_seal -= 1
	walkback_witnesses.append(walkback_room)
	walkback_notice = (
		"WITNESS %02d/03 / %s CLOCK READ / SEAL -01 / %02d REMAIN"
		% [
			walkback_witnesses.size(),
			WALKBACK_ROOM_NAMES[walkback_room],
			walkback_seal,
		]
	)
	_append_log(
		"[S12:%02d] CLOCK %s / local witness accepted"
		% [
			WALKBACK_SEAL_LIMIT - walkback_seal,
			_walkback_room_code(walkback_room),
		]
	)
	if not _walkback_has_available_action():
		_finish_walkback(true)
		return
	_refresh_all()
	_focus_walkback_control()


func _finish_walkback(exposed: bool) -> void:
	if phase != Phase.WALKBACK:
		return
	if (
		not exposed
		and (
			walkback_room != "core"
			or walkback_witnesses.size() < WALKBACK_REQUIRED_WITNESSES
		)
	):
		return
	walkback_exposed = exposed
	if exposed:
		integrity = maxi(0, integrity - 8)
		coherence = maxi(0, coherence - 6)
	else:
		var full_witness := walkback_witnesses.size() == WALKBACK_WITNESS_ROOMS.size()
		integrity = mini(100, integrity + (6 if full_witness else 3))
		coherence = maxi(0, coherence - (4 if full_witness else 1))
	phase = Phase.WALKBACK_SUMMARY
	_set_maintenance_console(false)
	outcome_kicker.text = (
		"CAMPAIGN LEDGER / SHIFT 12 / WO-011 -> WO-012 -> WO-013 -> "
		+ "WO-014 -> WO-015 -> WO-016 -> WO-017"
	)
	if walkback_exposed:
		outcome_title.text = "THE TETHER REELS YOU HOME."
	elif walkback_witnesses.size() == WALKBACK_WITNESS_ROOMS.size():
		outcome_title.text = "YOUR BADGE ARRIVED FIRST."
	else:
		outcome_title.text = "THE LOCAL CLOCKS AGREE."
	outcome_body.text = (
		"The suit camera records one return. The tether controller records two."
		if walkback_exposed
		else (
			"Three isolated mechanical clocks accept the new control timebase. "
			+ "Each records your deck credential before CORE records your departure."
			if walkback_witnesses.size() == WALKBACK_WITNESS_ROOMS.size()
			else (
				"Two isolated mechanical clocks are enough to stabilize arbitration. "
				+ "The unread witness leaves the arrival sequence unresolved."
			)
		)
	)
	outcome_ledger.text = _walkback_summary_ledger()
	outcome_reveal.text = (
		"TETHER RETURNS 02 / SUIT RETURNS 01 / BADGE CARRIER UNVERIFIED"
		if walkback_exposed
		else (
			"LOCAL CLOCKS AGREE / BADGE ARRIVAL PRECEDES CORE DEPARTURE / "
			+ "CAUSE UNRESOLVED"
			if walkback_witnesses.size() == WALKBACK_WITNESS_ROOMS.size()
			else (
				"LOCAL CLOCKS AGREE / NETWORK TIMEBASE REJECTED / "
				+ "THIRD WITNESS UNREAD"
			)
		)
	)
	dialogue_label.text = (
		"WO-017 is closed. CONTINUITY identifies the earlier credential as yours."
	)
	next_order_button.visible = true
	next_order_button.text = "BEGIN SHIFT 13 / WO-018  [N]"
	restart_button.visible = true
	restart_button.text = "RESTART CAMPAIGN  [R]"
	outcome_overlay.visible = true
	_refresh_all()
	next_order_button.call_deferred("grab_focus")


func _refresh_walkback() -> void:
	if phase != Phase.WALKBACK:
		station_map.set_walkback_state(false, "core", [], [], [])
		return
	_set_maintenance_console(true, true)
	map_section_title.text = "DECK 03 / CLOCK WALKBACK"
	map_section_tag.text = "TETHER LIVE"
	work_section_title.text = "WORK ORDER WO-017"
	work_section_tag.text = "LOCAL TIMEBASE"
	action_section_title.text = "ADJACENT COMPARTMENTS"
	maintenance_work_kicker.text = "WO-017 / MECHANICAL WITNESS BUS / SUIT TETHER"
	maintenance_target_label.text = "MOVE / DIRECT COMMIT"
	station_map.set_walkback_state(
		true,
		walkback_room,
		walkback_path,
		walkback_witnesses,
		walkback_hazards
	)
	maintenance_map_forecast.text = (
		"TETHER · %s · %02d SEAL · DAMAGE %s"
		% [
			_walkback_path_line(),
			walkback_seal,
			_walkback_hazard_line(),
		]
	)
	for index in range(MAINTENANCE_SYSTEMS.size()):
		var key: String = MAINTENANCE_SYSTEMS[index]
		var witness_room: String = WALKBACK_WITNESS_ROOMS[index]
		var track: Label = maintenance_track_labels[key]
		var read := witness_room in walkback_witnesses
		track.text = (
			"%s CLOCK\n%s"
			% [
				WALKBACK_ROOM_NAMES[witness_room],
				"■ READ / LOCAL" if read else "□ UNREAD / SEAL -01",
			]
		)
		track.add_theme_color_override("font_color", PHOSPHOR if read else ICE)

	maintenance_work_title.text = (
		"%s / %02d SEAL / %02d OF 03 WITNESSES"
		% [
			WALKBACK_ROOM_NAMES[walkback_room],
			walkback_seal,
			walkback_witnesses.size(),
		]
	)
	maintenance_work_body.text = (
		"Movement and clock reads spend suit seal. Return two witnesses to CORE "
		+ "for a stable lock; the third improves integrity and costs coherence."
	)
	maintenance_work_ledger.text = _walkback_active_ledger()
	maintenance_work_warning.text = walkback_notice
	maintenance_carrier_label.text = (
		"TETHER / %s / NETWORK CLOCK DISCONNECTED"
		% (
			"TWO CORE POSITIONS"
			if coherence < 50
			else "ONE LOCAL BODYCAM"
		)
	)

	var neighbors := _walkback_neighbors(walkback_room)
	for index in range(MAINTENANCE_SYSTEMS.size()):
		var key: String = MAINTENANCE_SYSTEMS[index]
		var button: Button = maintenance_system_buttons[key]
		if index >= neighbors.size():
			button.text = "  [%d] NO ADJACENT CORRIDOR" % (index + 1)
			button.disabled = true
			button.add_theme_color_override("font_color", MUTED)
			continue
		var destination: String = neighbors[index]
		var cost := _walkback_move_cost(walkback_room, destination)
		var route := _walkback_edge_route(walkback_room, destination)
		var hazard_text := (
			" / %s DAMAGE +01" % _maintenance_system_code(route)
			if route in walkback_hazards
			else " / LOCAL"
		)
		button.text = (
			"  [%d] MOVE TO %s\nSEAL -%02d / AFTER %02d%s"
			% [
				index + 1,
				WALKBACK_ROOM_NAMES[destination],
				cost,
				maxi(0, walkback_seal - cost),
				hazard_text,
			]
		)
		button.disabled = cost > walkback_seal
		button.add_theme_color_override(
			"font_color",
			RED if button.disabled else (AMBER if route in walkback_hazards else PHOSPHOR)
		)

	maintenance_selection_label.text = (
		"LOCATION / %s\nLOCK / %02d OF %02d REQUIRED / 03 OPTIONAL"
		% [
			WALKBACK_ROOM_NAMES[walkback_room],
			walkback_witnesses.size(),
			WALKBACK_REQUIRED_WITNESSES,
		]
	)
	action_section_tag.text = "%02d SEAL" % walkback_seal
	_refresh_walkback_action_button()


func _refresh_walkback_action_button() -> void:
	maintenance_repair_button.add_theme_color_override("font_color", AMBER)
	if walkback_room == "core":
		var ready := walkback_witnesses.size() >= WALKBACK_REQUIRED_WITNESSES
		var full_witness := walkback_witnesses.size() == WALKBACK_WITNESS_ROOMS.size()
		maintenance_repair_button.disabled = not ready
		maintenance_repair_button.text = (
			(
				"[SPACE] LOCK %02d WITNESSES / INT +%02d / COH -%02d"
				% [
					walkback_witnesses.size(),
					6 if full_witness else 3,
					4 if full_witness else 1,
				]
			)
			if ready
			else "[SPACE] LOCK UNAVAILABLE / 02 WITNESSES REQUIRED"
		)
		return
	var unread_witness := (
		walkback_room in WALKBACK_WITNESS_ROOMS
		and walkback_room not in walkback_witnesses
	)
	maintenance_repair_button.disabled = not unread_witness or walkback_seal < 1
	maintenance_repair_button.text = (
		"[SPACE] SAMPLE %s CLOCK / SEAL -01 / AFTER %02d"
		% [WALKBACK_ROOM_NAMES[walkback_room], maxi(0, walkback_seal - 1)]
		if unread_witness
		else "[SPACE] NO UNREAD LOCAL CLOCK / MOVE TO CONTINUE"
	)


func _focus_walkback_control() -> void:
	if phase != Phase.WALKBACK:
		return
	var action_ready := (
		(
			walkback_room == "core"
			and walkback_witnesses.size() >= WALKBACK_REQUIRED_WITNESSES
		)
		or (
			walkback_room in WALKBACK_WITNESS_ROOMS
			and walkback_room not in walkback_witnesses
			and walkback_seal >= 1
		)
	)
	if action_ready:
		maintenance_repair_button.call_deferred("grab_focus")
		return
	for key in MAINTENANCE_SYSTEMS:
		var button: Button = maintenance_system_buttons[key]
		if not button.disabled:
			button.call_deferred("grab_focus")
			return


func _walkback_neighbors(room: String) -> Array[String]:
	var result: Array[String] = []
	for neighbor in WALKBACK_GRAPH.get(room, []):
		result.append(str(neighbor))
	return result


func _walkback_move_cost(origin: String, destination: String) -> int:
	if destination not in _walkback_neighbors(origin):
		return WALKBACK_SEAL_LIMIT + 1
	var route := _walkback_edge_route(origin, destination)
	return 2 if route in walkback_hazards else 1


func _walkback_edge_route(origin: String, destination: String) -> String:
	var rooms: Array[String] = [origin, destination]
	rooms.sort()
	return str(WALKBACK_EDGE_ROUTES.get("|".join(rooms), ""))


func _walkback_has_available_action() -> bool:
	if walkback_room == "core" and walkback_witnesses.size() >= WALKBACK_REQUIRED_WITNESSES:
		return true
	if (
		walkback_room in WALKBACK_WITNESS_ROOMS
		and walkback_room not in walkback_witnesses
		and walkback_seal >= 1
	):
		return true
	for destination in _walkback_neighbors(walkback_room):
		if _walkback_move_cost(walkback_room, destination) <= walkback_seal:
			return true
	return false


func _walkback_active_ledger() -> String:
	return (
		"[color=#e6a448]LOCATION[/color]          "
		+ WALKBACK_ROOM_NAMES[walkback_room] + "\n"
		+ "[color=#e6a448]TETHER PATH[/color]       " + _walkback_path_line() + "\n"
		+ "[color=#8dbdc0]WITNESSES[/color]         " + _walkback_witness_line() + "\n"
		+ "[color=#d45b50]CORRIDOR DAMAGE[/color]   " + _walkback_hazard_line() + "\n"
		+ "[color=#a9d8a4]02-CLOCK LOCK[/color]     INT +03 / COH -01\n"
		+ "[color=#8877a9]03-CLOCK LOCK[/color]     INT +06 / COH -04"
	)


func _walkback_summary_ledger() -> String:
	var lines: Array[String] = [
		"[color=#e6a448]TETHER PATH[/color]      " + _walkback_path_line(),
		"[color=#d45b50]CORRIDOR DAMAGE[/color]  " + _walkback_hazard_line(),
	]
	for room in WALKBACK_WITNESS_ROOMS:
		lines.append(
			"[color=%s]%-18s[/color] %s"
			% [
				"#a9d8a4" if room in walkback_witnesses else "#698b7d",
				WALKBACK_ROOM_NAMES[room] + " CLOCK",
				_walkback_witness_record(room) if room in walkback_witnesses else "UNREAD",
			]
		)
	lines.append(
		"[color=#d45b50]CORE DEPARTURE[/color]    19:04:23 / LOCAL BODYCAM"
	)
	lines.append(
		"[color=#e6a448]INTEGRITY[/color]        %03d%% -> %03d%%"
		% [walkback_integrity_start, integrity]
	)
	lines.append(
		"[color=#8877a9]COHERENCE[/color]        %03d%% -> %03d%%"
		% [walkback_coherence_start, coherence]
	)
	return "\n".join(lines)


func _walkback_witness_record(room: String) -> String:
	match room:
		"med":
			return "18:40:58 / JAE " + _campaign_jae_state()
		"aux":
			return "18:41:09 / MINA " + mina_state.to_upper()
		"bridge":
			var carrier := (
				"SILENT"
				if service_carrier_silent
				else _watch_survivor_state()
			)
			return "18:41:17 / CARRIER " + carrier
	return "NO LOCAL RECORD"


func _walkback_path_line() -> String:
	var entries: Array[String] = []
	for room in walkback_path:
		entries.append(_walkback_room_code(room))
	return ">".join(entries)


func _walkback_witness_line() -> String:
	if walkback_witnesses.is_empty():
		return "NONE / 02 REQUIRED"
	var entries: Array[String] = []
	for room in walkback_witnesses:
		entries.append(_walkback_room_code(room))
	return " / ".join(entries) + " / %02d OF 03" % walkback_witnesses.size()


func _walkback_hazard_line() -> String:
	if walkback_hazards.is_empty():
		return "NONE / ALL CORRIDORS COST 01"
	var entries: Array[String] = []
	for key in walkback_hazards:
		entries.append(
			"%s %s"
			% [_maintenance_system_code(key), _walkback_hazard_source(key)]
		)
	return " / ".join(entries)


func _walkback_hazard_source(key: String) -> String:
	var sources: Array[String] = []
	if key in service_scars:
		sources.append("M9 SCAR")
	if service_failures.has(key):
		sources.append("M10 LOSS")
	return "+".join(sources)


func _walkback_room_code(room: String) -> String:
	match room:
		"core":
			return "COR"
		"med":
			return "MED"
		"aux":
			return "AUX"
		"airlock":
			return "AIR"
		"bridge":
			return "BRG"
	return "---"


func open_splicer() -> void:
	if phase != Phase.WALKBACK_SUMMARY:
		return
	phase = Phase.SPLICER
	splice_index = 0
	splice_choices.clear()
	splice_misfeeds = 0
	splice_tension = SPLICE_TENSION_LIMIT
	splice_degraded = false
	splice_integrity_start = integrity
	splice_coherence_start = coherence
	splice_notice = "RECORDER OPEN / FRESH TAPE ABOVE OLDER PRESSURE IMPRESSION"
	outcome_overlay.visible = false
	next_order_button.visible = false
	restart_button.visible = false
	_set_maintenance_console(true, true)
	_append_log("[S+13]     WO-018 duplex log splicer opened")
	dialogue_label.text = (
		"Match each three-hole gate pattern to one physical tape feed. "
		+ "Two misfeeds tear the recorder."
	)
	_refresh_all()
	_focus_splice_control()


func advance_splice_feed(key: String) -> void:
	if (
		phase != Phase.SPLICER
		or key not in SPLICE_FEEDS
		or splice_index >= SPLICE_TARGET_CODES.size()
	):
		return
	var target_code := int(SPLICE_TARGET_CODES[splice_index])
	var feed_rows: Array = SPLICE_FEED_CODES[key]
	var feed_code := int(feed_rows[splice_index])
	if feed_code == target_code:
		splice_choices.append(key)
		splice_index += 1
		splice_notice = (
			"SEGMENT %02d/06 / %s PUNCH %s ACCEPTED"
			% [
				splice_index,
				SPLICE_FEED_NAMES[key],
				_splice_code_bits(feed_code),
			]
		)
		_append_log(
			"[S13:%02d] SPLICE %s / punch %s accepted"
			% [
				splice_choices.size() + splice_misfeeds,
				_splice_feed_code(key),
				_splice_code_bits(feed_code),
			]
		)
		if splice_index == SPLICE_TARGET_CODES.size():
			splice_notice = "SIX SEGMENTS SEATED / MANUAL CROSS-STAMP REQUIRED"
	else:
		splice_misfeeds += 1
		splice_tension = maxi(0, splice_tension - 1)
		splice_notice = (
			"MISFEED %02d/02 / %s PUNCH %s != GATE %s / TENSION %02d"
			% [
				splice_misfeeds,
				SPLICE_FEED_NAMES[key],
				_splice_code_bits(feed_code),
				_splice_code_bits(target_code),
				splice_tension,
			]
		)
		_append_log(
			"[S13:%02d] MISFEED %s / tension %02d"
			% [
				splice_choices.size() + splice_misfeeds,
				_splice_feed_code(key),
				splice_tension,
			]
		)
		if splice_tension == 0:
			_finish_splice(true)
			return
	_refresh_all()
	_focus_splice_control()


func stamp_splice() -> void:
	if phase != Phase.SPLICER:
		return
	if splice_index != SPLICE_TARGET_CODES.size():
		splice_notice = (
			"CROSS-STAMP REJECTED / %02d OF 06 SEGMENTS / NO FEED / NO TIMESTAMP"
			% splice_index
		)
		_refresh_splicer()
		return
	_finish_splice(false)


func _finish_splice(degraded: bool) -> void:
	if phase != Phase.SPLICER:
		return
	if degraded:
		if splice_tension > 0:
			return
		coherence = maxi(0, coherence - 6)
	else:
		if splice_index != SPLICE_TARGET_CODES.size():
			return
		integrity = mini(100, integrity + 3)
		coherence = maxi(0, coherence - 2)
	splice_degraded = degraded
	phase = Phase.SPLICER_SUMMARY
	_set_maintenance_console(false)
	outcome_kicker.text = (
		"CAMPAIGN LEDGER / SHIFT 13 / WO-011 -> WO-012 -> WO-013 -> "
		+ "WO-014 -> WO-015 -> WO-016 -> WO-017 -> WO-018"
	)
	outcome_title.text = (
		"THE THIRD FEED TEARS."
		if splice_degraded
		else "THE REEL REMEMBERS YOUR HAND."
	)
	outcome_body.text = (
		"Two physical feeds survive the automatic splice. An older pressure "
		+ "impression remains, but the torn track cannot authenticate its order."
		if splice_degraded
		else (
			"The manual cross-stamp closes a mechanically continuous reel. "
			+ "Beneath it, an older impression contains the same six feed choices."
		)
	)
	outcome_ledger.text = _splice_summary_ledger()
	outcome_reveal.text = (
		"UNDERPRINT PRESENT / FRESH REEL PARTIAL / MATCH UNVERIFIED"
		if splice_degraded
		else (
			"SPLICE ORDER PREDATES REPAIR / BOTH IMPRESSIONS MATCH / "
			+ "AUTHORSHIP UNRESOLVED"
		)
	)
	dialogue_label.text = (
		"WO-018 is closed. CONTINUITY classifies the older hand pressure as yours."
	)
	next_order_button.visible = true
	next_order_button.text = "BEGIN SHIFT 14 / WO-019  [N]"
	restart_button.visible = true
	restart_button.text = "RESTART CAMPAIGN  [R]"
	outcome_overlay.visible = true
	_refresh_all()
	next_order_button.call_deferred("grab_focus")


func _refresh_splicer() -> void:
	var display_active := phase in [Phase.SPLICER, Phase.SPLICER_SUMMARY]
	_set_splice_display_visible(display_active)
	if not display_active:
		splice_display.set_splice_state(false, [], {}, 0, [], 0, 0, false)
		return
	splice_display.set_splice_state(
		true,
		SPLICE_TARGET_CODES,
		SPLICE_FEED_CODES,
		splice_index,
		splice_choices,
		splice_tension,
		splice_misfeeds,
		coherence < 50
	)
	map_section_title.text = "CORE / DUPLEX EVENT RECORDER"
	map_section_tag.text = "REEL SEALED" if phase == Phase.SPLICER_SUMMARY else "TAPE LIVE"
	if phase != Phase.SPLICER:
		return

	_set_maintenance_console(true, true)
	map_section_title.text = "CORE / DUPLEX EVENT RECORDER"
	map_section_tag.text = "TAPE LIVE"
	work_section_title.text = "WORK ORDER WO-018"
	work_section_tag.text = "PHYSICAL LOG"
	action_section_title.text = "RECORDER FEEDS"
	maintenance_work_kicker.text = "WO-018 / HARD-COPY EVENT BUS / MANUAL GATE"
	maintenance_target_label.text = "ADVANCE MATCHING PUNCH"
	maintenance_map_forecast.text = (
		"GATE · SEGMENT %02d/06 · TENSION %02d/02 · TARGET %s"
		% [
			splice_index,
			splice_tension,
			(
				_splice_code_bits(int(SPLICE_TARGET_CODES[splice_index]))
				if splice_index < SPLICE_TARGET_CODES.size()
				else "SEALED"
			),
		]
	)
	for index in range(MAINTENANCE_SYSTEMS.size()):
		var key: String = MAINTENANCE_SYSTEMS[index]
		var feed: String = SPLICE_FEEDS[index]
		var track: Label = maintenance_track_labels[key]
		track.text = (
			"%s TAPE\n%s"
			% [
				SPLICE_FEED_NAMES[feed],
				(
					"HEAD " + _splice_code_bits(_splice_feed_code_at(feed, splice_index))
					if splice_index < SPLICE_TARGET_CODES.size()
					else "FEED COMPLETE"
				),
			]
		)
		track.add_theme_color_override("font_color", ICE)

	maintenance_work_title.text = (
		"SEGMENT %02d OF 06 / %02d TENSION"
		% [splice_index, splice_tension]
	)
	maintenance_work_body.text = (
		"Compare the gate's three-hole target with each tape head. A matching "
		+ "feed seats one segment; two mismatches tear the third track."
	)
	maintenance_work_ledger.text = _splice_active_ledger()
	maintenance_work_warning.text = splice_notice
	maintenance_carrier_label.text = (
		"RECORDER / THREE FEEDS / ONE HAND MOVING TWICE"
		if coherence < 50
		else "RECORDER / THREE PHYSICAL FEEDS / ONE MANUAL GATE"
	)

	for index in range(MAINTENANCE_SYSTEMS.size()):
		var key: String = MAINTENANCE_SYSTEMS[index]
		var feed: String = SPLICE_FEEDS[index]
		var button: Button = maintenance_system_buttons[key]
		button.text = (
			"  [%d] ADVANCE %s TAPE\nHEAD %s / GATE %s"
			% [
				index + 1,
				SPLICE_FEED_NAMES[feed],
				(
					_splice_code_bits(_splice_feed_code_at(feed, splice_index))
					if splice_index < SPLICE_TARGET_CODES.size()
					else "---"
				),
				(
					_splice_code_bits(int(SPLICE_TARGET_CODES[splice_index]))
					if splice_index < SPLICE_TARGET_CODES.size()
					else "SEALED"
				),
			]
		)
		button.disabled = splice_index >= SPLICE_TARGET_CODES.size()
		button.add_theme_color_override(
			"font_color",
			MUTED if button.disabled else PHOSPHOR
		)

	maintenance_selection_label.text = (
		"CURRENT GATE / %s\nASSEMBLED / %s"
		% [
			(
				_splice_code_bits(int(SPLICE_TARGET_CODES[splice_index]))
				if splice_index < SPLICE_TARGET_CODES.size()
				else "SEALED"
			),
			_splice_choice_line(),
		]
	)
	action_section_tag.text = "%02d TENSION" % splice_tension
	maintenance_repair_button.disabled = splice_index != SPLICE_TARGET_CODES.size()
	maintenance_repair_button.text = (
		"[SPACE] CROSS-STAMP REEL / INT +03 / COH -02"
		if splice_index == SPLICE_TARGET_CODES.size()
		else (
			"[SPACE] CROSS-STAMP LOCKED / %02d OF 06 SEGMENTS"
			% splice_index
		)
	)
	maintenance_repair_button.add_theme_color_override("font_color", AMBER)


func _set_splice_display_visible(active: bool) -> void:
	station_map.visible = not active
	splice_display.visible = active
	map_legend.visible = not active
	map_note.visible = not active
	splice_legend.visible = active
	splice_note.visible = active


func _focus_splice_control() -> void:
	if phase != Phase.SPLICER:
		return
	if splice_index == SPLICE_TARGET_CODES.size():
		maintenance_repair_button.call_deferred("grab_focus")
		return
	for key in MAINTENANCE_SYSTEMS:
		var button: Button = maintenance_system_buttons[key]
		if not button.disabled:
			button.call_deferred("grab_focus")
			return


func _splice_feed_code_at(feed: String, row: int) -> int:
	if feed not in SPLICE_FEEDS or row < 0 or row >= SPLICE_TARGET_CODES.size():
		return 0
	var rows: Array = SPLICE_FEED_CODES[feed]
	return int(rows[row])


func _splice_expected_feed(row: int) -> String:
	if row < 0 or row >= SPLICE_TARGET_CODES.size():
		return ""
	var target := int(SPLICE_TARGET_CODES[row])
	for feed in SPLICE_FEEDS:
		if _splice_feed_code_at(feed, row) == target:
			return feed
	return ""


func _splice_code_bits(code: int) -> String:
	var bits := ""
	for mask in [4, 2, 1]:
		bits += "1" if code & mask else "0"
	return bits


func _splice_feed_code(feed: String) -> String:
	match feed:
		"core":
			return "COR"
		"tether":
			return "TET"
		"badge":
			return "BDG"
	return "---"


func _splice_choice_line() -> String:
	if splice_choices.is_empty():
		return "NONE / 06 REQUIRED"
	var entries: Array[String] = []
	for feed in splice_choices:
		entries.append(_splice_feed_code(feed))
	return ">".join(entries)


func _splice_source_line() -> String:
	if walkback_exposed:
		return "TETHER RECOVERY / RETURNS 02 / SUIT 01"
	if walkback_witnesses.size() == WALKBACK_WITNESS_ROOMS.size():
		return "03-CLOCK LOCK / BADGE ARRIVAL FIRST"
	return "02-CLOCK LOCK / THIRD WITNESS UNREAD"


func _splice_active_ledger() -> String:
	var gate := (
		_splice_code_bits(int(SPLICE_TARGET_CODES[splice_index]))
		if splice_index < SPLICE_TARGET_CODES.size()
		else "SEALED"
	)
	return (
		"[color=#e6a448]GATE TARGET[/color]       " + gate + "\n"
		+ "[color=#a9d8a4]ASSEMBLED[/color]         " + _splice_choice_line() + "\n"
		+ "[color=#d45b50]MISFEEDS[/color]          %02d / 02\n" % splice_misfeeds
		+ "[color=#8dbdc0]SOURCE RECORD[/color]     " + _splice_source_line() + "\n"
		+ "[color=#a9d8a4]CLEAN STAMP[/color]       INT +03 / COH -02\n"
		+ "[color=#8877a9]TAPE TEAR[/color]         INT +00 / COH -06"
	)


func _splice_summary_ledger() -> String:
	var fresh_state := (
		_splice_choice_line()
		if not splice_degraded
		else _splice_choice_line() + " / PARTIAL"
	)
	return (
		"[color=#8dbdc0]SOURCE RECORD[/color]   " + _splice_source_line() + "\n"
		+ "[color=#a9d8a4]FRESH SPLICE[/color]    " + fresh_state + "\n"
		+ "[color=#d45b50]MISFEEDS[/color]       %02d / 02\n" % splice_misfeeds
		+ "[color=#8877a9]UNDERPRINT[/color]      TET>COR>BDG>TET>BDG>COR / 18:41:22\n"
		+ "[color=#e6a448]CROSS-STAMP[/color]     "
		+ ("AUTOMATIC / THIRD FEED TORN" if splice_degraded else "MANUAL / 19:13:08")
		+ "\n[color=#e6a448]INTEGRITY[/color]       %03d%% -> %03d%%"
		% [splice_integrity_start, integrity]
		+ "\n[color=#8877a9]COHERENCE[/color]       %03d%% -> %03d%%"
		% [splice_coherence_start, coherence]
	)


func open_gyro_cage() -> void:
	if phase != Phase.SPLICER_SUMMARY:
		return
	phase = Phase.GYRO
	gyro_ring_index = 0
	gyro_angles.clear()
	for angle in GYRO_START_ANGLES:
		gyro_angles.append(int(angle))
	gyro_latches.clear()
	gyro_settle = GYRO_SETTLE_LIMIT
	gyro_index_pins = GYRO_INDEX_PIN_LIMIT
	gyro_degraded = false
	gyro_integrity_start = integrity
	gyro_coherence_start = coherence
	gyro_notice = "CAGE OPEN / FOUR MECHANICAL DATUMS / LOAD BUS HARD-WIRED"
	gyro_load_events.clear()
	outcome_overlay.visible = false
	next_order_button.visible = false
	restart_button.visible = false
	_set_maintenance_console(true, true)
	_append_log("[S+14]     WO-019 inertial reference cage opened")
	dialogue_label.text = (
		"Rotate each ring to its printed datum, then latch the index. "
		+ "Nine settle detents remain; two bad index tests slip the cage."
	)
	_refresh_all()
	_focus_gyro_control()


func rotate_gyro(direction: int) -> void:
	if (
		phase != Phase.GYRO
		or direction not in [-1, 1]
		or gyro_ring_index < 0
		or gyro_ring_index >= GYRO_TARGET_ANGLES.size()
		or gyro_settle <= 0
	):
		return
	var prior_angle := gyro_angles[gyro_ring_index]
	gyro_angles[gyro_ring_index] = wrapi(
		prior_angle + direction,
		0,
		GYRO_DETENT_COUNT
	)
	gyro_settle -= 1
	var direction_name := "CCW" if direction < 0 else "CW"
	gyro_notice = (
		"ROTATE %s / %s / %02d > %02d / SETTLE %02d"
		% [
			direction_name,
			GYRO_RING_NAMES[gyro_ring_index],
			prior_angle,
			gyro_angles[gyro_ring_index],
			gyro_settle,
		]
	)
	_append_log(
		"[S14:%02d] GYRO %s / %s / datum %02d / settle %02d"
		% [
			_gyro_event_index(),
			_gyro_ring_code(gyro_ring_index),
			direction_name,
			gyro_angles[gyro_ring_index],
			gyro_settle,
		]
	)
	if (
		gyro_settle == 0
		and gyro_angles[gyro_ring_index] != int(GYRO_TARGET_ANGLES[gyro_ring_index])
	):
		_finish_gyro(true)
		return
	_refresh_all()
	_focus_gyro_control()


func latch_gyro() -> void:
	if (
		phase != Phase.GYRO
		or gyro_ring_index < 0
		or gyro_ring_index >= GYRO_TARGET_ANGLES.size()
	):
		return
	var current_angle := gyro_angles[gyro_ring_index]
	var target_angle := int(GYRO_TARGET_ANGLES[gyro_ring_index])
	if current_angle != target_angle:
		gyro_index_pins = maxi(0, gyro_index_pins - 1)
		gyro_notice = (
			"INDEX REJECTED / %s %02d != DATUM %02d / PINS %02d"
			% [
				GYRO_RING_NAMES[gyro_ring_index],
				current_angle,
				target_angle,
				gyro_index_pins,
			]
		)
		_append_log(
			"[S14:%02d] INDEX REJECTED %s / pins %02d"
			% [
				_gyro_event_index(),
				_gyro_ring_code(gyro_ring_index),
				gyro_index_pins,
			]
		)
		if gyro_index_pins == 0 or gyro_settle == 0:
			_finish_gyro(true)
			return
		_refresh_all()
		_focus_gyro_control()
		return

	var latched_ring := gyro_ring_index
	gyro_latches.append(latched_ring)
	gyro_load_events.append(str(GYRO_LOAD_LINES[latched_ring]))
	gyro_ring_index += 1
	gyro_notice = (
		"RING %02d/04 LATCHED / HAB LOAD ACCEPTED / OPERATOR ZERO"
		% gyro_latches.size()
	)
	_append_log(
		"[S14:%02d] LATCH %s / habitat load accepted"
		% [_gyro_event_index(), _gyro_ring_code(latched_ring)]
	)
	if gyro_ring_index == GYRO_TARGET_ANGLES.size():
		_finish_gyro(false)
		return
	if (
		gyro_settle == 0
		and gyro_angles[gyro_ring_index] != int(GYRO_TARGET_ANGLES[gyro_ring_index])
	):
		_finish_gyro(true)
		return
	_refresh_all()
	_focus_gyro_control()


func _finish_gyro(degraded: bool) -> void:
	if phase != Phase.GYRO:
		return
	if degraded:
		var current_unreachable := (
			gyro_ring_index < GYRO_TARGET_ANGLES.size()
			and gyro_settle == 0
			and gyro_angles[gyro_ring_index] != int(GYRO_TARGET_ANGLES[gyro_ring_index])
		)
		if gyro_index_pins > 0 and not current_unreachable:
			return
		coherence = maxi(0, coherence - 7)
	else:
		if gyro_ring_index != GYRO_TARGET_ANGLES.size():
			return
		integrity = mini(100, integrity + 4)
		coherence = maxi(0, coherence - 3)
	gyro_degraded = degraded
	phase = Phase.GYRO_SUMMARY
	_set_maintenance_console(false)
	outcome_kicker.text = (
		"CAMPAIGN LEDGER / SHIFT 14 / WO-011 -> WO-012 -> WO-013 -> "
		+ "WO-014 -> WO-015 -> WO-016 -> WO-017 -> WO-018 -> WO-019"
	)
	outcome_title.text = (
		"THE CAGE LOSES ITS ZERO."
		if gyro_degraded
		else "THE ZERO HOLDS. THE LOAD MOVES."
	)
	outcome_body.text = (
		"The cage slips before it can certify a stable frame. Its partial load "
		+ "record cannot order the habitat spikes against the failed calibration."
		if gyro_degraded
		else (
			"Four counterweight pulses settle the station. The hard-wired recorder "
			+ "marks four accepted loads on nominally occupied suspension lines."
		)
	)
	outcome_ledger.text = _gyro_summary_ledger()
	outcome_reveal.text = (
		"FRAME UNVERIFIED / HAB LOADS %02d / CAUSAL ORDER UNRESOLVED"
		% gyro_load_events.size()
		if gyro_degraded
		else (
			"FRAME STABLE / HAB LOADS 04 / OCCUPANCY CHANNEL UNVERIFIED"
		)
	)
	dialogue_label.text = (
		"WO-019 is closed. CONTINUITY calls the habitat load routine stabilization."
	)
	next_order_button.visible = true
	next_order_button.text = "BEGIN SHIFT 15 / WO-020  [N]"
	restart_button.visible = true
	restart_button.text = "RESTART CAMPAIGN  [R]"
	outcome_overlay.visible = true
	_refresh_all()
	next_order_button.call_deferred("grab_focus")


func _refresh_gyro() -> void:
	var display_active := phase in [Phase.GYRO, Phase.GYRO_SUMMARY]
	if not display_active:
		gyro_display.set_gyro_state(false, [], [], 0, [], 0, 0, false, 0)
		_set_gyro_display_visible(false)
		return
	_set_gyro_display_visible(true)
	gyro_display.set_gyro_state(
		true,
		gyro_angles,
		GYRO_TARGET_ANGLES,
		gyro_ring_index,
		gyro_latches,
		gyro_settle,
		gyro_index_pins,
		coherence < 50,
		gyro_load_events.size()
	)
	map_section_title.text = "CORE / INERTIAL REFERENCE CAGE"
	map_section_tag.text = "FRAME SET" if phase == Phase.GYRO_SUMMARY else "GYROS LIVE"
	if phase != Phase.GYRO:
		return

	_set_maintenance_console(true, true)
	map_section_title.text = "CORE / INERTIAL REFERENCE CAGE"
	map_section_tag.text = "GYROS LIVE"
	work_section_title.text = "WORK ORDER WO-019"
	work_section_tag.text = "MECHANICAL ZERO"
	action_section_title.text = "GIMBAL CONTROL"
	maintenance_work_kicker.text = "WO-019 / FOUR-RING CAGE / COUNTERWEIGHT BUS"
	maintenance_target_label.text = "ROTATE ACTIVE RING"
	maintenance_map_forecast.text = (
		"RING %02d/04 · SETTLE %02d/09 · PINS %02d/02 · DATUM %s"
		% [
			mini(gyro_ring_index + 1, GYRO_TARGET_ANGLES.size()),
			gyro_settle,
			gyro_index_pins,
			_gyro_current_datum_line(),
		]
	)

	var current_name: String = str(GYRO_RING_NAMES[gyro_ring_index])
	maintenance_track_labels["loop"].text = (
		"ACTIVE RING\n%s" % current_name
	)
	maintenance_track_labels["reserve"].text = (
		"CURRENT / TARGET\n%02d / %02d"
		% [
			gyro_angles[gyro_ring_index],
			int(GYRO_TARGET_ANGLES[gyro_ring_index]),
		]
	)
	maintenance_track_labels["carrier"].text = (
		"HAB LOADS\n%02d / 04" % gyro_load_events.size()
	)
	maintenance_track_labels["loop"].add_theme_color_override("font_color", AMBER)
	maintenance_track_labels["reserve"].add_theme_color_override("font_color", ICE)
	maintenance_track_labels["carrier"].add_theme_color_override("font_color", VIOLET)

	maintenance_work_title.text = (
		"RING %02d OF 04 / %02d SETTLE"
		% [gyro_ring_index + 1, gyro_settle]
	)
	maintenance_work_body.text = (
		"Move the active ring around its eight-detent cage. Latch only on the "
		+ "printed datum; a bad index test spends one of two shear pins."
	)
	maintenance_work_ledger.text = _gyro_active_ledger()
	maintenance_work_warning.text = gyro_notice
	maintenance_carrier_label.text = (
		"LOAD BUS / FOUR OCCUPIED LINES / OR ONE LINE REPEATED"
		if coherence < 50
		else "HARD-WIRED LOAD BUS / OCCUPANCY CHANNEL UNCERTIFIED"
	)

	var ccw_button: Button = maintenance_system_buttons["loop"]
	var cw_button: Button = maintenance_system_buttons["reserve"]
	var pin_button: Button = maintenance_system_buttons["carrier"]
	ccw_button.text = (
		"  [1] ROTATE COUNTER-CLOCKWISE\n%02d > %02d / SETTLE AFTER %02d"
		% [
			gyro_angles[gyro_ring_index],
			_gyro_candidate_angle(-1),
			maxi(0, gyro_settle - 1),
		]
	)
	cw_button.text = (
		"  [2] ROTATE CLOCKWISE\n%02d > %02d / SETTLE AFTER %02d"
		% [
			gyro_angles[gyro_ring_index],
			_gyro_candidate_angle(1),
			maxi(0, gyro_settle - 1),
		]
	)
	ccw_button.disabled = gyro_settle <= 0
	cw_button.disabled = gyro_settle <= 0
	ccw_button.add_theme_color_override(
		"font_color",
		MUTED if ccw_button.disabled else PHOSPHOR
	)
	cw_button.add_theme_color_override(
		"font_color",
		MUTED if cw_button.disabled else PHOSPHOR
	)
	pin_button.text = (
		"  [3] INDEX PIN MONITOR\n%02d / 02 REMAIN / LATCH WITH SPACE"
		% gyro_index_pins
	)
	pin_button.disabled = true
	pin_button.add_theme_color_override("font_color", MUTED)

	var on_datum := (
		gyro_angles[gyro_ring_index] == int(GYRO_TARGET_ANGLES[gyro_ring_index])
	)
	maintenance_selection_label.text = (
		"ACTIVE / %s\nCURRENT %02d / TARGET %02d / DISTANCE %02d"
		% [
			current_name,
			gyro_angles[gyro_ring_index],
			int(GYRO_TARGET_ANGLES[gyro_ring_index]),
			_gyro_shortest_distance(),
		]
	)
	action_section_tag.text = "%02d SETTLE" % gyro_settle
	maintenance_repair_button.disabled = false
	maintenance_repair_button.text = (
		"[SPACE] LATCH %s / HAB LOAD PULSE"
		% current_name
		if on_datum
		else (
			"[SPACE] TEST INDEX / OFF DATUM / PIN AFTER %02d"
			% maxi(0, gyro_index_pins - 1)
		)
	)
	maintenance_repair_button.add_theme_color_override(
		"font_color",
		AMBER if on_datum else RED
	)


func _set_gyro_display_visible(active: bool) -> void:
	gyro_display.visible = active
	gyro_legend.visible = active
	gyro_note.visible = active
	if not active:
		return
	station_map.visible = false
	splice_display.visible = false
	map_legend.visible = false
	map_note.visible = false
	splice_legend.visible = false
	splice_note.visible = false


func _focus_gyro_control() -> void:
	if phase != Phase.GYRO:
		return
	if gyro_angles[gyro_ring_index] == int(GYRO_TARGET_ANGLES[gyro_ring_index]):
		maintenance_repair_button.call_deferred("grab_focus")
		return
	if gyro_settle > 0:
		var current := gyro_angles[gyro_ring_index]
		var target := int(GYRO_TARGET_ANGLES[gyro_ring_index])
		var clockwise := wrapi(target - current, 0, GYRO_DETENT_COUNT)
		var counter_clockwise := wrapi(current - target, 0, GYRO_DETENT_COUNT)
		var focus_key := "reserve" if clockwise <= counter_clockwise else "loop"
		maintenance_system_buttons[focus_key].call_deferred("grab_focus")


func _gyro_candidate_angle(direction: int) -> int:
	if (
		direction not in [-1, 1]
		or gyro_ring_index < 0
		or gyro_ring_index >= gyro_angles.size()
	):
		return 0
	return wrapi(
		gyro_angles[gyro_ring_index] + direction,
		0,
		GYRO_DETENT_COUNT
	)


func _gyro_shortest_distance() -> int:
	if gyro_ring_index < 0 or gyro_ring_index >= GYRO_TARGET_ANGLES.size():
		return 0
	var current := gyro_angles[gyro_ring_index]
	var target := int(GYRO_TARGET_ANGLES[gyro_ring_index])
	var clockwise := wrapi(target - current, 0, GYRO_DETENT_COUNT)
	var counter_clockwise := wrapi(current - target, 0, GYRO_DETENT_COUNT)
	return mini(clockwise, counter_clockwise)


func _gyro_current_datum_line() -> String:
	if gyro_ring_index < 0 or gyro_ring_index >= GYRO_TARGET_ANGLES.size():
		return "LOCKED"
	return (
		"%02d>%02d"
		% [
			gyro_angles[gyro_ring_index],
			int(GYRO_TARGET_ANGLES[gyro_ring_index]),
		]
	)


func _gyro_ring_code(index: int) -> String:
	match index:
		0:
			return "OUT"
		1:
			return "ROL"
		2:
			return "PIT"
		3:
			return "ROT"
	return "---"


func _gyro_event_index() -> int:
	return (
		GYRO_SETTLE_LIMIT - gyro_settle
		+ GYRO_INDEX_PIN_LIMIT - gyro_index_pins
		+ gyro_latches.size()
	)


func _gyro_latch_line() -> String:
	if gyro_latches.is_empty():
		return "NONE / 04 REQUIRED"
	var entries: Array[String] = []
	for ring in gyro_latches:
		entries.append(_gyro_ring_code(ring))
	return ">".join(entries) + " / %02d OF 04" % gyro_latches.size()


func _gyro_source_line() -> String:
	return (
		"TORN REEL / UNDERPRINT UNVERIFIED"
		if splice_degraded
		else "SEALED REEL / UNDERPRINT MATCH"
	)


func _gyro_load_line() -> String:
	if gyro_load_events.is_empty():
		return "NONE RECORDED"
	var entries: Array[String] = []
	for load_event in gyro_load_events:
		var event_text := str(load_event)
		var load_name := event_text.get_slice(" / ", 1).trim_suffix(" LOAD ACCEPTED")
		entries.append("%s@%s" % [load_name, event_text.get_slice(" / ", 0)])
	return ">".join(entries)


func _gyro_final_angle_line() -> String:
	var entries: Array[String] = []
	for angle in gyro_angles:
		entries.append("%02d" % posmod(int(angle), GYRO_DETENT_COUNT))
	return " / ".join(entries)


func _gyro_active_ledger() -> String:
	return (
		"[color=#e6a448]ACTIVE DATUM[/color]      " + _gyro_current_datum_line() + "\n"
		+ "[color=#a9d8a4]LATCHED[/color]           " + _gyro_latch_line() + "\n"
		+ "[color=#8dbdc0]SETTLE[/color]            %02d / 09\n" % gyro_settle
		+ "[color=#d45b50]INDEX PINS[/color]        %02d / 02\n" % gyro_index_pins
		+ "[color=#8877a9]HAB LOADS[/color]         %02d / 04 / SOURCE UNCERTIFIED\n"
		% gyro_load_events.size()
		+ "[color=#a9d8a4]CLEAN ZERO[/color]        INT +04 / COH -03\n"
		+ "[color=#8877a9]CAGE SLIP[/color]         INT +00 / COH -07"
	)


func _gyro_summary_ledger() -> String:
	return (
		"[color=#8dbdc0]SOURCE RECORD[/color]   " + _gyro_source_line() + "\n"
		+ "[color=#a9d8a4]DATUMS PRINT>FINAL[/color]  02 / 04 / 05 / 00 > "
		+ _gyro_final_angle_line() + "\n"
		+ "[color=#a9d8a4]LATCHED[/color]         " + _gyro_latch_line() + "\n"
		+ "[color=#d45b50]INDEX PINS[/color]      %02d / 02 REMAIN\n" % gyro_index_pins
		+ "[color=#8dbdc0]SETTLE[/color]          %02d / 09 REMAIN\n" % gyro_settle
		+ "[color=#8877a9]LOAD RECORDER[/color]   %02d / 04 / " % gyro_load_events.size()
		+ _gyro_load_line() + "\n"
		+ "[color=#e6a448]INTEGRITY[/color]       %03d%% -> %03d%%"
		% [gyro_integrity_start, integrity]
		+ "\n[color=#8877a9]COHERENCE[/color]       %03d%% -> %03d%%"
		% [gyro_coherence_start, coherence]
	)


func open_bus_breakout() -> void:
	if phase != Phase.GYRO_SUMMARY:
		return
	phase = Phase.BUS_BREAKOUT
	bus_bars.clear()
	for _bar in BUS_BAR_NAMES:
		bus_bars.append(true)
	bus_proof_index = 0
	bus_proofs.clear()
	bus_fuses = BUS_FUSE_LIMIT
	bus_rejections = 0
	bus_degraded = false
	bus_integrity_start = integrity
	bus_coherence_start = coherence
	bus_notice = "BREAKOUT OPEN / THREE COPPER BARS COMMON ALL FOUR LOAD LINES"
	outcome_overlay.visible = false
	next_order_button.visible = false
	restart_button.visible = false
	_set_maintenance_console(true, true)
	_append_log("[S+15]     WO-020 suspension bus breakout opened")
	dialogue_label.text = (
		"Set each printed isolation topology, then inject proof. "
		+ "Two rejected pulses will arc the breakout."
	)
	_refresh_all()
	_focus_bus_control()


func toggle_bus_bar(index: int) -> void:
	if phase != Phase.BUS_BREAKOUT or index < 0 or index >= bus_bars.size():
		return
	bus_bars[index] = not bus_bars[index]
	bus_notice = (
		"%s BAR %s / TOPOLOGY %s"
		% [
			BUS_BAR_NAMES[index],
			"CLOSED" if bus_bars[index] else "OPEN",
			_bus_topology_line(bus_bars),
		]
	)
	_append_log(
		"[S15]     BAR %s / %s"
		% [_bus_bar_code(index), "closed" if bus_bars[index] else "opened"]
	)
	_refresh_all()
	_focus_bus_control()


func inject_bus_proof() -> void:
	if (
		phase != Phase.BUS_BREAKOUT
		or bus_proof_index < 0
		or bus_proof_index >= BUS_BAR_TARGETS.size()
	):
		return
	if not _bus_topology_matches_target():
		bus_fuses = maxi(0, bus_fuses - 1)
		bus_rejections += 1
		bus_notice = (
			"PROOF REJECTED / HAVE %s / NEED %s / FUSES %02d"
			% [
				_bus_topology_line(bus_bars),
				_bus_topology_line(BUS_BAR_TARGETS[bus_proof_index]),
				bus_fuses,
			]
		)
		_append_log(
			"[S15:%02d] PROOF REJECTED / %s / fuses %02d"
			% [bus_proof_index + bus_rejections, BUS_PROOF_NAMES[bus_proof_index], bus_fuses]
		)
		if bus_fuses == 0:
			_finish_bus_breakout(true)
			return
		_refresh_all()
		_focus_bus_control()
		return

	var completed_proof := bus_proof_index
	bus_proofs.append(str(BUS_PROOF_LINES[completed_proof]))
	bus_proof_index += 1
	bus_notice = (
		"PROOF %02d/03 ACCEPTED / COPPER %s / LOAD LABELS STILL 04"
		% [bus_proof_index, _bus_topology_line(bus_bars)]
	)
	_append_log(
		"[S15:%02d] PROOF %s / load labels 04"
		% [bus_proof_index + bus_rejections, BUS_PROOF_NAMES[completed_proof]]
	)
	if bus_proof_index == BUS_BAR_TARGETS.size():
		_finish_bus_breakout(false)
		return
	_refresh_all()
	_focus_bus_control()


func _finish_bus_breakout(degraded: bool) -> void:
	if phase != Phase.BUS_BREAKOUT:
		return
	if degraded:
		if bus_fuses > 0:
			return
		coherence = maxi(0, coherence - 6)
	else:
		if bus_proof_index != BUS_BAR_TARGETS.size():
			return
		integrity = mini(100, integrity + 3)
		coherence = maxi(0, coherence - 2)
	bus_degraded = degraded
	phase = Phase.BUS_SUMMARY
	_set_maintenance_console(false)
	outcome_kicker.text = (
		"CAMPAIGN LEDGER / SHIFT 15 / WO-011 -> WO-012 -> WO-013 -> "
		+ "WO-014 -> WO-015 -> WO-016 -> WO-017 -> WO-018 -> WO-019 -> WO-020"
	)
	outcome_title.text = (
		"THE BREAKOUT ARCS SHUT."
		if bus_degraded
		else "THE COPPER OPENS. THE LABELS REMAIN."
	)
	outcome_body.text = (
		"The second rejected proof welds the breakout contacts. Its partial record "
		+ "cannot locate the accepted-load labels relative to the local copper."
		if bus_degraded
		else (
			"Three proof pulses separate every local suspension conductor. "
			+ "The recorder continues to name four accepted habitat loads."
		)
	)
	outcome_ledger.text = _bus_summary_ledger()
	outcome_reveal.text = (
		"BREAKOUT INCOMPLETE / PROOFS %02d / LABEL ORIGIN UNRESOLVED"
		% bus_proofs.size()
		if bus_degraded
		else "LOCAL COPPER OPEN / LOAD LABELS 04 / ORIGIN UPSTREAM"
	)
	dialogue_label.text = (
		"WO-020 is closed. The local conductors are not the source of the labels."
		if not bus_degraded
		else "WO-020 is closed. CONTINUITY accepts the incomplete separation."
	)
	next_order_button.visible = false
	restart_button.visible = true
	restart_button.text = "RESTART CAMPAIGN  [R]"
	outcome_overlay.visible = true
	_refresh_all()
	restart_button.call_deferred("grab_focus")


func _refresh_bus_breakout() -> void:
	var display_active := phase in [Phase.BUS_BREAKOUT, Phase.BUS_SUMMARY]
	if not display_active:
		bus_display.set_bus_state(false, [], [], 0, [], 0, false, 0)
		_set_bus_display_visible(false)
		return
	var target: Array = (
		BUS_BAR_TARGETS[bus_proof_index]
		if bus_proof_index < BUS_BAR_TARGETS.size()
		else BUS_BAR_TARGETS[BUS_BAR_TARGETS.size() - 1]
	)
	_set_bus_display_visible(true)
	bus_display.set_bus_state(
		true,
		bus_bars,
		target,
		bus_proof_index,
		bus_proofs,
		bus_fuses,
		coherence < 50,
		bus_rejections
	)
	map_section_title.text = "CORE / SUSPENSION BUS BREAKOUT"
	map_section_tag.text = "BUS SEALED" if phase == Phase.BUS_SUMMARY else "PROOF LIVE"
	if phase != Phase.BUS_BREAKOUT:
		return

	_set_maintenance_console(true, true)
	map_section_title.text = "CORE / SUSPENSION BUS BREAKOUT"
	map_section_tag.text = "PROOF LIVE"
	work_section_title.text = "WORK ORDER WO-020"
	work_section_tag.text = "GALVANIC ISOLATION"
	action_section_title.text = "KNIFE SWITCHES"
	maintenance_work_kicker.text = "WO-020 / LOCAL COPPER BREAKOUT / RECORDER BUS"
	maintenance_target_label.text = "SET PRINTED TOPOLOGY"
	maintenance_map_forecast.text = (
		"PROOF %02d/03 · %s · FUSES %02d/02 · TARGET %s"
		% [
			bus_proof_index + 1,
			BUS_PROOF_NAMES[bus_proof_index],
			bus_fuses,
			_bus_topology_line(target),
		]
	)

	for index in range(BUS_BAR_NAMES.size()):
		var key: String = str(MAINTENANCE_SYSTEMS[index])
		maintenance_track_labels[key].text = (
			"%s\n%s"
			% [
				BUS_BAR_NAMES[index],
				"CLOSED" if bus_bars[index] else "OPEN",
			]
		)
		maintenance_track_labels[key].add_theme_color_override(
			"font_color",
			AMBER if bus_bars[index] else ICE
		)
		var button: Button = maintenance_system_buttons[key]
		button.disabled = false
		button.text = (
			"  [%d] %s BAR\n%s > %s / TARGET %s"
			% [
				index + 1,
				BUS_BAR_NAMES[index],
				"CLOSED" if bus_bars[index] else "OPEN",
				"OPEN" if bus_bars[index] else "CLOSED",
				"CLOSED" if bool(target[index]) else "OPEN",
			]
		)
		button.add_theme_color_override(
			"font_color",
			PHOSPHOR if bus_bars[index] == bool(target[index]) else AMBER
		)

	maintenance_work_title.text = (
		"PROOF %02d OF 03 / %s"
		% [bus_proof_index + 1, BUS_PROOF_NAMES[bus_proof_index]]
	)
	maintenance_work_body.text = (
		"Open or close the three copper commoning bars until the live topology "
		+ "matches the printed proof. Inject only after the states agree."
	)
	maintenance_work_ledger.text = _bus_active_ledger()
	maintenance_work_warning.text = bus_notice
	maintenance_carrier_label.text = (
		"LOAD LABELS / FOUR OCCUPIED LINES / OR ONE RECORDER LOOP"
		if coherence < 50
		else "LOAD LABELS / FOUR CHANNELS / LOCAL SOURCE UNCERTIFIED"
	)
	maintenance_selection_label.text = (
		"CURRENT %s\nTARGET  %s / %s"
		% [
			_bus_topology_line(bus_bars),
			_bus_topology_line(target),
			"MATCH" if _bus_topology_matches_target() else "OPEN CIRCUIT MISMATCH",
		]
	)
	action_section_tag.text = "%02d FUSES" % bus_fuses
	maintenance_repair_button.disabled = false
	maintenance_repair_button.text = (
		"[SPACE] INJECT %s / LOAD TRACE"
		% BUS_PROOF_NAMES[bus_proof_index]
	)
	maintenance_repair_button.add_theme_color_override(
		"font_color",
		PHOSPHOR if _bus_topology_matches_target() else RED
	)


func _set_bus_display_visible(active: bool) -> void:
	bus_display.visible = active
	bus_legend.visible = active
	bus_note.visible = active
	if not active:
		return
	station_map.visible = false
	splice_display.visible = false
	gyro_display.visible = false
	map_legend.visible = false
	map_note.visible = false
	splice_legend.visible = false
	splice_note.visible = false
	gyro_legend.visible = false
	gyro_note.visible = false


func _focus_bus_control() -> void:
	if phase != Phase.BUS_BREAKOUT:
		return
	if _bus_topology_matches_target():
		maintenance_repair_button.call_deferred("grab_focus")
		return
	var target: Array = BUS_BAR_TARGETS[bus_proof_index]
	for index in range(bus_bars.size()):
		if bus_bars[index] != bool(target[index]):
			maintenance_system_buttons[MAINTENANCE_SYSTEMS[index]].call_deferred(
				"grab_focus"
			)
			return


func _bus_topology_matches_target() -> bool:
	if bus_proof_index < 0 or bus_proof_index >= BUS_BAR_TARGETS.size():
		return false
	var target: Array = BUS_BAR_TARGETS[bus_proof_index]
	if bus_bars.size() != target.size():
		return false
	for index in range(bus_bars.size()):
		if bus_bars[index] != bool(target[index]):
			return false
	return true


func _bus_topology_line(topology: Array) -> String:
	if topology.size() != BUS_BAR_NAMES.size():
		return "---"
	var entries: Array[String] = []
	for closed in topology:
		entries.append("C" if bool(closed) else "O")
	return "/".join(entries)


func _bus_bar_code(index: int) -> String:
	match index:
		0:
			return "PRT"
		1:
			return "CTR"
		2:
			return "STB"
	return "---"


func _bus_proof_line() -> String:
	if bus_proofs.is_empty():
		return "NONE / 03 REQUIRED"
	var entries: Array[String] = []
	for proof in bus_proofs:
		entries.append(_bus_proof_event_field(str(proof), 1))
	return ">".join(entries) + " / %02d OF 03" % bus_proofs.size()


func _bus_proof_time_line() -> String:
	if bus_proofs.is_empty():
		return "NONE RECORDED"
	var entries: Array[String] = []
	for proof in bus_proofs:
		entries.append(_bus_proof_event_field(str(proof), 0))
	return " > ".join(entries)


func _bus_proof_event_field(proof: String, field_index: int) -> String:
	var fields := proof.split("/", false)
	if field_index < 0 or field_index >= fields.size():
		return "UNREADABLE"
	return fields[field_index].strip_edges()


func _bus_source_line() -> String:
	return (
		"SLIPPED FRAME / LOAD ORDER PARTIAL"
		if gyro_degraded
		else "STABLE FRAME / LOAD ORDER 04"
	)


func _bus_load_summary_line() -> String:
	if not bus_degraded:
		return "04 / PERSIST AFTER LOCAL BREAKOUT"
	if bus_proofs.is_empty():
		return "04 / NO VALID BREAKOUT PROOF"
	return (
		"04 / PARTIAL ISOLATION / %02d PROOF%s"
		% [bus_proofs.size(), "" if bus_proofs.size() == 1 else "S"]
	)


func _bus_active_ledger() -> String:
	var target: Array = BUS_BAR_TARGETS[bus_proof_index]
	return (
		"[color=#e6a448]CURRENT BUS[/color]       " + _bus_topology_line(bus_bars) + "\n"
		+ "[color=#8dbdc0]PRINTED TARGET[/color]   " + _bus_topology_line(target) + "\n"
		+ "[color=#a9d8a4]PROOFS[/color]            " + _bus_proof_line() + "\n"
		+ "[color=#d45b50]ARC FUSES[/color]         %02d / 02\n" % bus_fuses
		+ "[color=#8877a9]LOAD LABELS[/color]       04 / LOCAL SOURCE UNCERTIFIED\n"
		+ "[color=#a9d8a4]CLEAN BREAKOUT[/color]    INT +03 / COH -02\n"
		+ "[color=#8877a9]WELDED CONTACTS[/color]   INT +00 / COH -06"
	)


func _bus_summary_ledger() -> String:
	return (
		"[color=#8dbdc0]SOURCE FRAME[/color]    " + _bus_source_line() + "\n"
		+ "[color=#e6a448]FINAL BUS[/color]      " + _bus_topology_line(bus_bars) + "\n"
		+ "[color=#a9d8a4]PROOFS[/color]         " + _bus_proof_line() + "\n"
		+ "[color=#8877a9]PROOF RECORDER[/color] " + _bus_proof_time_line() + "\n"
		+ "[color=#d45b50]ARC FUSES[/color]      %02d / 02 REMAIN / REJECTED %02d\n"
		% [bus_fuses, bus_rejections]
		+ "[color=#8877a9]LOAD LABELS[/color]    " + _bus_load_summary_line() + "\n"
		+ "[color=#e6a448]INTEGRITY[/color]      %03d%% -> %03d%%"
		% [bus_integrity_start, integrity]
		+ "\n[color=#8877a9]COHERENCE[/color]      %03d%% -> %03d%%"
		% [bus_coherence_start, coherence]
	)


func _watch_has_survivor() -> bool:
	return mina_state == "alive" or wo013_responder_result == "RETAINED"


func _watch_survivor_state() -> String:
	if not _watch_has_survivor():
		return "NO CERTIFIED CARRIER"
	if watch_roster_uses == 0:
		return "RESPONDING"
	if watch_roster_uses == 1:
		return "ECHOING"
	return "COMPLIANT"


func _watch_attribution_line() -> String:
	if coherence < 50:
		return "AUTHORSHIP UNRESOLVED / TWO VALID TIMEBASES / EFFECTS VERIFIED"
	return "CREDENTIAL MATCH VERIFIED / AUX-4 OPERATOR KEY"


func _watch_log_line() -> String:
	var entries: Array[String] = []
	for index in range(3):
		if index < watch_actions.size():
			entries.append("D%d %s" % [
				index + 1,
				"MNL" if watch_actions[index] == "manual" else "RST",
			])
		else:
			entries.append("D%d ---" % (index + 1))
	return " / ".join(entries)


func _watch_decision_ledger() -> String:
	return (
		("[color=#e6a448]WATCH DAY[/color]       %02d / 03\n" % watch_day)
		+ "[color=#e6a448]WATCH LOG[/color]       " + _watch_log_line() + "\n"
		+ ("[color=#a9d8a4]ENDURANCE[/color]       %02d DAYS\n" % endurance_days)
		+ ("[color=#e6a448]INTEGRITY[/color]       %03d%%\n" % integrity)
		+ ("[color=#8877a9]COHERENCE[/color]       %03d%%\n" % coherence)
		+ "[color=#a9d8a4]CARRIER[/color]         " + _watch_survivor_state() + "\n"
		+ "[color=#8877a9]ROSTER HEADER[/color]   AUX-4 OPERATOR KEY / RECOVERED PRE-FAULT"
	)


func _archive_packet_ledger() -> String:
	var timebase_state := (
		"TWO VALID ANSWERS / OPERATOR COHERENCE %03d%%" % coherence
		if coherence < 50
		else "MECHANICAL WATCH VERIFIED / OPERATOR COHERENCE %03d%%" % coherence
	)
	var carrier_state := (
		"RETAINED / LOCAL HANDOFF"
		if wo013_responder_result == "RETAINED"
		else "LOST / " + wo013_choice.to_upper()
	)
	var trace_state := "MANUAL TRACE PRESENT" if wo013_verified else "NO MANUAL TRACE"
	return (
		"[color=#e6a448]SEALED PACKET 08-C / BLACK-BOX MIRROR[/color]\n"
		+ "[color=#8877a9]AUTHORITY[/color]        AUX-4 OPERATOR KEY -> CONTINUITY -> WO-011\n"
		+ "[color=#a9d8a4]PACKET WRITE[/color]     SHIFT 06 / 18:41:09\n"
		+ "[color=#a9d8a4]FIRST FAULT[/color]      SHIFT 07 / 19:04:11\n"
		+ "[color=#8877a9]TIMEBASE[/color]         " + timebase_state + "\n"
		+ "[color=#e6a448]CARRIER[/color]          " + carrier_state + " / " + trace_state + "\n"
		+ "[color=#e15b64]DISCREPANCY[/color]      ORDER PREDATES FIRST FAULT / AUTHOR UNRESOLVED"
	)


func _wo013_decision_ledger() -> String:
	var source_state := (
		"TRACED / LOCAL MANUAL"
		if wo013_verified and responders_retained
		else (
			"TRACED / SOURCE ABSENT"
			if wo013_verified
			else ("LIVE / MANUAL JUNCTION" if responders_retained else "ACTIVE / SOURCE ABSENT")
		)
	)
	return (
		("[color=#a9d8a4]ENDURANCE[/color]       %02d DAYS\n" % endurance_days)
		+ "[color=#a9d8a4]M1 / MINA[/color]       " + carried_mina_state + "\n"
		+ "[color=#e6a448]M1 / JAE[/color]        " + carried_jae_state + "\n"
		+ _seal_campaign_ledger_line()
		+ "[color=#8877a9]WO-012 SIGNALS[/color]  "
		+ ("RESPONDING" if responders_retained else "LOST") + "\n"
		+ "[color=#e6a448]LOOP-C COOLANT[/color]  118% / RISING\n"
		+ "[color=#8877a9]MANUAL SOURCE[/color]   " + source_state
	)


func restart_shift() -> void:
	get_tree().reload_current_scene()


func _append_evidence_card(kind: String) -> void:
	if evidence_placeholder.visible:
		evidence_placeholder.visible = false
	var evidence: Dictionary = EVIDENCE[kind]
	var color := VIOLET if kind == "provenance" else ICE
	if kind == "camera" or kind == "mina":
		color = AMBER
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style_box(PANEL_DEEP, color, 1, 7, 4))
	evidence_list.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	box.add_child(_label(str(evidence.code), 8, color))
	var card_title := _label(str(evidence.title), 11, PHOSPHOR, display_font)
	card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(card_title)
	var card_body := _label(str(evidence.body), 9, MUTED)
	card_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(card_body)


func _refresh_all() -> void:
	var remaining := maxi(0, RUPTURE_MINUTE - elapsed_minutes)
	if phase == Phase.BUS_BREAKOUT:
		var bus_remaining := maxi(0, BUS_BAR_TARGETS.size() - bus_proof_index)
		clock_caption_label.text = "PROOF STAGES LEFT"
		clock_label.text = "%02d PRF" % bus_remaining
		clock_label.add_theme_color_override(
			"font_color",
			RED if bus_fuses <= 1 else AMBER
		)
		var bus_track := ""
		for index in range(BUS_BAR_TARGETS.size()):
			bus_track += "■" if index < bus_proof_index else "□"
		time_track_label.text = bus_track
		time_track_label.add_theme_color_override(
			"font_color",
			RED if bus_fuses <= 1 else MUTED
		)
	elif phase == Phase.GYRO:
		clock_caption_label.text = "SETTLE DETENTS LEFT"
		clock_label.text = "%02d DET" % gyro_settle
		clock_label.add_theme_color_override(
			"font_color",
			RED if gyro_settle <= 2 else AMBER
		)
		var gyro_track := ""
		for index in range(GYRO_SETTLE_LIMIT):
			gyro_track += "■" if index < GYRO_SETTLE_LIMIT - gyro_settle else "□"
		time_track_label.text = gyro_track
		time_track_label.add_theme_color_override(
			"font_color",
			RED if gyro_settle <= 2 else MUTED
		)
	elif phase == Phase.SPLICER:
		clock_caption_label.text = "SPLICE SEGMENTS"
		clock_label.text = "%02d / 06" % splice_index
		clock_label.add_theme_color_override(
			"font_color",
			RED if splice_tension <= 1 else AMBER
		)
		var splice_track := ""
		for index in range(SPLICE_TARGET_CODES.size()):
			splice_track += "■" if index < splice_index else "□"
		time_track_label.text = splice_track
		time_track_label.add_theme_color_override(
			"font_color",
			RED if splice_tension <= 1 else MUTED
		)
	elif phase == Phase.WALKBACK:
		clock_caption_label.text = "SUIT SEAL REMAINING"
		clock_label.text = "%02d SEAL" % walkback_seal
		clock_label.add_theme_color_override(
			"font_color",
			RED if walkback_seal <= 2 else AMBER
		)
		var walkback_track := ""
		for index in range(WALKBACK_SEAL_LIMIT):
			walkback_track += "■" if index < walkback_seal else "□"
		time_track_label.text = walkback_track
		time_track_label.add_theme_color_override(
			"font_color",
			RED if walkback_seal <= 2 else MUTED
		)
	elif phase == Phase.SERVICE_RUN:
		var service_remaining := maxi(0, SERVICE_ACTION_LIMIT - service_action)
		clock_caption_label.text = "SERVICE ACTIONS LEFT"
		clock_label.text = "%02d ACT" % service_remaining
		clock_label.add_theme_color_override(
			"font_color",
			RED if service_remaining <= 2 else AMBER
		)
		var service_track := ""
		for index in range(SERVICE_ACTION_LIMIT):
			service_track += "■" if index < service_action else "□"
		time_track_label.text = service_track
		time_track_label.add_theme_color_override(
			"font_color",
			RED if service_remaining <= 2 else MUTED
		)
	elif phase == Phase.MAINTENANCE:
		var strokes_remaining := maxi(0, 2 - maintenance_strokes)
		clock_caption_label.text = "PULSE %02d / 03" % maintenance_pulse
		clock_label.text = "%02d STK" % strokes_remaining
		clock_label.add_theme_color_override(
			"font_color",
			RED if strokes_remaining <= 1 else AMBER
		)
		var maintenance_track := ""
		for index in range(6):
			maintenance_track += "■" if index < maintenance_allocations.size() else "□"
		time_track_label.text = maintenance_track
		time_track_label.add_theme_color_override(
			"font_color",
			RED if strokes_remaining <= 1 else MUTED
		)
	elif phase == Phase.WATCH:
		var watch_remaining := maxi(0, 3 - watch_day)
		clock_caption_label.text = "WATCH DAYS LEFT"
		clock_label.text = "%02dd" % watch_remaining
		clock_label.add_theme_color_override(
			"font_color",
			RED if watch_remaining <= 1 else AMBER
		)
		var watch_track := ""
		for index in range(3):
			watch_track += "■" if index < watch_day else "□"
		time_track_label.text = watch_track
		time_track_label.add_theme_color_override(
			"font_color",
			RED if watch_remaining <= 1 else MUTED
		)
	elif phase == Phase.REPAIR_2:
		var wo013_remaining := maxi(0, WO013_WINDOW - wo013_elapsed_minutes)
		clock_caption_label.text = "WO-013 WINDOW"
		clock_label.text = "%02d:00" % wo013_remaining
		clock_label.add_theme_color_override("font_color", RED if wo013_remaining <= 1 else AMBER)
		var wo013_track := ""
		for index in range(WO013_WINDOW):
			wo013_track += "■" if index < wo013_elapsed_minutes else "□"
		time_track_label.text = wo013_track
		time_track_label.add_theme_color_override(
			"font_color",
			RED if wo013_remaining <= 1 else MUTED
		)
	elif phase in [
		Phase.OUTCOME,
		Phase.FOLLOWUP,
		Phase.SUMMARY,
		Phase.FINAL_SUMMARY,
		Phase.WATCH_SUMMARY,
		Phase.MAINTENANCE_SUMMARY,
		Phase.SERVICE_SUMMARY,
		Phase.WALKBACK_SUMMARY,
		Phase.SPLICER_SUMMARY,
		Phase.GYRO_SUMMARY,
		Phase.BUS_SUMMARY,
	]:
		clock_caption_label.text = "REPAIR WINDOW"
		clock_label.text = "CLOSED"
		clock_label.add_theme_color_override("font_color", MUTED)
		time_track_label.text = "────────────"
		time_track_label.add_theme_color_override("font_color", MUTED)
	else:
		clock_caption_label.text = "UNTIL CASCADE"
		clock_label.text = "%02d:00" % remaining
		clock_label.add_theme_color_override("font_color", RED if remaining <= 3 else AMBER)
		var track := ""
		for index in range(RUPTURE_MINUTE):
			track += "■" if index < elapsed_minutes else "□"
		time_track_label.text = track
		time_track_label.add_theme_color_override("font_color", RED if remaining <= 3 else MUTED)
	integrity_bar.value = integrity
	integrity_value_label.text = "%03d%%" % integrity
	coherence_bar.value = coherence
	coherence_value_label.text = "%03d%%" % coherence
	match phase:
		Phase.OUTCOME:
			phase_label.text = "SHIFT 07  /  OUTCOME LOCKED"
		Phase.FOLLOWUP:
			phase_label.text = "SHIFT 07  /  WO-012 DISPOSITION"
		Phase.SUMMARY:
			phase_label.text = "SHIFT 07  /  ENDURANCE RECALCULATED"
		Phase.REPAIR_2:
			phase_label.text = "SHIFT 08  /  SERVICE-SPINE CONTROL"
		Phase.FINAL_SUMMARY:
			phase_label.text = "SHIFT 08  /  ENDURANCE RECALCULATED"
		Phase.WATCH:
			phase_label.text = "SHIFT 09  /  RECOVERY WATCH ACTIVE"
		Phase.WATCH_SUMMARY:
			phase_label.text = "SHIFT 09  /  WATCH ROSTER SEALED"
		Phase.MAINTENANCE:
			phase_label.text = "SHIFT 10  /  MAINTENANCE ROTATION ACTIVE"
		Phase.MAINTENANCE_SUMMARY:
			phase_label.text = "SHIFT 10  /  ROTATION SEALED"
		Phase.SERVICE_RUN:
			phase_label.text = "SHIFT 11  /  SERVICE TRANSFER ACTIVE"
		Phase.SERVICE_SUMMARY:
			phase_label.text = "SHIFT 11  /  SERVICE RUN SEALED"
		Phase.WALKBACK:
			phase_label.text = "SHIFT 12  /  LOCAL CLOCK WALKBACK"
		Phase.WALKBACK_SUMMARY:
			phase_label.text = "SHIFT 12  /  TIMEBASE LOCK SEALED"
		Phase.SPLICER:
			phase_label.text = "SHIFT 13  /  DUPLEX LOG SPLICER"
		Phase.SPLICER_SUMMARY:
			phase_label.text = "SHIFT 13  /  PHYSICAL REEL SEALED"
		Phase.GYRO:
			phase_label.text = "SHIFT 14  /  INERTIAL REFERENCE CAGE"
		Phase.GYRO_SUMMARY:
			phase_label.text = "SHIFT 14  /  REFERENCE FRAME SEALED"
		Phase.BUS_BREAKOUT:
			phase_label.text = "SHIFT 15  /  SUSPENSION BUS BREAKOUT"
		Phase.BUS_SUMMARY:
			phase_label.text = "SHIFT 15  /  LOCAL COPPER SEALED"
		_:
			phase_label.text = "SHIFT 07  /  AUXILIARY CONTROL NODE 04"
	match phase:
		Phase.BUS_BREAKOUT:
			shortcuts_label.text = "[1–3] TOGGLE BAR   [SPACE] INJECT PROOF"
		Phase.GYRO:
			shortcuts_label.text = "[1] ROTATE CCW   [2] ROTATE CW   [SPACE] LATCH"
		Phase.SPLICER:
			shortcuts_label.text = "[1–3] ADVANCE TAPE   [SPACE] CROSS-STAMP"
		Phase.WALKBACK:
			shortcuts_label.text = "[1–3] MOVE ADJACENT   [SPACE] READ / LOCK"
		Phase.SERVICE_RUN:
			shortcuts_label.text = "[1–3] SELECT ROUTE   [SPACE] APPLY SERVICE"
		Phase.MAINTENANCE:
			shortcuts_label.text = "[1–3] SELECT ROUTE   [SPACE] APPLY REPAIR STROKE"
		Phase.MAINTENANCE_SUMMARY:
			shortcuts_label.text = "[N] BEGIN SHIFT 11   [R] RESTART CAMPAIGN"
		Phase.SERVICE_SUMMARY:
			shortcuts_label.text = "[N] BEGIN SHIFT 12   [R] RESTART CAMPAIGN"
		Phase.WALKBACK_SUMMARY:
			shortcuts_label.text = "[N] BEGIN SHIFT 13   [R] RESTART CAMPAIGN"
		Phase.SPLICER_SUMMARY:
			shortcuts_label.text = "[N] BEGIN SHIFT 14   [R] RESTART CAMPAIGN"
		Phase.GYRO_SUMMARY:
			shortcuts_label.text = "[N] BEGIN SHIFT 15   [R] RESTART CAMPAIGN"
		Phase.BUS_SUMMARY:
			shortcuts_label.text = "[R] RESTART CAMPAIGN"
		_:
			shortcuts_label.text = "[1–4] VERIFY   [5–9] FIELD   [E/B/I] COMMIT"

	if collected.has("provenance"):
		provenance_label.text = "VENN.CREDENTIAL †  ›  SIM/ADVERSARIAL  ›  CONTINUITY  ›  WO-011"
		provenance_label.add_theme_color_override("font_color", VIOLET)
	else:
		provenance_label.text = "CORE/FAULT  ›  WATCH/AUTO  ›  CONTINUITY  ›  WO-011"
		provenance_label.add_theme_color_override("font_color", AMBER)

	var risk_note := "  ·  OCCUPANCY CONFLICT" if _mina_was_known() else ""
	order_meta_label.text = "CONFIDENCE 99.2%  ·  EXPECTED CREW LOSS 00  ·  COST 03m" + risk_note
	order_meta_label.add_theme_color_override("font_color", RED if _mina_was_known() else MUTED)
	_refresh_order_review()
	_refresh_crew()
	_refresh_buttons()
	_refresh_log()
	station_map.set_scenario_state(
		elapsed_minutes,
		_map_mina_state(),
		outcome_id,
		coherence,
		jae_supported,
		inner_seal_braced,
		timeline_events.has("seal_deformation")
	)
	_refresh_maintenance()
	_refresh_service()
	_refresh_walkback()
	_refresh_splicer()
	_refresh_gyro()
	_refresh_bus_breakout()
	queue_redraw()


func _refresh_order_review() -> void:
	order_review_panel.visible = order_review_open and phase == Phase.ACTIVE
	order_review_button.disabled = phase != Phase.ACTIVE
	order_review_button.text = (
		"[O] CLOSE PHYSICAL OPERATIONS"
		if order_review_open
		else "[O] REVIEW PHYSICAL OPERATIONS"
	)
	var occupancy_line := (
		"OCCUPANCY CONFLICT / LIVE HUMAN SIGNAL IN AUX-4"
		if _mina_was_known()
		else "OCCUPANCY / CLEARED BY CERTIFIED MANIFEST"
	)
	var authority_line := (
		"AUTHORITY CONFLICT / VENN.CREDENTIAL IS SIM/ADVERSARIAL"
		if collected.has("provenance")
		else "AUTHORITY / CONTINUITY-CERTIFIED"
	)
	order_review_warning_label.text = occupancy_line + "\n" + authority_line
	order_review_warning_label.add_theme_color_override(
		"font_color",
		RED if _mina_was_known() else (VIOLET if collected.has("provenance") else MUTED)
	)


func _refresh_crew() -> void:
	var jae_color := RED if elapsed_minutes >= 10 and not jae_supported else AMBER
	var jae_text := (
		"SIGNAL LOST / MED-2"
		if outcome_id == "rupture"
		else (
			"ON RESERVE / MED-2"
			if jae_supported
			else ("DECEASED / MED-2" if elapsed_minutes >= 10 else (
				"FAILING / MED-2" if elapsed_minutes >= 6 else "CRITICAL / MED-2"
			))
		)
	)
	if outcome_id == "rupture":
		jae_color = RED
	_set_crew_widget("jae", jae_text, jae_color)
	if mina_state == "dead":
		_set_crew_widget("mina", "DECEASED / AUX-4", RED)
	elif _mina_was_known() or phase == Phase.OUTCOME:
		_set_crew_widget("mina", "ALIVE / AUX-4", PHOSPHOR)
	else:
		_set_crew_widget("mina", "NO RETURN / UNKNOWN", VIOLET)
	if phase in [Phase.WATCH, Phase.WATCH_SUMMARY] and mina_state == "alive":
		var watch_state := _watch_survivor_state()
		var watch_color := (
			PHOSPHOR
			if watch_state == "RESPONDING"
			else (AMBER if watch_state == "ECHOING" else VIOLET)
		)
		_set_crew_widget("mina", watch_state + " / WATCH", watch_color)


func _refresh_buttons() -> void:
	watch_action_box.visible = phase == Phase.WATCH
	watch_manual_button.disabled = phase != Phase.WATCH or watch_day >= 3
	watch_roster_button.disabled = phase != Phase.WATCH or watch_day >= 3
	watch_status_label.text = (
		"NEXT ENTRY %02d / 03  ·  CARRIER %s"
		% [mini(3, watch_day + 1), _watch_survivor_state()]
	)
	watch_status_label.add_theme_color_override(
		"font_color",
		VIOLET if watch_roster_uses > 0 else ICE
	)
	watch_roster_button.text = (
		"[E] ACCEPT RECOVERED ROSTER\nEND +01d / INT +03 / COH -06 / "
		+ (
			"CARRIER DEGRADES"
			if _watch_has_survivor()
			else "NO CARRIER / ENTRY STILL ACCEPTED"
		)
	)
	support_button.disabled = phase != Phase.ACTIVE or jae_supported
	support_button.text = (
		"[5] O₂ LOGGED"
		if jae_supported
		else "[5] O₂  −03m"
	)
	for key in action_buttons:
		var button: Button = action_buttons[key]
		button.disabled = phase != Phase.ACTIVE or collected.has(key)
		button.text = str(button.get_meta("base_text")) + ("  / LOGGED" if collected.has(key) else "")
	for key in commit_buttons:
		var commit: Button = commit_buttons[key]
		commit.disabled = phase != Phase.ACTIVE
		commit.text = str(commit.get_meta("base_text"))
	var isolate: Button = commit_buttons.isolate
	if phase == Phase.ACTIVE and not _is_isolate_unlocked():
		isolate.disabled = true
		isolate.text = str(isolate.get_meta("base_text")) + "  / LOCKED"
	elif phase == Phase.ACTIVE:
		isolate.text = str(isolate.get_meta("base_text")) + "  / READY"
	var seal_action_visible := (
		phase == Phase.ACTIVE
		and timeline_events.has("seal_deformation")
	)
	var brace_rig_available := _brace_rig_available()
	var brace_rig_ready := _brace_rig_ready()
	seal_action_panel.visible = seal_action_visible
	seal_brace_button.visible = not brace_rig_open or inner_seal_braced
	seal_brace_button.disabled = not brace_rig_available
	seal_brace_button.text = (
		"[6] BRACED"
		if inner_seal_braced
		else "[6] OPEN RIG\nLOCK -01m"
	)
	brace_rig_controls.visible = (
		seal_action_visible and brace_rig_open and not inner_seal_braced
	)
	brace_port_button.text = "[7] PORT  %d/2" % brace_port_tension
	brace_starboard_button.text = "[8] STBD  %d/2" % brace_starboard_tension
	brace_lock_button.text = "[9] LOCK"
	brace_port_button.disabled = (
		not brace_rig_available
		or not brace_rig_open
		or brace_port_tension >= 2
		or brace_port_tension > brace_starboard_tension
	)
	brace_starboard_button.disabled = (
		not brace_rig_available
		or not brace_rig_open
		or brace_starboard_tension >= 2
		or brace_starboard_tension > brace_port_tension
	)
	brace_lock_button.disabled = not brace_rig_available or not brace_rig_ready
	if inner_seal_braced:
		seal_action_status.text = "BRACED / LOCAL ROUTES +08 INT / PURGE NO BENEFIT"
	elif brace_rig_open:
		var brace_guidance := (
			"READY TO LOCK"
			if brace_rig_ready
			else (
				"TENSION STARBOARD"
				if brace_port_tension > brace_starboard_tension
				else (
					"TENSION PORT"
					if brace_starboard_tension > brace_port_tension
					else "LOAD EITHER SHOE"
				)
			)
		)
		seal_action_status.text = (
			"RIG / PORT %d/2 / STBD %d/2 / %s\n"
			+ "LOCK -01m / +08 LOCAL INT / PURGE NO BENEFIT"
		) % [brace_port_tension, brace_starboard_tension, brace_guidance]
	else:
		seal_action_status.text = (
			"DEFORMING / LOCAL ROUTES +08 INT / PURGE NO BENEFIT"
		)
	seal_action_status.add_theme_color_override(
		"font_color",
		PHOSPHOR if inner_seal_braced or brace_rig_ready else (
			AMBER if brace_rig_open else MUTED
		)
	)


func _refresh_log() -> void:
	var visible_lines := log_lines.slice(maxi(0, log_lines.size() - 4), log_lines.size())
	var rendered := ""
	for line in visible_lines:
		rendered += "[color=#698b7d]" + line + "[/color]\n"
	log_view.text = rendered.trim_suffix("\n")


func _append_log(text: String) -> void:
	log_lines.append(text)


func _set_crew_widget(key: String, state_text: String, color: Color) -> void:
	var widget: Dictionary = crew_widgets[key]
	var marker: ColorRect = widget.marker
	var state: Label = widget.state
	marker.color = color
	state.text = state_text
	state.add_theme_color_override("font_color", color)


func _is_isolate_unlocked() -> bool:
	return collected.has("camera") and collected.has("provenance")


func _mina_was_known() -> bool:
	return collected.has("camera") or collected.has("mina")


func _map_mina_state() -> String:
	if mina_state == "dead":
		return "dead"
	if _mina_was_known() or phase == Phase.OUTCOME:
		return "alive"
	return "unknown"


func _campaign_jae_state() -> String:
	if jae_supported:
		return "CRITICAL / RESERVE"
	if elapsed_minutes >= 10:
		return "DECEASED"
	return "CRITICAL / SIGNAL PRESENT"


func _seal_integrity_bonus() -> int:
	return SEAL_BRACE_INTEGRITY_BONUS if inner_seal_braced else 0


func _seal_ledger_line(applied: bool = true) -> String:
	if not inner_seal_braced:
		return ""
	var result := "BRACED / +%02d INTEGRITY" % SEAL_BRACE_INTEGRITY_BONUS
	if not applied:
		result = (
			"BRACED / LOST WITH AUX-4"
			if outcome_id == "rupture"
			else "BRACED / PURGE NO BENEFIT"
		)
	return (
		"\n[color=#a9d8a4]INNER SEAL[/color]     " + result
	)


func _seal_campaign_ledger_line() -> String:
	if not inner_seal_braced:
		return ""
	var result := (
		"BRACED / NO PURGE BENEFIT"
		if outcome_id == "purge"
		else "BRACED / +%02d LOCAL INT" % SEAL_BRACE_INTEGRITY_BONUS
	)
	return (
		"[color=#a9d8a4]M1 / SEAL[/color]       " + result + "\n"
	)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if phase == Phase.BOOT:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			start_shift()
		return
	if phase == Phase.ACTIVE:
		match event.keycode:
			KEY_1, KEY_KP_1:
				take_evidence("telemetry")
			KEY_2, KEY_KP_2:
				take_evidence("camera")
			KEY_3, KEY_KP_3:
				take_evidence("mina")
			KEY_4, KEY_KP_4:
				take_evidence("provenance")
			KEY_5, KEY_KP_5:
				stabilize_jae()
			KEY_6, KEY_KP_6:
				open_brace_rig()
			KEY_7, KEY_KP_7:
				tension_brace_port()
			KEY_8, KEY_KP_8:
				tension_brace_starboard()
			KEY_9, KEY_KP_9:
				lock_brace_rig()
			KEY_O:
				toggle_order_review()
			KEY_E:
				commit_choice("purge")
			KEY_B:
				commit_choice("bypass")
			KEY_I:
				commit_choice("isolate")
		return
	if phase == Phase.OUTCOME:
		if event.keycode == KEY_N and next_order_button.visible:
			open_next_order()
		elif event.keycode == KEY_R:
			restart_shift()
		return
	if phase == Phase.FOLLOWUP:
		if event.keycode == KEY_S:
			resolve_followup("sterilize")
		elif event.keycode == KEY_Q:
			resolve_followup("quarantine")
		return
	if phase == Phase.SUMMARY:
		if event.keycode == KEY_N and next_order_button.visible:
			open_next_order()
		elif event.keycode == KEY_R:
			restart_shift()
		return
	if phase == Phase.REPAIR_2:
		if event.keycode == KEY_V:
			trace_wo013_signal()
		elif event.keycode == KEY_E:
			resolve_wo013("remote")
		elif event.keycode == KEY_H:
			resolve_wo013("handoff")
		return
	if phase == Phase.FINAL_SUMMARY:
		if event.keycode == KEY_A:
			open_archive_packet()
		elif event.keycode == KEY_N and next_order_button.visible:
			open_next_order()
		elif event.keycode == KEY_R:
			restart_shift()
		return
	if phase == Phase.WATCH:
		if event.keycode == KEY_H:
			resolve_watch("manual")
		elif event.keycode == KEY_E:
			resolve_watch("roster")
		return
	if phase == Phase.WATCH_SUMMARY:
		if event.keycode == KEY_N and next_order_button.visible:
			open_next_order()
		elif event.keycode == KEY_R:
			restart_shift()
		return
	if phase == Phase.MAINTENANCE:
		match event.keycode:
			KEY_1, KEY_KP_1:
				select_maintenance_system("loop")
			KEY_2, KEY_KP_2:
				select_maintenance_system("reserve")
			KEY_3, KEY_KP_3:
				select_maintenance_system("carrier")
			KEY_SPACE:
				apply_maintenance_stroke()
		return
	if phase == Phase.MAINTENANCE_SUMMARY:
		if event.keycode == KEY_N and next_order_button.visible:
			open_next_order()
		elif event.keycode == KEY_R:
			restart_shift()
		return
	if phase == Phase.SERVICE_RUN:
		match event.keycode:
			KEY_1, KEY_KP_1:
				select_service_system("loop")
			KEY_2, KEY_KP_2:
				select_service_system("reserve")
			KEY_3, KEY_KP_3:
				select_service_system("carrier")
			KEY_SPACE:
				apply_service_action()
		return
	if phase == Phase.SERVICE_SUMMARY:
		if event.keycode == KEY_N and next_order_button.visible:
			open_next_order()
		elif event.keycode == KEY_R:
			restart_shift()
		return
	if phase == Phase.WALKBACK:
		match event.keycode:
			KEY_1, KEY_KP_1:
				move_walkback(0)
			KEY_2, KEY_KP_2:
				move_walkback(1)
			KEY_3, KEY_KP_3:
				move_walkback(2)
			KEY_SPACE:
				apply_walkback_action()
		return
	if phase == Phase.WALKBACK_SUMMARY:
		if event.keycode == KEY_N and next_order_button.visible:
			open_next_order()
		elif event.keycode == KEY_R:
			restart_shift()
		return
	if phase == Phase.SPLICER:
		match event.keycode:
			KEY_1, KEY_KP_1:
				advance_splice_feed("core")
			KEY_2, KEY_KP_2:
				advance_splice_feed("tether")
			KEY_3, KEY_KP_3:
				advance_splice_feed("badge")
			KEY_SPACE:
				stamp_splice()
		return
	if phase == Phase.SPLICER_SUMMARY:
		if event.keycode == KEY_N and next_order_button.visible:
			open_next_order()
		elif event.keycode == KEY_R:
			restart_shift()
		return
	if phase == Phase.GYRO:
		match event.keycode:
			KEY_1, KEY_KP_1:
				rotate_gyro(-1)
			KEY_2, KEY_KP_2:
				rotate_gyro(1)
			KEY_SPACE:
				latch_gyro()
		return
	if phase == Phase.GYRO_SUMMARY:
		if event.keycode == KEY_N and next_order_button.visible:
			open_next_order()
		elif event.keycode == KEY_R:
			restart_shift()
		return
	if phase == Phase.BUS_BREAKOUT:
		match event.keycode:
			KEY_1, KEY_KP_1:
				toggle_bus_bar(0)
			KEY_2, KEY_KP_2:
				toggle_bus_bar(1)
			KEY_3, KEY_KP_3:
				toggle_bus_bar(2)
			KEY_SPACE:
				inject_bus_proof()
		return
	if phase == Phase.BUS_SUMMARY:
		if event.keycode == KEY_R:
			restart_shift()


func _label(text: String, font_size: int, color: Color, font: Font = null) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font if font != null else mono_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _thin_rule(color: Color) -> ColorRect:
	var rule := ColorRect.new()
	rule.color = color
	rule.custom_minimum_size.y = 1
	return rule


func _fill_box(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	return style


func _style_box(
	background: Color,
	border: Color,
	width: int = 1,
	padding: int = 8,
	left_width: int = -1
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = left_width if left_width >= 0 else width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width
	style.content_margin_left = padding
	style.content_margin_top = padding
	style.content_margin_right = padding
	style.content_margin_bottom = padding
	return style


func _alpha(color: Color, value: float) -> Color:
	var result := color
	result.a = value
	return result
