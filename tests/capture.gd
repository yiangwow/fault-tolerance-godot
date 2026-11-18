extends SceneTree

const CAPTURE_DIR := "res://captures"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	await _capture_boot()
	await _capture_active()
	await _capture_brace_rig()
	await _capture_braced_seal()
	await _capture_order_review()
	await _capture_purge()
	await _capture_next_order()
	await _capture_campaign_summary()
	await _capture_wo013_repair()
	await _capture_campaign_ledger()
	await _capture_archive_packet()
	await _capture_watch_roster_day_two()
	await _capture_watch_summary()
	await _capture_maintenance_active()
	await _capture_maintenance_failure()
	await _capture_maintenance_ledger()
	await _capture_service_active()
	await _capture_service_carrier_failure()
	await _capture_service_ledger()
	await _capture_walkback_active()
	await _capture_walkback_mid_route()
	await _capture_walkback_three_witness_ledger()
	await _capture_splicer_active()
	await _capture_splicer_misfeed()
	await _capture_splicer_ledger()
	await _capture_gyro_active()
	await _capture_gyro_index_rejected()
	await _capture_gyro_ledger()
	await _capture_bus_active()
	await _capture_bus_arc_rejected()
	await _capture_bus_ledger()
	print(
		"CAPTURE PASS: boot, active, brace-rig, braced-seal, order-review, purge, follow-up, campaign-summary, WO-013, final-ledger, sealed-packet, recovered-watch, and maintenance "
		+ "and service, clock-walkback, duplex-splicer, inertial-cage, and bus-breakout frames written to res://captures"
	)
	quit(0)


func _new_game():
	var packed: PackedScene = load("res://main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	return game


func _capture_boot() -> void:
	var game = _new_game()
	await _settle()
	_save_viewport("01-boot.png")
	game.free()
	await process_frame


func _capture_active() -> void:
	var game = _new_game()
	game.start_shift()
	game.take_evidence("telemetry")
	game.take_evidence("camera")
	game.take_evidence("provenance")
	await _settle()
	_save_viewport("02-active-investigation.png")
	game.free()
	await process_frame


func _capture_brace_rig() -> void:
	var game = _new_game()
	game.start_shift()
	game.take_evidence("telemetry")
	game.take_evidence("camera")
	game.take_evidence("mina")
	game.take_evidence("provenance")
	game.seal_brace_button.emit_signal("pressed")
	game.brace_port_button.emit_signal("pressed")
	await _settle()
	_save_viewport("02c-brace-rig.png")
	game.free()
	await process_frame


func _capture_braced_seal() -> void:
	var game = _new_game()
	game.start_shift()
	game.take_evidence("telemetry")
	game.take_evidence("camera")
	game.take_evidence("mina")
	game.take_evidence("provenance")
	_complete_brace_rig(game)
	await _settle()
	_save_viewport("02c-braced-inner-seal.png")
	game.free()
	await process_frame


func _capture_order_review() -> void:
	var game = _new_game()
	game.start_shift()
	game.take_evidence("camera")
	game.take_evidence("provenance")
	game.toggle_order_review()
	await _settle()
	_save_viewport("02b-work-order-review.png")
	game.free()
	await process_frame


func _capture_purge() -> void:
	var game = _new_game()
	game.start_shift()
	game.take_evidence("mina")
	game.commit_choice("purge")
	await _settle()
	_save_viewport("03-purge-outcome.png")
	game.free()
	await process_frame


func _capture_next_order() -> void:
	var game = _new_game()
	game.start_shift()
	game.take_evidence("camera")
	game.take_evidence("provenance")
	game.commit_choice("isolate")
	game.open_next_order()
	await _settle()
	_save_viewport("04-follow-up-decision.png")
	game.free()
	await process_frame


func _capture_campaign_summary() -> void:
	var game = _new_game()
	game.start_shift()
	game.take_evidence("mina")
	game.commit_choice("purge")
	game.open_next_order()
	game.resolve_followup("sterilize")
	await _settle()
	_save_viewport("05-campaign-summary.png")
	game.free()
	await process_frame


func _capture_wo013_repair() -> void:
	var game = _new_game()
	game.start_shift()
	game.take_evidence("mina")
	game.commit_choice("purge")
	game.open_next_order()
	game.resolve_followup("sterilize")
	game.open_next_order()
	game.trace_wo013_signal()
	await _settle()
	_save_viewport("06-wo013-repair.png")
	game.free()
	await process_frame


func _capture_campaign_ledger() -> void:
	var game = _new_game()
	game.start_shift()
	game.take_evidence("telemetry")
	game.take_evidence("camera")
	game.take_evidence("mina")
	game.take_evidence("provenance")
	_complete_brace_rig(game)
	game.commit_choice("isolate")
	game.open_next_order()
	game.resolve_followup("quarantine")
	game.open_next_order()
	game.resolve_wo013("handoff")
	await _settle()
	_save_viewport("07-campaign-ledger.png")
	game.free()
	await process_frame


func _capture_archive_packet() -> void:
	var game = _new_game()
	game.start_shift()
	game.take_evidence("telemetry")
	game.take_evidence("camera")
	game.take_evidence("mina")
	game.take_evidence("provenance")
	_complete_brace_rig(game)
	game.commit_choice("isolate")
	game.open_next_order()
	game.resolve_followup("quarantine")
	game.open_next_order()
	game.resolve_wo013("handoff")
	game.open_archive_packet()
	await _settle()
	_save_viewport("08-sealed-audit-packet.png")
	game.free()
	await process_frame


func _capture_watch_roster_day_two() -> void:
	var game = _new_game()
	_enter_watch(game)
	game.resolve_watch("roster")
	game.resolve_watch("roster")
	await _settle()
	_save_viewport("09-watch-roster-day-2.png")
	game.free()
	await process_frame


func _capture_watch_summary() -> void:
	var game = _new_game()
	_enter_watch(game)
	game.resolve_watch("roster")
	game.resolve_watch("roster")
	game.resolve_watch("manual")
	await _settle()
	_save_viewport("10-watch-summary-ledger.png")
	game.free()
	await process_frame


func _capture_maintenance_active() -> void:
	var game = _new_game()
	_enter_maintenance(game)
	await _settle()
	_save_viewport("11-maintenance-active.png")
	game.free()
	await process_frame


func _capture_maintenance_failure() -> void:
	var game = _new_game()
	_enter_maintenance(game)
	_apply_maintenance_pair(game, "reserve", "carrier")
	await _settle()
	_save_viewport("12-maintenance-contained-failure.png")
	game.free()
	await process_frame


func _capture_maintenance_ledger() -> void:
	var game = _new_game()
	_enter_maintenance(game)
	_apply_maintenance_pair(game, "loop", "reserve")
	_apply_maintenance_pair(game, "loop", "reserve")
	_apply_maintenance_pair(game, "loop", "reserve")
	await _settle()
	_save_viewport("13-maintenance-ledger.png")
	game.free()
	await process_frame


func _capture_service_active() -> void:
	var game = _new_game()
	_enter_service_run(game)
	await _settle()
	_save_viewport("14-service-run-active.png")
	game.free()
	await process_frame


func _capture_service_carrier_failure() -> void:
	var game = _new_game()
	_enter_service_run(game)
	for system in ["loop", "reserve", "loop", "reserve"]:
		game.select_service_system(system)
		game.apply_service_action()
	await _settle()
	_save_viewport("15-service-carrier-silence.png")
	game.free()
	await process_frame


func _capture_service_ledger() -> void:
	var game = _new_game()
	_enter_service_run(game)
	for system in ["loop", "reserve", "carrier", "loop", "reserve", "carrier", "loop", "reserve", "carrier"]:
		game.select_service_system(system)
		game.apply_service_action()
	await _settle()
	_save_viewport("16-service-ledger.png")
	game.free()
	await process_frame


func _capture_walkback_active() -> void:
	var game = _new_game()
	_enter_walkback(game)
	await _settle()
	_save_viewport("17-walkback-active.png")
	game.free()
	await process_frame


func _capture_walkback_mid_route() -> void:
	var game = _new_game()
	_enter_walkback(game)
	game.move_walkback(0)
	game.apply_walkback_action()
	game.move_walkback(1)
	game.apply_walkback_action()
	await _settle()
	_save_viewport("18-walkback-mid-route.png")
	game.free()
	await process_frame


func _capture_walkback_three_witness_ledger() -> void:
	var game = _new_game()
	_enter_walkback(game)
	for index in [0, 1, 2, 1, 1]:
		game.move_walkback(index)
		if game.walkback_room in ["med", "aux", "bridge"] and game.walkback_room not in game.walkback_witnesses:
			game.apply_walkback_action()
	game.apply_walkback_action()
	await _settle()
	_save_viewport("19-walkback-three-witness-ledger.png")
	game.free()
	await process_frame


func _capture_splicer_active() -> void:
	var game = _new_game()
	_enter_splicer(game)
	await _settle()
	_save_viewport("20-splicer-active.png")
	game.free()
	await process_frame


func _capture_splicer_misfeed() -> void:
	var game = _new_game()
	_enter_splicer(game)
	game.advance_splice_feed("tether")
	game.advance_splice_feed("tether")
	await _settle()
	_save_viewport("21-splicer-misfeed.png")
	game.free()
	await process_frame


func _capture_splicer_ledger() -> void:
	var game = _new_game()
	_enter_splicer(game)
	for feed in ["tether", "core", "badge", "tether", "badge", "core"]:
		game.advance_splice_feed(feed)
	game.stamp_splice()
	await _settle()
	_save_viewport("22-splicer-ledger.png")
	game.free()
	await process_frame


func _capture_gyro_active() -> void:
	var game = _new_game()
	_enter_gyro_cage(game)
	await _settle()
	_save_viewport("23-gyro-active.png")
	game.free()
	await process_frame


func _capture_gyro_index_rejected() -> void:
	var game = _new_game()
	_enter_gyro_cage(game)
	game.gyro_settle = 2
	game.latch_gyro()
	await _settle()
	_save_viewport("24-gyro-index-rejected.png")
	game.free()
	await process_frame


func _capture_gyro_ledger() -> void:
	var game = _new_game()
	_enter_gyro_cage(game)
	game.rotate_gyro(1)
	game.rotate_gyro(1)
	game.latch_gyro()
	game.rotate_gyro(-1)
	game.latch_gyro()
	game.rotate_gyro(1)
	game.rotate_gyro(1)
	game.rotate_gyro(1)
	game.latch_gyro()
	game.rotate_gyro(1)
	game.latch_gyro()
	await _settle()
	if game.outcome_ledger.get_visible_line_count() < game.outcome_ledger.get_line_count():
		push_error(
			"M13 ledger clips %d of %d rendered lines"
			% [
				game.outcome_ledger.get_line_count()
				- game.outcome_ledger.get_visible_line_count(),
				game.outcome_ledger.get_line_count(),
			]
		)
		quit(1)
		return
	_save_viewport("25-gyro-ledger.png")
	game.free()
	await process_frame


func _capture_bus_active() -> void:
	var game = _new_game()
	_enter_bus_breakout(game)
	await _settle()
	_save_viewport("26-bus-active.png")
	game.free()
	await process_frame


func _capture_bus_arc_rejected() -> void:
	var game = _new_game()
	_enter_bus_breakout(game)
	game.toggle_bus_bar(0)
	game.inject_bus_proof()
	game.inject_bus_proof()
	await _settle()
	_save_viewport("27-bus-arc-rejected.png")
	game.free()
	await process_frame


func _capture_bus_ledger() -> void:
	var game = _new_game()
	_enter_bus_breakout(game)
	game.toggle_bus_bar(0)
	game.inject_bus_proof()
	game.toggle_bus_bar(2)
	game.inject_bus_proof()
	game.toggle_bus_bar(1)
	game.inject_bus_proof()
	await _settle()
	if game.outcome_ledger.get_visible_line_count() < game.outcome_ledger.get_line_count():
		push_error(
			"M14 ledger clips %d of %d rendered lines"
			% [
				game.outcome_ledger.get_line_count()
				- game.outcome_ledger.get_visible_line_count(),
				game.outcome_ledger.get_line_count(),
			]
		)
		quit(1)
		return
	_save_viewport("28-bus-ledger.png")
	game.free()
	await process_frame


func _enter_watch(game) -> void:
	game.start_shift()
	game.take_evidence("camera")
	game.take_evidence("provenance")
	game.commit_choice("isolate")
	game.open_next_order()
	game.resolve_followup("quarantine")
	game.open_next_order()
	game.resolve_wo013("handoff")
	game.open_watch_roster()


func _enter_maintenance(game) -> void:
	_enter_watch(game)
	game.resolve_watch("manual")
	game.resolve_watch("manual")
	game.resolve_watch("manual")
	game.open_maintenance_rotation()


func _enter_service_run(game) -> void:
	_enter_maintenance(game)
	_apply_maintenance_pair(game, "loop", "reserve")
	_apply_maintenance_pair(game, "loop", "reserve")
	_apply_maintenance_pair(game, "loop", "reserve")
	game.open_next_order()


func _enter_walkback(game) -> void:
	_enter_service_run(game)
	for system in ["loop", "reserve", "carrier", "loop", "reserve", "carrier", "loop", "reserve", "carrier"]:
		game.select_service_system(system)
		game.apply_service_action()
	game.open_next_order()


func _enter_splicer(game):
	_enter_walkback(game)
	for index in [0, 1, 2, 1, 1]:
		game.move_walkback(index)
		if game.walkback_room in ["med", "aux", "bridge"] and game.walkback_room not in game.walkback_witnesses:
			game.apply_walkback_action()
	game.apply_walkback_action()
	game.open_next_order()
	return game


func _enter_gyro_cage(game):
	_enter_splicer(game)
	for feed in ["tether", "core", "badge", "tether", "badge", "core"]:
		game.advance_splice_feed(feed)
	game.stamp_splice()
	game.open_next_order()
	return game


func _enter_bus_breakout(game):
	_enter_gyro_cage(game)
	game.rotate_gyro(1)
	game.rotate_gyro(1)
	game.latch_gyro()
	game.rotate_gyro(-1)
	game.latch_gyro()
	game.rotate_gyro(1)
	game.rotate_gyro(1)
	game.rotate_gyro(1)
	game.latch_gyro()
	game.rotate_gyro(1)
	game.latch_gyro()
	game.open_bus_breakout()
	return game


func _apply_maintenance_pair(game, first: String, second: String) -> void:
	game.select_maintenance_system(first)
	game.apply_maintenance_stroke()
	game.select_maintenance_system(second)
	game.apply_maintenance_stroke()


func _complete_brace_rig(game) -> void:
	game.open_brace_rig()
	game.tension_brace_port()
	game.tension_brace_starboard()
	game.tension_brace_port()
	game.tension_brace_starboard()
	game.lock_brace_rig()


func _settle() -> void:
	await process_frame
	await process_frame
	await create_timer(0.08).timeout


func _save_viewport(filename: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path(CAPTURE_DIR.path_join(filename))
	var result := image.save_png(path)
	if result != OK:
		push_error("Could not save capture %s (error %d)" % [path, result])
		quit(1)
