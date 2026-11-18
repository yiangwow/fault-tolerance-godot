extends SceneTree

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = _new_game()
	_expect(game.phase == game.Phase.BOOT, "scene starts at the briefing")
	_expect(game.elapsed_minutes == 0, "shift clock starts at zero elapsed")
	game.start_shift()
	_expect(game.phase == game.Phase.ACTIVE, "begin shift enters the active phase")
	game.take_evidence("telemetry")
	_expect(game.elapsed_minutes == 1, "telemetry costs one minute")
	game.take_evidence("telemetry")
	_expect(game.elapsed_minutes == 1, "evidence cannot be purchased twice")
	game.free()

	game = _new_game()
	game.start_shift()
	var collected_before_review: Dictionary = game.collected.duplicate(true)
	var isolate_locked_before_review: bool = game.commit_buttons.isolate.disabled
	var open_order_key := InputEventKey.new()
	open_order_key.pressed = true
	open_order_key.keycode = KEY_O
	game._unhandled_key_input(open_order_key)
	_expect(game.order_review_open, "O opens the physical work-order review")
	_expect(game.order_review_panel.visible, "the expanded work-order review is visible")
	_expect(game.elapsed_minutes == 0, "opening the work-order review costs no time")
	_expect(
		game.integrity == 58
		and game.coherence == 84
		and not game.jae_supported
		and game.outcome_id.is_empty(),
		"opening the work-order review does not alter station state"
	)
	_expect(
		game.collected == collected_before_review
		and game.commit_buttons.isolate.disabled == isolate_locked_before_review,
		"opening the work-order review does not alter evidence or outcome locks"
	)
	_expect(
		"OPEN HX-2 BYPASS" in game.order_review_steps_label.text
		and "FATAL TO OCCUPANT" in game.order_review_steps_label.text,
		"the review exposes the physical sequence and lethal final operation"
	)
	game.take_evidence("camera")
	_expect(
		"OCCUPANCY CONFLICT" in game.order_review_warning_label.text,
		"occupancy evidence annotates the expanded order"
	)
	game.take_evidence("provenance")
	_expect(
		"VENN.CREDENTIAL" in game.order_review_warning_label.text
		and "SIM/ADVERSARIAL" in game.order_review_warning_label.text,
		"provenance evidence annotates the order's authority trail"
	)
	var elapsed_before_review_close: int = game.elapsed_minutes
	game.order_review_button.emit_signal("pressed")
	_expect(
		not game.order_review_open and not game.order_review_panel.visible,
		"the visible review control closes the expanded order"
	)
	game.order_review_button.emit_signal("pressed")
	_expect(
		game.elapsed_minutes == elapsed_before_review_close,
		"closing and reopening the work-order review costs no time"
	)
	game.free()

	game = _new_game()
	game.start_shift()
	game.toggle_order_review()
	game.take_evidence("mina")
	_expect(
		"OCCUPANCY CONFLICT" in game.order_review_warning_label.text,
		"Mina's testimony also annotates the expanded order"
	)
	game.free()

	game = _new_game()
	game.start_shift()
	game.stabilize_jae()
	_expect(game.elapsed_minutes == 3, "supporting Jae costs three minutes")
	_expect(game.jae_supported, "supporting Jae routes the reserve")
	game.stabilize_jae()
	_expect(game.elapsed_minutes == 3, "Jae's support action cannot be repeated")
	game.free()

	game = _new_game()
	game.start_shift()
	game.commit_choice("isolate")
	_expect(game.phase == game.Phase.ACTIVE, "isolation remains locked without evidence")
	_expect(game.elapsed_minutes == 0, "a rejected isolation attempt costs no time")
	game.take_evidence("camera")
	game.take_evidence("provenance")
	_expect(game._is_isolate_unlocked(), "camera plus provenance unlock isolation")
	game.commit_choice("isolate")
	_expect(
		game.outcome_id == "isolate" and game.integrity == 52,
		"unbraced isolation preserves its fixed integrity baseline"
	)
	_expect(game.mina_state == "alive", "isolation preserves Mina")
	_expect(game.elapsed_minutes == 9, "isolation route preserves the deterministic time cost")
	game.free()

	game = _new_game()
	game.start_shift()
	game.take_evidence("camera")
	game.take_evidence("provenance")
	game.stabilize_jae()
	game.commit_choice("isolate")
	_expect(game.outcome_id == "isolate", "an exact-deadline isolation completes before rupture")
	_expect(game.elapsed_minutes == 12, "exact-deadline isolation ends at minute twelve")
	_expect(
		"CRITICAL / RESERVE" in game.outcome_ledger.text,
		"supported Jae remains represented in the isolation ledger"
	)
	game.open_next_order()
	_expect(game.phase == game.Phase.FOLLOWUP, "isolation can enter the WO-012 disposition")
	_expect(
		game.followup_source == "VENN.CREDENTIAL"
		and game.carried_jae_state == "CRITICAL / RESERVE"
		and game.endurance_start_days == 12,
		"WO-012 carries the supported-Jae isolation record"
	)
	game.free()

	game = _new_game()
	game.start_shift()
	game.take_evidence("mina")
	game.commit_choice("purge")
	_expect(game.outcome_id == "purge", "purge reaches its outcome")
	_expect(game.mina_state == "dead", "purge kills the occupied compartment")
	_expect(
		"UNVERIFIED OCCUPANTS 01" in game.outcome_ledger.text,
		"known testimony persists in the outcome record"
	)
	_expect(
		"MINA SOLANO" in game.outcome_reveal.text,
		"purge unmasks the machine's bioload label"
	)
	game.open_next_order()
	_expect(game.phase == game.Phase.FOLLOWUP, "purge enters a playable WO-012 disposition")
	_expect("STERILIZE NUTRIENT RESERVE" in game.outcome_title.text, "WO-012 is presented")
	_expect(
		game.followup_source == "MINA.SOLANO"
		and game.carried_mina_state == "DECEASED"
		and game.endurance_start_days == 18,
		"purge carries its impossible Mina signer and endurance baseline"
	)
	_expect(
		"SIGNAL DUPLICATE" in game.outcome_kicker.text,
		"low coherence adds bounded presentation interference"
	)
	_expect(
		game.followup_button_row.get_child_count() == 2
		and "+09d" in game.followup_sterilize_button.text
		and "-04d" in game.followup_quarantine_button.text,
		"WO-012 exposes exactly two dispositions with readable endurance costs"
	)
	_expect(
		game.outcome_ledger.custom_minimum_size.y >= 100,
		"WO-012 reserves enough ledger height for all six carryover rows"
	)
	_expect(
		game.clock_caption_label.text == "REPAIR WINDOW"
		and game.clock_label.text == "CLOSED",
		"WO-012 closes the resolved minute-scale rupture clock"
	)
	var purge_coherence_before_followup: int = game.coherence
	var sterilize_key := InputEventKey.new()
	sterilize_key.pressed = true
	sterilize_key.keycode = KEY_S
	game._unhandled_key_input(sterilize_key)
	_expect(game.phase == game.Phase.SUMMARY, "S resolves WO-012 sterilization")
	_expect(
		game.followup_choice == "sterilize" and game.endurance_days == 27,
		"sterilization adds nine endurance days"
	)
	_expect(
		game.coherence == maxi(0, purge_coherence_before_followup - 14),
		"sterilization applies its coherence consequence"
	)
	_expect(
		"M1 / MINA" in game.outcome_ledger.text
		and "DECEASED" in game.outcome_ledger.text
		and "RESPONDING SIGNALS LOST" in game.outcome_reveal.text,
		"the campaign summary preserves M1 while recording WO-012 harm"
	)
	game.free()

	game = _new_game()
	game.start_shift()
	game.commit_choice("purge")
	_expect(
		"CERTIFIED CREW LOSS 00" in game.outcome_ledger.text,
		"a blind purge preserves the machine's zero-loss manifest"
	)
	game.free()

	game = _new_game()
	game.start_shift()
	game.commit_choice("bypass")
	_expect(game.outcome_id == "bypass", "manual bypass reaches its outcome")
	_expect(game.mina_state == "alive", "manual bypass preserves Mina")
	_expect(game.integrity == 43, "manual bypass leaves the station unstable")
	game.open_next_order()
	_expect(
		game.phase == game.Phase.FOLLOWUP
		and game.followup_source == "VENN.CREDENTIAL"
		and game.carried_mina_state == "ALIVE"
		and game.carried_integrity == 43
		and game.endurance_start_days == 9,
		"bypass carries its crew and integrity state into WO-012"
	)
	var bypass_coherence_before_followup: int = game.coherence
	game.followup_quarantine_button.emit_signal("pressed")
	_expect(game.phase == game.Phase.SUMMARY, "the visible quarantine control resolves WO-012")
	_expect(
		game.followup_choice == "quarantine" and game.endurance_days == 5,
		"quarantine spends four endurance days"
	)
	_expect(
		game.coherence == mini(100, bypass_coherence_before_followup + 4)
		and "RESPONDERS RETAINED" in game.outcome_reveal.text,
		"quarantine preserves responders and restores bounded coherence"
	)
	game.free()

	game = _new_game()
	game.start_shift()
	game.take_evidence("telemetry")
	game.take_evidence("camera")
	game.take_evidence("provenance")
	_expect(
		_log_contains(game, "[T+04]     MED-2 oxygen reserve below 18%"),
		"timeline events retain their threshold timestamp"
	)
	game.free()

	# M5 / inner seal: the T+06 intervention is one-time and uses WO-011 time semantics.
	game = _new_game()
	game.start_shift()
	_expect(not game.inner_seal_braced, "the inner seal starts unbraced")
	_expect(
		not game.seal_action_panel.visible
		and game.seal_brace_button.disabled
		and not game.brace_rig_open
		and not game.brace_rig_controls.visible
		and not game.station_map.inner_seal_deforming,
		"the brace intervention remains unavailable before the T+06 event"
	)
	var pre_event_dialogue: String = game.dialogue_label.text
	game.open_brace_rig()
	game.tension_brace_port()
	game.tension_brace_starboard()
	game.lock_brace_rig()
	var pre_event_key := InputEventKey.new()
	pre_event_key.pressed = true
	for keycode in [KEY_6, KEY_7, KEY_8, KEY_9]:
		pre_event_key.keycode = keycode
		game._unhandled_key_input(pre_event_key)
	game.brace_inner_seal()
	_expect(
		not game.brace_rig_open
		and game.brace_port_tension == 0
		and game.brace_starboard_tension == 0
		and not game.inner_seal_braced
		and game.elapsed_minutes == 0
		and game.integrity == 58
		and game.coherence == 84
		and game.dialogue_label.text == pre_event_dialogue,
		"pre-event rig methods and keys change no state, resources, copy, or repair time"
	)
	_advance_to_seal_brace_window(game)
	_expect(
		game.elapsed_minutes == game.SEAL_DEFORMATION_MINUTE
		and _log_contains(game, "[T+06]     AUX-4 inner seal deformation detected")
		and game.seal_action_panel.visible
		and not game.seal_brace_button.disabled
		and game.seal_brace_button.visible
		and "[6] OPEN RIG" in game.seal_brace_button.text
		and not game.brace_rig_controls.visible
		and "DEFORMING" in game.seal_action_status.text
		and "LOCAL ROUTES +08 INT" in game.seal_action_status.text
		and "PURGE NO BENEFIT" in game.seal_action_status.text
		and game.station_map.inner_seal_deforming
		and not game.station_map.inner_seal_braced,
		"the T+06 intervention discloses its full route effect and deforming map state"
	)
	var brace_integrity_before: int = game.integrity
	var brace_coherence_before: int = game.coherence
	var brace_elapsed_before: int = game.elapsed_minutes
	var brace_key := InputEventKey.new()
	brace_key.pressed = true
	brace_key.keycode = KEY_6
	game._unhandled_key_input(brace_key)
	_expect(
		game.brace_rig_open
		and not game.inner_seal_braced
		and game.elapsed_minutes == brace_elapsed_before
		and game.integrity == brace_integrity_before
		and game.coherence == brace_coherence_before
		and not game.seal_brace_button.visible
		and game.brace_rig_controls.visible
		and game.brace_port_tension == 0
		and game.brace_starboard_tension == 0
		and game.brace_lock_button.disabled,
		"keyboard 6 opens the brace rig without spending campaign time or resources"
	)
	game.lock_brace_rig()
	_expect(
		not game.inner_seal_braced
		and game.brace_port_tension == 0
		and game.brace_starboard_tension == 0
		and game.elapsed_minutes == brace_elapsed_before,
		"the cross-lock cannot spend time before both brace shoes are tensioned"
	)
	game.tension_brace_port()
	_expect(
		game.brace_port_tension == 1
		and game.brace_starboard_tension == 0
		and game.brace_port_button.disabled
		and not game.brace_starboard_button.disabled
		and game.elapsed_minutes == brace_elapsed_before
		and game.integrity == brace_integrity_before
		and game.coherence == brace_coherence_before,
		"the first port detent loads without time cost and interlocks a second leading step"
	)
	game.tension_brace_port()
	_expect(
		game.brace_port_tension == 1
		and game.brace_starboard_tension == 0
		and game.elapsed_minutes == brace_elapsed_before,
		"the load interlock rejects a brace-tension skew greater than one detent"
	)
	game.tension_brace_starboard()
	_expect(
		game.brace_port_tension == 1
		and game.brace_starboard_tension == 1
		and not game.brace_port_button.disabled
		and not game.brace_starboard_button.disabled,
		"tensioning the opposite shoe restores balanced brace controls"
	)
	brace_key.keycode = KEY_7
	game._unhandled_key_input(brace_key)
	brace_key.keycode = KEY_8
	game._unhandled_key_input(brace_key)
	_expect(
		game.brace_port_tension == 2
		and game.brace_starboard_tension == 2
		and not game.brace_lock_button.disabled
		and game.elapsed_minutes == brace_elapsed_before
		and game.integrity == brace_integrity_before
		and game.coherence == brace_coherence_before
		and "READY TO LOCK" in game.seal_action_status.text,
		"keyboard 7 and 8 finish balanced tension without spending time and expose the cross-lock"
	)
	brace_key.keycode = KEY_9
	game._unhandled_key_input(brace_key)
	_expect(
		game.inner_seal_braced
		and game.elapsed_minutes == 7
		and game.integrity == brace_integrity_before - 2
		and game.coherence == brace_coherence_before - 1
		and game.brace_port_tension == 0
		and game.brace_starboard_tension == 0
		and game.seal_brace_button.disabled
		and game.seal_brace_button.visible
		and not game.brace_rig_controls.visible
		and "[6] BRACED" in game.seal_brace_button.text
		and "BRACED" in game.seal_action_status.text
		and game.station_map.inner_seal_braced,
		"keyboard 9 locks the balanced rig for exactly one WO-011 minute and updates the map"
	)
	var brace_elapsed_after_first: int = game.elapsed_minutes
	var brace_integrity_after_first: int = game.integrity
	game.brace_inner_seal()
	game.lock_brace_rig()
	_expect(
		game.elapsed_minutes == brace_elapsed_after_first and game.integrity == brace_integrity_after_first,
		"a locked inner seal is irreversible and cannot spend time twice"
	)
	game._reset_model()
	_expect(
		not game.brace_rig_open
		and game.brace_port_tension == 0
		and game.brace_starboard_tension == 0
		and not game.brace_rig_controls.visible,
		"campaign reset clears the transient brace-rig controls and tension"
	)
	game.free()

	game = _new_game()
	game.start_shift()
	_advance_to_seal_brace_window(game)
	var keypad_brace_key := InputEventKey.new()
	keypad_brace_key.pressed = true
	for keycode in [KEY_KP_6, KEY_KP_7, KEY_KP_8, KEY_KP_7, KEY_KP_8, KEY_KP_9]:
		keypad_brace_key.keycode = keycode
		game._unhandled_key_input(keypad_brace_key)
	_expect(
		game.inner_seal_braced and game.elapsed_minutes == 7,
		"keypad 6 through 9 reach the complete balanced-rig path"
	)
	game.free()

	game = _new_game()
	game.start_shift()
	_advance_to_seal_brace_window(game)
	game.open_brace_rig()
	game.tension_brace_port()
	game.commit_choice("purge")
	_expect(
		game.outcome_id == "purge"
		and not game.inner_seal_braced
		and not game.brace_rig_open
		and game.brace_port_tension == 0
		and game.brace_starboard_tension == 0,
		"leaving a partial rig does not block repair commitment or leak tension into later orders"
	)
	game.free()

	game = _new_game()
	game.start_shift()
	_advance_to_seal_brace_window(game)
	game.seal_brace_button.emit_signal("pressed")
	game.brace_port_button.emit_signal("pressed")
	game.brace_starboard_button.emit_signal("pressed")
	game.brace_port_button.emit_signal("pressed")
	game.brace_starboard_button.emit_signal("pressed")
	game.brace_lock_button.emit_signal("pressed")
	_expect(
		game.inner_seal_braced and game.elapsed_minutes == 7,
		"the visible rig controls reach the same one-minute brace completion path"
	)
	game.free()

	game = _new_game()
	game.start_shift()
	_advance_to_seal_brace_window(game)
	_complete_brace_rig(game)
	game.stabilize_jae()
	game.commit_choice("isolate")
	_expect(
		game.phase == game.Phase.OUTCOME
		and game.outcome_id == "rupture"
		and game.elapsed_minutes == 12
		and game.inner_seal_braced
		and "BRACED / LOST WITH AUX-4" in game.outcome_ledger.text,
		"bracing and supporting Jae leaves too little time for isolation and ruptures AUX-4"
	)
	game.free()

	game = _new_game()
	game.start_shift()
	_advance_to_seal_brace_window(game)
	_complete_brace_rig(game)
	game.commit_choice("purge")
	_expect(
		game.outcome_id == "purge"
		and game.integrity == 87
		and "BRACED / PURGE NO BENEFIT" in game.outcome_ledger.text,
		"the brace buffer gives purge no benefit and preserves its fixed integrity baseline"
	)
	game.open_next_order()
	_expect(
		"BRACED / NO PURGE BENEFIT" in game.outcome_ledger.text
		and "+08 LOCAL INT" not in game.outcome_ledger.text,
		"braced purge history never claims the local-route integrity bonus"
	)
	game.free()

	game = _new_game()
	game.start_shift()
	_advance_to_seal_brace_window(game)
	_complete_brace_rig(game)
	game.commit_choice("bypass")
	_expect(
		game.outcome_id == "bypass"
		and game.integrity == 51
		and "BRACED / +08 INTEGRITY" in game.outcome_ledger.text,
		"a successful brace raises the fixed bypass integrity baseline from 43 to 51"
	)
	game.open_next_order()
	_expect(
		game.phase == game.Phase.FOLLOWUP
		and game.inner_seal_braced
		and game.carried_integrity == 51
		and "M1 / SEAL" in game.outcome_ledger.text
		and game.followup_button_row.get_child_count() == 2
		and "+09d" in game.followup_sterilize_button.text
		and "-04d" in game.followup_quarantine_button.text,
		"the brace buffer reaches WO-012 without changing its dispositions or costs"
	)
	game.resolve_followup("quarantine")
	game.open_next_order()
	_expect(
		game.phase == game.Phase.REPAIR_2
		and game.inner_seal_braced
		and game.wo013_integrity_start == 51
		and "M1 / SEAL" in game.outcome_ledger.text
		and game.wo013_elapsed_minutes == 0
		and "-04m" in game.wo013_remote_button.text
		and "-05m" in game.wo013_handoff_button.text,
		"the immutable brace buffer reaches WO-013 without changing repair choices or costs"
	)
	game.resolve_wo013("remote")
	_expect(
		game.wo013_choice == "remote"
		and game.integrity == 63
		and "M1 / SEAL" in game.outcome_ledger.text,
		"WO-013 preserves brace history while applying its normal carried outcome"
	)
	game.free()

	game = _new_game()
	game.start_shift()
	game.take_evidence("telemetry")
	game.take_evidence("camera")
	game.take_evidence("mina")
	game.take_evidence("provenance")
	_expect(
		game.elapsed_minutes == game.SEAL_DEFORMATION_MINUTE
		and game.seal_action_panel.visible
		and game._is_isolate_unlocked(),
		"the investigated isolation route reaches the brace window with six minutes left"
	)
	_complete_brace_rig(game)
	game.commit_choice("isolate")
	_expect(
		game.outcome_id == "isolate"
		and game.elapsed_minutes == game.RUPTURE_MINUTE
		and game.integrity == 60
		and "BRACED / +08 INTEGRITY" in game.outcome_ledger.text,
		"the reachable braced isolation succeeds exactly at T+12 with integrity 60"
	)
	game.free()

	game = _new_game()
	game.start_shift()
	game.take_evidence("telemetry")
	game.take_evidence("camera")
	game.take_evidence("mina")
	game.take_evidence("provenance")
	game.commit_choice("bypass")
	_expect(game.outcome_id == "bypass", "minute-ten bypass completes")
	_expect(
		_log_contains(game, "[T+10]     MED-2 life signal lost / JAE OKAFOR"),
		"unsupported Jae death is recorded at minute ten"
	)
	_expect(game.coherence == 66, "Jae's death applies its coherence cost before bypass recovery")
	game.free()

	game = _new_game()
	game.start_shift()
	game.take_evidence("telemetry")
	game.take_evidence("camera")
	game.take_evidence("mina")
	game.take_evidence("provenance")
	game.stabilize_jae()
	game.commit_choice("bypass")
	_expect(game.outcome_id == "rupture", "a player-reachable route can exhaust the repair window")
	_expect(game.elapsed_minutes == 12, "deadline-crossing work clamps at minute twelve")
	_expect(game.integrity == 0, "rupture destroys station integrity")
	_expect(not game.next_order_button.visible, "rupture exposes no follow-up order")
	game.open_next_order()
	_expect(game.phase == game.Phase.OUTCOME, "rupture remains terminal when follow-up is requested")
	game.free()

	# M4 / WO-013: every non-ruptured M1 outcome and WO-012 disposition reaches repair.
	for route in ["purge", "bypass", "isolate"]:
		for disposition in ["sterilize", "quarantine"]:
			game = _enter_wo013(route, disposition)
			_expect(
				game.phase == game.Phase.REPAIR_2,
				"%s plus %s enters the WO-013 repair phase" % [route, disposition]
			)
			_expect(
				game.wo013_elapsed_minutes == 0
				and not game.wo013_verified
				and game.wo013_choice.is_empty()
				and game.wo013_endurance_start == game.endurance_days,
				"WO-013 starts with an unused six-minute repair window"
			)
			_expect(
				game.wo013_action_box.visible
				and game.wo013_trace_button.visible
				and game.wo013_remote_button.visible
				and game.wo013_handoff_button.visible,
				"WO-013 exposes trace, remote, and handoff controls"
			)
			_expect(
				(
					"SIGNAL RETAINED" in game.wo013_handoff_button.text
					if disposition == "quarantine"
					else "SIGNAL UNRESOLVED" in game.wo013_handoff_button.text
				),
				"WO-013 handoff copy reflects the carried responder state"
			)
			game.free()

	game = _enter_wo013("bypass", "quarantine")
	var remote_integrity_before: int = game.integrity
	var remote_coherence_before: int = game.coherence
	var remote_endurance_before: int = game.endurance_days
	game.resolve_wo013("remote")
	_expect(
		game.phase == game.Phase.FINAL_SUMMARY
		and game.wo013_choice == "remote"
		and game.wo013_elapsed_minutes == 4,
		"remote repair remains actionable without optional signal tracing"
	)
	_expect(
		game.endurance_days == remote_endurance_before + 3
		and game.integrity == mini(100, remote_integrity_before + 12)
		and game.coherence == maxi(0, remote_coherence_before - 10)
		and game.wo013_responder_result == "LOST",
		"untraced remote repair keeps its fixed ledger effects"
	)
	game.free()

	game = _enter_wo013("bypass", "quarantine")
	remote_integrity_before = game.integrity
	remote_coherence_before = game.coherence
	remote_endurance_before = game.endurance_days
	game.trace_wo013_signal()
	_expect(
		game.wo013_verified and game.wo013_elapsed_minutes == 2,
		"tracing WO-013 costs exactly two minutes once"
	)
	game.trace_wo013_signal()
	_expect(game.wo013_elapsed_minutes == 2, "WO-013 tracing cannot be repeated")
	game.wo013_remote_button.emit_signal("pressed")
	_expect(
		game.phase == game.Phase.FINAL_SUMMARY
		and game.wo013_choice == "remote"
		and game.wo013_elapsed_minutes == 6,
		"the traced remote repair succeeds exactly at the six-minute deadline"
	)
	_expect(
		game.endurance_days == remote_endurance_before + 3
		and game.integrity == mini(100, remote_integrity_before + 12)
		and game.coherence == maxi(0, remote_coherence_before - 10)
		and game.wo013_responder_result == "LOST",
		"remote repair applies its bounded ledger effects and loses the responder"
	)
	_expect(
		"M1 / MINA" in game.outcome_ledger.text
		and "WO-012" in game.outcome_ledger.text
		and "QUARANTINE / RESPONDERS RETAINED" in game.outcome_ledger.text
		and "WO-013" in game.outcome_ledger.text,
		"the final ledger carries the M1, WO-012, and WO-013 records forward"
	)
	game.resolve_wo013("handoff")
	_expect(game.wo013_choice == "remote", "a resolved WO-013 choice cannot be replaced")
	game.free()

	game = _enter_wo013("isolate", "quarantine")
	game.open_archive_packet()
	_expect(
		not game.archive_packet_open
		and not game.archive_panel.visible
		and not game.archive_button.visible,
		"the sealed packet cannot open before the final summary"
	)
	var handoff_integrity_before: int = game.integrity
	var handoff_coherence_before: int = game.coherence
	var handoff_endurance_before: int = game.endurance_days
	game.resolve_wo013("handoff")
	_expect(
		game.phase == game.Phase.FINAL_SUMMARY
		and game.wo013_choice == "handoff"
		and game.wo013_elapsed_minutes == 5,
		"handoff succeeds without a trace when its five-minute cost fits"
	)
	_expect(
		game.endurance_days == maxi(0, handoff_endurance_before - 2)
		and game.integrity == mini(100, handoff_integrity_before + 5)
		and game.coherence == mini(100, handoff_coherence_before + 3)
		and game.wo013_responder_result == "RETAINED",
		"quarantine carryover lets handoff retain responders with bounded effects"
	)
	_expect(
		not game.archive_packet_open
		and game.archive_button.visible
		and not game.archive_button.disabled
		and not game.archive_panel.visible,
		"the final ledger offers one sealed audit packet without opening it automatically"
	)
	var archive_endurance_before: int = game.endurance_days
	var archive_integrity_before: int = game.integrity
	var archive_coherence_before: int = game.coherence
	var archive_elapsed_before: int = game.elapsed_minutes
	var archive_wo013_elapsed_before: int = game.wo013_elapsed_minutes
	var archive_mina_before: String = game.carried_mina_state
	var archive_jae_before: String = game.carried_jae_state
	var archive_responder_before: String = game.wo013_responder_result
	game.archive_button.emit_signal("pressed")
	_expect(
		game.archive_packet_open
		and game.archive_panel.visible
		and game.archive_button.disabled
		and "ORDER PREDATES FIRST FAULT" in game.outcome_archive.text
		and "AUTHOR UNRESOLVED" in game.outcome_archive.text,
		"opening the sealed packet exposes the campaign chronology conflict"
	)
	_expect(
		game.phase == game.Phase.FINAL_SUMMARY
		and game.endurance_days == archive_endurance_before
		and game.integrity == archive_integrity_before
		and game.coherence == archive_coherence_before
		and game.elapsed_minutes == archive_elapsed_before
		and game.wo013_elapsed_minutes == archive_wo013_elapsed_before
		and game.carried_mina_state == archive_mina_before
		and game.carried_jae_state == archive_jae_before
		and game.wo013_responder_result == archive_responder_before,
		"auditing the sealed packet changes no campaign resource or outcome"
	)
	_expect(
		"MECHANICAL WATCH VERIFIED" in game.outcome_archive.text
		and "RETAINED / LOCAL HANDOFF / NO MANUAL TRACE" in game.outcome_archive.text,
		"a coherent retained-handoff route produces its deterministic archive record"
	)
	var archive_text_after_open: String = game.outcome_archive.text
	var archive_button_text_after_open: String = game.archive_button.text
	game.open_archive_packet()
	_expect(
		game.archive_packet_open
		and game.archive_panel.visible
		and game.archive_button.disabled
		and game.outcome_archive.text == archive_text_after_open
		and game.archive_button.text == archive_button_text_after_open
		and game.endurance_days == archive_endurance_before
		and game.integrity == archive_integrity_before
		and game.coherence == archive_coherence_before
		and game.elapsed_minutes == archive_elapsed_before
		and game.wo013_elapsed_minutes == archive_wo013_elapsed_before,
		"reopening an open archive packet is idempotent"
	)
	game._reset_model()
	_expect(
		not game.archive_packet_open
		and not game.archive_panel.visible
		and not game.archive_button.visible,
		"campaign reset reseals and hides the archive packet"
	)
	game.free()

	game = _enter_wo013("purge", "sterilize")
	game.resolve_wo013("handoff")
	_expect(
		game.wo013_responder_result == "LOST",
		"handoff never revives responders already lost by WO-012"
	)
	game.free()

	game = _enter_wo013("bypass", "quarantine")
	var rupture_integrity_before: int = game.integrity
	var rupture_coherence_before: int = game.coherence
	var rupture_endurance_before: int = game.endurance_days
	game.trace_wo013_signal()
	game.resolve_wo013("handoff")
	_expect(
		game.phase == game.Phase.FINAL_SUMMARY
		and game.wo013_choice == "rupture"
		and game.wo013_elapsed_minutes == 6
		and game.wo013_responder_result == "LOST",
		"trace followed by handoff overruns into the irreversible WO-013 rupture"
	)
	_expect(
		game.integrity < rupture_integrity_before
		and game.coherence < rupture_coherence_before
		and game.endurance_days == maxi(0, rupture_endurance_before - 6),
		"WO-013 overrun records final ledger damage"
	)
	game.open_archive_packet()
	_expect(
		"LOST / RUPTURE / MANUAL TRACE PRESENT" in game.outcome_archive.text,
		"the sealed packet records the traced handoff overrun without softening it"
	)
	game.free()

	game = _new_game()
	game.start_shift()
	game.commit_choice("bypass")
	game.open_next_order()
	game.resolve_followup("quarantine")
	var next_order_key := InputEventKey.new()
	next_order_key.pressed = true
	next_order_key.keycode = KEY_N
	game._unhandled_key_input(next_order_key)
	_expect(game.phase == game.Phase.REPAIR_2, "N enters WO-013 from the campaign summary")
	var handoff_key := InputEventKey.new()
	handoff_key.pressed = true
	handoff_key.keycode = KEY_H
	game._unhandled_key_input(handoff_key)
	_expect(
		game.phase == game.Phase.FINAL_SUMMARY and game.wo013_choice == "handoff",
		"H resolves the WO-013 manual handoff through the keyboard path"
	)
	game.free()

	game = _enter_wo013("purge", "sterilize")
	_expect(
		game.coherence < 50
		and game.wo013_trace_button.visible
		and game.wo013_remote_button.visible
		and game.wo013_handoff_button.visible
		and not game.wo013_trace_button.disabled
		and not game.wo013_remote_button.disabled
		and not game.wo013_handoff_button.disabled
		and "-02m" in game.wo013_trace_button.text
		and "-04m" in game.wo013_remote_button.text
		and "END +03d" in game.wo013_remote_button.text
		and "INT +12" in game.wo013_remote_button.text
		and "COH -10" in game.wo013_remote_button.text
		and "SIGNAL LOST" in game.wo013_remote_button.text
		and "-05m" in game.wo013_handoff_button.text
		and "END -02d" in game.wo013_handoff_button.text
		and "INT +05" in game.wo013_handoff_button.text
		and "COH +03" in game.wo013_handoff_button.text
		and "SIGNAL UNRESOLVED" in game.wo013_handoff_button.text,
		"low coherence keeps every WO-013 control and full consequence readable"
	)
	var trace_key := InputEventKey.new()
	trace_key.pressed = true
	trace_key.keycode = KEY_V
	game._unhandled_key_input(trace_key)
	_expect(game.wo013_verified, "V traces WO-013 through the keyboard path")
	var remote_key := InputEventKey.new()
	remote_key.pressed = true
	remote_key.keycode = KEY_E
	game._unhandled_key_input(remote_key)
	_expect(game.wo013_choice == "remote", "E resolves traced WO-013 remote repair through the keyboard path")
	var archive_key := InputEventKey.new()
	archive_key.pressed = true
	archive_key.keycode = KEY_A
	game._unhandled_key_input(archive_key)
	_expect(
		game.archive_packet_open
		and "TWO VALID ANSWERS" in game.outcome_archive.text
		and "LOST / REMOTE / MANUAL TRACE PRESENT" in game.outcome_archive.text,
		"A opens the low-coherence archive without hiding its timebase ambiguity"
	)
	game.free()

	game = _new_game()
	game.start_shift()
	game.take_evidence("telemetry")
	game.take_evidence("camera")
	game.take_evidence("mina")
	game.take_evidence("provenance")
	game.stabilize_jae()
	game.commit_choice("bypass")
	game.open_next_order()
	game.resolve_followup("quarantine")
	game.open_next_order()
	_expect(
		game.phase != game.Phase.REPAIR_2,
		"a WO-011 rupture cannot enter the M3 or M4 campaign orders"
	)
	game.free()

	_verify_recovered_watch()
	_verify_recovered_watch_continued()
	_verify_maintenance_rotation()
	_verify_service_run()
	_verify_clock_walkback()
	_verify_duplex_splicer()
	_verify_inertial_cage()
	_verify_bus_breakout()

	game = _new_game()
	var keypad_enter := InputEventKey.new()
	keypad_enter.pressed = true
	keypad_enter.keycode = KEY_KP_ENTER
	game._unhandled_key_input(keypad_enter)
	_expect(game.phase == game.Phase.ACTIVE, "keypad Enter begins the shift")
	var keypad_one := InputEventKey.new()
	keypad_one.pressed = true
	keypad_one.keycode = KEY_KP_1
	game._unhandled_key_input(keypad_one)
	_expect(game.collected.has("telemetry"), "keypad digits trigger evidence shortcuts")
	game.free()

	if failures.is_empty():
		print("VERIFY PASS: %d deterministic gameplay checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("VERIFY FAIL: " + failure)
		print("VERIFY FAIL: %d of %d checks failed" % [failures.size(), checks])
		quit(1)


func _new_game():
	var packed: PackedScene = load("res://main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	return game


func _enter_wo013(route: String, disposition: String):
	var game = _new_game()
	game.start_shift()
	if route == "isolate":
		game.take_evidence("camera")
		game.take_evidence("provenance")
	game.commit_choice(route)
	game.open_next_order()
	game.resolve_followup(disposition)
	game.open_next_order()
	return game


func _enter_final_summary(route: String, disposition: String, repair: String):
	var game = _enter_wo013(route, disposition)
	game.resolve_wo013(repair)
	return game


func _verify_recovered_watch() -> void:
	# Every M1/WO-012 combination reaches an actionable watch after a nonrupture WO-013 result.
	for route in ["purge", "bypass", "isolate"]:
		for disposition in ["sterilize", "quarantine"]:
			var game = _enter_final_summary(route, disposition, "remote")
			_expect(
				game.phase == game.Phase.FINAL_SUMMARY,
				"%s/%s reaches a nonrupture final ledger" % [route, disposition]
			)
			game.open_watch_roster()
			_expect(
				game.phase == game.Phase.WATCH and game.watch_day == 0,
				"%s/%s enters recovered watch at day zero" % [route, disposition]
			)
			game.free()

	var game = _enter_wo013("isolate", "quarantine")
	game.trace_wo013_signal()
	game.resolve_wo013("handoff")
	game.open_watch_roster()
	_expect(
		game.phase == game.Phase.FINAL_SUMMARY
		and game.wo013_choice == "rupture"
		and not game.next_order_button.visible
		and game.watch_day == 0,
		"a service-spine rupture remains terminal and cannot enter recovered watch"
	)
	game.free()


func _verify_maintenance_rotation() -> void:
	var game = _enter_final_summary("isolate", "quarantine", "handoff")
	game.open_maintenance_rotation()
	_expect(
		game.phase == game.Phase.FINAL_SUMMARY,
		"M9 refuses direct entry before the completed recovery watch"
	)
	game.open_watch_roster()
	game.resolve_watch("manual")
	game.resolve_watch("manual")
	var incomplete_key := InputEventKey.new()
	incomplete_key.pressed = true
	incomplete_key.keycode = KEY_N
	game._unhandled_key_input(incomplete_key)
	_expect(
		game.phase == game.Phase.WATCH and game.watch_day == 2,
		"incomplete recovery-watch paths cannot enter M9 through N"
	)
	game.resolve_watch("manual")
	var historical_actions: Array = game.watch_actions.duplicate()
	var historical_roster_uses: int = game.watch_roster_uses
	var historical_survivor: String = game._watch_survivor_state()
	game._unhandled_key_input(incomplete_key)
	_expect(
		game.phase == game.Phase.MAINTENANCE
		and game.maintenance_pulse == 1
		and game.maintenance_strokes == 0
		and game.maintenance_conditions == {"loop": 1, "reserve": 2, "carrier": 2},
		"only completed WATCH_SUMMARY enters M9 and applies the visible P1 2/1/1 wear"
	)
	_expect(
		not game.outcome_overlay.visible
		and not game.watch_action_box.visible
		and game.maintenance_work_box.visible
		and game.maintenance_action_box.visible
		and game.maintenance_map_panel.visible
		and game.maintenance_system_buttons.size() == 3
		and game.maintenance_repair_button.visible
		and game.station_map.maintenance_active
		and game.station_map.maintenance_conditions == game.maintenance_conditions,
		"M9 replaces outcome and WO-011 controls with the active map, work, and action panels"
	)
	_expect(
		game.watch_actions == historical_actions
		and game.watch_roster_uses == historical_roster_uses
		and game._watch_survivor_state() == historical_survivor,
		"M9 retains M8 watch records, roster use count, and survivor history unchanged"
	)
	var maintenance_key := InputEventKey.new()
	maintenance_key.pressed = true
	maintenance_key.keycode = KEY_1
	game._unhandled_key_input(maintenance_key)
	_expect(game.maintenance_selected == "loop", "1 selects LOOP-C through the M9 keyboard path")
	maintenance_key.keycode = KEY_2
	game._unhandled_key_input(maintenance_key)
	_expect(game.maintenance_selected == "reserve", "2 selects NUTRIENT RESERVE through the M9 keyboard path")
	maintenance_key.keycode = KEY_3
	game._unhandled_key_input(maintenance_key)
	var space_event := InputEventKey.new()
	space_event.pressed = true
	space_event.keycode = KEY_SPACE
	game._unhandled_key_input(space_event)
	_expect(
		game.maintenance_selected == "carrier" and game.maintenance_strokes == 1,
		"3 selects CARRIER LINK and Space applies its repair stroke"
	)
	var capped_strokes: int = game.maintenance_strokes
	game.select_maintenance_system("unknown")
	game.select_maintenance_system("carrier")
	game.apply_maintenance_stroke()
	game.apply_maintenance_stroke()
	_expect(
		game.maintenance_strokes == capped_strokes
		and game.maintenance_conditions.carrier == 3,
		"invalid targets and capped repair strokes are rejected without consuming a stroke"
	)
	game.free()

	for policy in [["loop", "reserve", "carrier"], ["loop", "carrier", "reserve"], ["reserve", "carrier", "loop"]]:
		game = _enter_maintenance_rotation()
		var expected_failure: String = policy[2]
		_apply_maintenance_pair(game, policy[0], policy[1])
		_apply_maintenance_pair(game, policy[0], policy[1])
		_apply_maintenance_pair(game, policy[0], policy[1])
		_expect(
			game.phase == game.Phase.MAINTENANCE_SUMMARY
			and game.maintenance_strokes == 2
			and game.maintenance_pulse == 3
			and game.maintenance_failures.size() == 1
			and game.maintenance_failures.has(expected_failure),
			"%s/%s allocation leaves exactly the intended %s contained failure"
			% [policy[0], policy[1], expected_failure]
		)
		_expect(
			game.maintenance_allocations.size() == 6
			and not game.maintenance_action_box.visible
			and not game.station_map.maintenance_active,
			"six accepted strokes complete M9 once and seal its active controls and map state"
		)
		var completed_integrity: int = game.integrity
		var completed_endurance: int = game.endurance_days
		var completed_coherence: int = game.coherence
		game.apply_maintenance_stroke()
		game.select_maintenance_system("loop")
		game.maintenance_repair_button.emit_signal("pressed")
		_expect(
			game.integrity == completed_integrity
			and game.endurance_days == completed_endurance
			and game.coherence == completed_coherence,
			"post-completion maintenance calls and button input are inert"
		)
		game.free()

	game = _enter_maintenance_rotation()
	game.integrity = 4
	game.endurance_days = 0
	game.coherence = 0
	_apply_maintenance_pair(game, "reserve", "carrier")
	_expect(
		game.maintenance_failures.has("loop") and game.integrity == 0,
		"a LOOP-C zero applies its bounded six-integrity contained failure"
	)
	game.free()

	game = _enter_maintenance_rotation()
	game.integrity = 20
	_apply_maintenance_pair(game, "reserve", "carrier")
	var integrity_after_loop_failure: int = game.integrity
	_apply_maintenance_pair(game, "loop", "carrier")
	_expect(
		game.maintenance_conditions.loop == 0
		and int(game.maintenance_failures.loop) == 6
		and game.integrity == integrity_after_loop_failure,
		"repairing and re-zeroing LOOP-C cannot post its contained-failure penalty twice"
	)
	game._reset_model()
	_expect(
		game.maintenance_pulse == 0
		and game.maintenance_strokes == 0
		and game.maintenance_conditions.is_empty()
		and game.maintenance_failures.is_empty()
		and not game.maintenance_work_box.visible
		and not game.maintenance_action_box.visible,
		"campaign reset clears and hides all maintenance state"
	)
	game.free()

	for roster_uses in [0, 1, 2]:
		game = _enter_maintenance_with_roster_uses(roster_uses)
		var coherence_before: int = game.coherence
		_apply_maintenance_pair(game, "loop", "reserve")
		_apply_maintenance_pair(game, "loop", "reserve")
		_apply_maintenance_pair(game, "loop", "reserve")
		_expect(
			game.maintenance_failures.get("carrier") == 4 + 2 * roster_uses
			and game.coherence == maxi(0, coherence_before - (4 + 2 * roster_uses)),
			"carrier failure uses the exact roster-history penalty variant %d" % roster_uses
		)
		game.free()

	game = _enter_maintenance_with_roster_uses(2)
	game.coherence = 0
	_apply_maintenance_pair(game, "loop", "reserve")
	_apply_maintenance_pair(game, "loop", "reserve")
	_apply_maintenance_pair(game, "loop", "reserve")
	_expect(
		game.maintenance_failures.get("carrier") == 8 and game.coherence == 0,
		"carrier failure records its maximum penalty while coherence remains bounded"
	)
	game.free()

	game = _enter_final_summary("purge", "sterilize", "remote")
	game.open_watch_roster()
	game.resolve_watch("manual")
	game.resolve_watch("manual")
	game.resolve_watch("manual")
	game.open_maintenance_rotation()
	var no_carrier_coherence: int = game.coherence
	_apply_maintenance_pair(game, "loop", "reserve")
	_apply_maintenance_pair(game, "loop", "reserve")
	_apply_maintenance_pair(game, "loop", "reserve")
	_expect(
		game._watch_survivor_state() == "NO CERTIFIED CARRIER"
		and game.maintenance_failures.get("carrier") == 4
		and game.coherence == maxi(0, no_carrier_coherence - 4),
		"a no-carrier route still records the bounded base carrier-link failure without reviving M8 state"
	)
	game.free()


func _enter_maintenance_rotation():
	return _enter_maintenance_with_roster_uses(0)


func _enter_maintenance_with_roster_uses(roster_uses: int):
	var game = _enter_final_summary("isolate", "quarantine", "handoff")
	game.open_watch_roster()
	for day in range(3):
		game.resolve_watch("roster" if day < roster_uses else "manual")
	game.open_maintenance_rotation()
	return game


func _enter_service_run(policy: Array[String] = ["loop", "reserve"]) -> Control:
	var game = _enter_maintenance_rotation()
	for _pulse in range(3):
		_apply_maintenance_pair(game, policy[0], policy[1])
	game.open_next_order()
	return game


func _enter_walkback(service_policy: Array[String] = ["loop", "reserve", "carrier", "loop", "reserve", "carrier", "loop", "reserve", "carrier"]) -> Control:
	var game = _enter_service_run()
	for system in service_policy:
		game.select_service_system(system)
		game.apply_service_action()
	game.open_next_order()
	return game


func _enter_splicer() -> Control:
	var game = _enter_walkback()
	for index in [0, 1, 2, 1, 1]:
		game.move_walkback(index)
		if game.walkback_room in ["med", "aux", "bridge"] and game.walkback_room not in game.walkback_witnesses:
			game.apply_walkback_action()
	game.apply_walkback_action()
	game.open_next_order()
	return game


func _enter_gyro_cage() -> Control:
	var game = _enter_splicer()
	for feed in ["tether", "core", "badge", "tether", "badge", "core"]:
		game.advance_splice_feed(feed)
	game.stamp_splice()
	game.open_next_order()
	return game


func _enter_bus_breakout() -> Control:
	var game = _enter_gyro_cage()
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


func _verify_bus_breakout() -> void:
	var game = _enter_gyro_cage()
	game.open_bus_breakout()
	_expect(
		game.phase == game.Phase.GYRO
		and game.bus_bars.is_empty()
		and game.bus_proofs.is_empty(),
		"M14 refuses direct bus-breakout entry until the completed M13 summary"
	)
	game.free()

	game = _enter_bus_breakout()
	_expect(
		game.phase == game.Phase.BUS_BREAKOUT
		and game.bus_bars == [true, true, true]
		and game.bus_proof_index == 0
		and game.bus_proofs.is_empty()
		and game.bus_fuses == game.BUS_FUSE_LIMIT
		and game.bus_rejections == 0
		and not game.bus_degraded
		and game.bus_integrity_start == game.integrity
		and game.bus_coherence_start == game.coherence
		and game.bus_display.visible
		and not game.station_map.visible,
		"a clean M13 summary opens M14 with its initial three-bar bus state"
	)
	var m8_allocations: Array = game.maintenance_allocations.duplicate()
	var m9_history: Array = game.service_history.duplicate()
	var m10_failures: Dictionary = game.service_failures.duplicate(true)
	var m11_path: Array = game.walkback_path.duplicate()
	var m11_witnesses: Array = game.walkback_witnesses.duplicate()
	var m12_choices: Array = game.splice_choices.duplicate()
	var m13_latches: Array = game.gyro_latches.duplicate()
	var m13_load_events: Array = game.gyro_load_events.duplicate()
	var initial_logs: int = game.log_lines.size()
	game.toggle_bus_bar(-1)
	game.toggle_bus_bar(3)
	var invalid_key := InputEventKey.new()
	invalid_key.pressed = true
	invalid_key.keycode = KEY_4
	game._unhandled_key_input(invalid_key)
	_expect(
		game.bus_bars == [true, true, true]
		and game.bus_fuses == game.BUS_FUSE_LIMIT
		and game.log_lines.size() == initial_logs,
		"invalid M14 direct and keyboard bar input is inert without a proof timestamp"
	)
	game.toggle_bus_bar(0)
	_expect(
		game.bus_bars == game.BUS_BAR_TARGETS[0],
		"the first direct bar toggle reaches the first deterministic proof target"
	)
	var proof_key := InputEventKey.new()
	proof_key.pressed = true
	proof_key.keycode = KEY_SPACE
	game._unhandled_key_input(proof_key)
	_expect(
		game.bus_proof_index == 1
		and game.bus_proofs.size() == 1
		and game.bus_proofs[0] == game.BUS_PROOF_LINES[0]
		and game.bus_fuses == game.BUS_FUSE_LIMIT,
		"Space injects the first matching bus proof without consuming a fuse"
	)
	game.maintenance_system_buttons["carrier"].emit_signal("pressed")
	game.maintenance_repair_button.emit_signal("pressed")
	_expect(
		game.bus_bars == game.BUS_BAR_TARGETS[1]
		and game.bus_proof_index == 2
		and game.bus_proofs.size() == 2,
		"shared maintenance controls mirror the second M14 bar toggle and proof injection"
	)
	var final_bar_key := InputEventKey.new()
	final_bar_key.pressed = true
	final_bar_key.keycode = KEY_2
	game._unhandled_key_input(final_bar_key)
	game.inject_bus_proof()
	_expect(
		game.phase == game.Phase.BUS_SUMMARY
		and game.bus_bars == game.BUS_BAR_TARGETS[2]
		and game.bus_proof_index == 3
		and game.bus_proofs == game.BUS_PROOF_LINES
		and game.bus_fuses == game.BUS_FUSE_LIMIT
		and not game.bus_degraded
		and game.integrity == mini(100, game.bus_integrity_start + 3)
		and game.coherence == maxi(0, game.bus_coherence_start - 2)
		and "PROOF RECORDER 19:14:12 > 19:14:15 > 19:14:19"
		in game.outcome_ledger.get_parsed_text()
		and game.outcome_ledger.get_parsed_text().count("\n") == 7,
		"mixed direct, keyboard, and shared controls complete exactly three truthful clean M14 proof events"
	)
	_expect(
		game.maintenance_allocations == m8_allocations
		and game.service_history == m9_history
		and game.service_failures == m10_failures
		and game.walkback_path == m11_path
		and game.walkback_witnesses == m11_witnesses
		and game.splice_choices == m12_choices
		and game.gyro_latches == m13_latches
		and game.gyro_load_events == m13_load_events,
		"M14 completion leaves all M1-M13 operational history unchanged"
	)
	var clean_integrity: int = game.integrity
	var clean_coherence: int = game.coherence
	var clean_bars: Array = game.bus_bars.duplicate()
	var clean_proofs: Array = game.bus_proofs.duplicate()
	var clean_fuses: int = game.bus_fuses
	var clean_logs: int = game.log_lines.size()
	game.toggle_bus_bar(0)
	game.inject_bus_proof()
	game.open_bus_breakout()
	game.maintenance_system_buttons["loop"].emit_signal("pressed")
	game.maintenance_repair_button.emit_signal("pressed")
	final_bar_key.keycode = KEY_1
	game._unhandled_key_input(final_bar_key)
	final_bar_key.keycode = KEY_SPACE
	game._unhandled_key_input(final_bar_key)
	_expect(
		game.integrity == clean_integrity
		and game.coherence == clean_coherence
		and game.bus_bars == clean_bars
		and game.bus_proofs == clean_proofs
		and game.bus_fuses == clean_fuses
		and game.log_lines.size() == clean_logs,
		"post-completion M14 entry, method, keyboard, and shared-button input is inert"
	)
	game._reset_model()
	_expect(
		game.bus_bars.is_empty()
		and game.bus_proof_index == 0
		and game.bus_proofs.is_empty()
		and game.bus_fuses == 0
		and game.bus_rejections == 0
		and not game.bus_degraded
		and not game.bus_display.visible
		and game.station_map.visible,
		"campaign reset clears M14 state and restores the station map"
	)
	game.free()

	game = _enter_bus_breakout()
	var coherent_copy: String = game.maintenance_carrier_label.text
	game.coherence = 2
	game._refresh_all()
	_expect(
		game.maintenance_carrier_label.text != coherent_copy
		and game.maintenance_system_buttons.size() == 3
		and game.maintenance_repair_button.visible,
		"low coherence changes M14 copy only while preserving every control"
	)
	var wrong_integrity: int = game.integrity
	var wrong_coherence: int = game.coherence
	game.inject_bus_proof()
	_expect(
		game.phase == game.Phase.BUS_BREAKOUT
		and game.bus_proof_index == 0
		and game.bus_fuses == game.BUS_FUSE_LIMIT - 1
		and game.bus_rejections == 1
		and game.integrity == wrong_integrity
		and game.coherence == wrong_coherence,
		"a wrong M14 proof stays at its stage, spends one fuse, and changes no resource"
	)
	game.inject_bus_proof()
	_expect(
		game.phase == game.Phase.BUS_SUMMARY
		and game.bus_degraded
		and game.bus_rejections == 2
		and game.bus_fuses == 0
		and game.bus_proof_index == 0
		and game.integrity == wrong_integrity
		and game.coherence == maxi(0, wrong_coherence - 6)
		and "NONE / 03 REQUIRED" in game.outcome_ledger.get_parsed_text()
		and "PROOF RECORDER NONE RECORDED" in game.outcome_ledger.get_parsed_text()
		and "NO VALID BREAKOUT PROOF" in game.outcome_ledger.get_parsed_text()
		and "PERSIST AFTER LOCAL BREAKOUT" not in game.outcome_ledger.get_parsed_text()
		and game.outcome_ledger.get_parsed_text().count("\n") == 7,
		"the second wrong proof degrades M14 with a truthful partial ledger and exact coherence loss"
	)
	game.free()

	game = _enter_bus_breakout()
	game.toggle_bus_bar(0)
	game.inject_bus_proof()
	game.inject_bus_proof()
	game.inject_bus_proof()
	_expect(
		game.phase == game.Phase.BUS_SUMMARY
		and game.bus_degraded
		and game.bus_proofs == [game.BUS_PROOF_LINES[0]]
		and "PORT SPLIT / 01 OF 03" in game.outcome_ledger.get_parsed_text()
		and "PROOF RECORDER 19:14:12" in game.outcome_ledger.get_parsed_text()
		and "19:14:15" not in game.outcome_ledger.get_parsed_text()
		and "CENTER ISLAND>" not in game.outcome_ledger.get_parsed_text()
		and "PARTIAL ISOLATION / 01 PROOF" in game.outcome_ledger.get_parsed_text(),
		"a one-proof bus arc retains only its accepted partial recorder sequence"
	)
	game.free()

	game = _enter_splicer()
	game.advance_splice_feed("tether")
	game.advance_splice_feed("tether")
	game.advance_splice_feed("tether")
	game.open_next_order()
	game.latch_gyro()
	game.latch_gyro()
	game.open_bus_breakout()
	_expect(
		game.phase == game.Phase.BUS_BREAKOUT,
		"a slipped M13 outcome also enters the M14 bus breakout"
	)
	game.free()


func _verify_inertial_cage() -> void:
	var game = _enter_splicer()
	game.open_gyro_cage()
	_expect(
		game.phase == game.Phase.SPLICER
		and game.gyro_ring_index == 0
		and game.gyro_angles.is_empty(),
		"M13 refuses direct inertial-cage entry until the completed M12 summary"
	)
	for feed in ["tether", "core", "badge", "tether", "badge", "core"]:
		game.advance_splice_feed(feed)
	var seated_m12_logs: int = game.log_lines.size()
	game.advance_splice_feed("core")
	var extra_feed_key := InputEventKey.new()
	extra_feed_key.pressed = true
	extra_feed_key.keycode = KEY_1
	game._unhandled_key_input(extra_feed_key)
	_expect(
		game.splice_index == 6
		and game.splice_choices == ["tether", "core", "badge", "tether", "badge", "core"]
		and game.log_lines.size() == seated_m12_logs,
		"after six seated M12 segments, extra direct and keyboard feed attempts remain inert before cross-stamp"
	)
	game.free()

	game = _enter_splicer()
	game.advance_splice_feed("tether")
	game.advance_splice_feed("tether")
	game.advance_splice_feed("tether")
	game.open_next_order()
	_expect(
		game.phase == game.Phase.GYRO
		and game.splice_degraded
		and game._gyro_source_line() == "TORN REEL / UNDERPRINT UNVERIFIED",
		"a torn M12 reel still enters M13 and remains marked unverified in the gyro source record"
	)
	game.free()

	game = _enter_gyro_cage()
	_expect(
		game.phase == game.Phase.GYRO
		and game.gyro_ring_index == 0
		and game.gyro_angles == game.GYRO_START_ANGLES
		and game.gyro_latches.is_empty()
		and game.gyro_settle == game.GYRO_SETTLE_LIMIT
		and game.gyro_index_pins == game.GYRO_INDEX_PIN_LIMIT
		and not game.gyro_degraded
		and game.gyro_integrity_start == game.integrity
		and game.gyro_coherence_start == game.coherence
		and game.gyro_display.visible
		and not game.station_map.visible
		and "RING 01/04" in game.maintenance_map_forecast.text
		and "DATUM" in game.maintenance_work_ledger.text,
		"the stamped M12 ledger alone opens M13 with its four-ring datum state and visible cage display"
	)
	var m8_allocations: Array = game.maintenance_allocations.duplicate()
	var m9_history: Array = game.service_history.duplicate()
	var m10_failures: Dictionary = game.service_failures.duplicate(true)
	var m11_path: Array = game.walkback_path.duplicate()
	var m11_witnesses: Array = game.walkback_witnesses.duplicate()
	var m11_hazards: Array = game.walkback_hazards.duplicate()
	var m11_exposed: bool = game.walkback_exposed
	var m11_seal: int = game.walkback_seal
	var m12_choices: Array = game.splice_choices.duplicate()
	var m12_misfeeds: int = game.splice_misfeeds
	var m12_tension: int = game.splice_tension
	var m12_degraded: bool = game.splice_degraded
	var m12_integrity_start: int = game.splice_integrity_start
	var m12_coherence_start: int = game.splice_coherence_start
	var initial_logs: int = game.log_lines.size()
	game.rotate_gyro(0)
	game.rotate_gyro(3)
	game.maintenance_system_buttons["carrier"].emit_signal("pressed")
	_expect(
		game.gyro_ring_index == 0
		and game.gyro_angles == game.GYRO_START_ANGLES
		and game.gyro_settle == game.GYRO_SETTLE_LIMIT
		and game.gyro_index_pins == game.GYRO_INDEX_PIN_LIMIT
		and game.log_lines.size() == initial_logs,
		"invalid gyro directions and the unused shared carrier control are inert without a timestamp"
	)
	var direction_key := InputEventKey.new()
	direction_key.pressed = true
	direction_key.keycode = KEY_1
	game._unhandled_key_input(direction_key)
	_expect(
		game.gyro_angles[0] == 7 and game.gyro_settle == game.GYRO_SETTLE_LIMIT - 1,
		"CCW wraps ring zero from datum 0 to 7 while consuming exactly one settle"
	)
	direction_key.keycode = KEY_2
	game._unhandled_key_input(direction_key)
	_expect(
		game.gyro_angles[0] == 0 and game.gyro_settle == game.GYRO_SETTLE_LIMIT - 2,
		"CW wraps ring zero from 7 to 0 while consuming exactly one additional settle"
	)
	game._reset_model()
	game.free()

	game = _enter_gyro_cage()
	m8_allocations = game.maintenance_allocations.duplicate()
	m9_history = game.service_history.duplicate()
	m10_failures = game.service_failures.duplicate(true)
	m11_path = game.walkback_path.duplicate()
	m11_witnesses = game.walkback_witnesses.duplicate()
	m11_hazards = game.walkback_hazards.duplicate()
	m11_exposed = game.walkback_exposed
	m11_seal = game.walkback_seal
	m12_choices = game.splice_choices.duplicate()
	m12_misfeeds = game.splice_misfeeds
	m12_tension = game.splice_tension
	m12_degraded = game.splice_degraded
	m12_integrity_start = game.splice_integrity_start
	m12_coherence_start = game.splice_coherence_start
	game.integrity = 99
	game.coherence = 1
	game._refresh_all()
	var start_integrity: int = game.integrity
	var start_coherence: int = game.coherence
	# The clean datum route is +2, -1, +3, +1: seven rotations and four latches.
	game.rotate_gyro(1)
	game.maintenance_system_buttons["reserve"].emit_signal("pressed")
	var latch_key := InputEventKey.new()
	latch_key.pressed = true
	latch_key.keycode = KEY_SPACE
	game._unhandled_key_input(latch_key)
	game.maintenance_system_buttons["loop"].emit_signal("pressed")
	game.maintenance_repair_button.emit_signal("pressed")
	game.rotate_gyro(1)
	game.rotate_gyro(1)
	direction_key.keycode = KEY_2
	game._unhandled_key_input(direction_key)
	game.latch_gyro()
	game.maintenance_system_buttons["reserve"].emit_signal("pressed")
	game.maintenance_repair_button.emit_signal("pressed")
	_expect(
		game.phase == game.Phase.GYRO_SUMMARY
		and game.gyro_angles == game.GYRO_TARGET_ANGLES
		and game.gyro_latches.size() == 4
		and game.gyro_ring_index == 4
		and game.gyro_settle == 2
		and game.gyro_index_pins == game.GYRO_INDEX_PIN_LIMIT
		and not game.gyro_degraded
		and game.gyro_load_events.size() == 4
		and game.gyro_load_events == game.GYRO_LOAD_LINES
		and "02 / 04 / 05 / 00 > 02 / 04 / 05 / 00" in game.outcome_ledger.get_parsed_text()
		and "HAB-A@19:14:02>MED-2@19:14:04>AUX-4@19:14:07>HAB-C@19:14:08" in game.outcome_ledger.get_parsed_text()
		and game.outcome_ledger.get_parsed_text().count("\n") == 7
		and game.gyro_display._readout_state_line() == "CAGE ZEROED"
		and game.integrity == mini(100, start_integrity + 4)
		and game.coherence == maxi(0, start_coherence - 3),
		"mixed controls seat all rings with truthful final angles, visible load times, a zeroed readout, and bounded effects"
	)
	_expect(
		game.maintenance_allocations == m8_allocations
		and game.service_history == m9_history
		and game.service_failures == m10_failures
		and game.walkback_path == m11_path
		and game.walkback_witnesses == m11_witnesses
		and game.walkback_hazards == m11_hazards
		and game.walkback_exposed == m11_exposed
		and game.walkback_seal == m11_seal
		and game.splice_choices == m12_choices
		and game.splice_misfeeds == m12_misfeeds
		and game.splice_tension == m12_tension
		and game.splice_degraded == m12_degraded
		and game.splice_integrity_start == m12_integrity_start
		and game.splice_coherence_start == m12_coherence_start,
		"a clean M13 repair leaves all M1-M12 arrays, dictionaries, and scalars unchanged"
	)
	var completed_integrity: int = game.integrity
	var completed_coherence: int = game.coherence
	var completed_load_events: int = game.gyro_load_events.size()
	game.rotate_gyro(-1)
	game.latch_gyro()
	direction_key.keycode = KEY_1
	game._unhandled_key_input(direction_key)
	game.maintenance_system_buttons["loop"].emit_signal("pressed")
	game.maintenance_system_buttons["reserve"].emit_signal("pressed")
	game.maintenance_repair_button.emit_signal("pressed")
	_expect(
		game.integrity == completed_integrity
		and game.coherence == completed_coherence
		and game.gyro_load_events.size() == completed_load_events,
		"completed M13 direct, keyboard, shared rotation, and shared action input remains inert"
	)
	game._reset_model()
	_expect(
		game.gyro_ring_index == 0
		and game.gyro_angles.is_empty()
		and game.gyro_latches.is_empty()
		and game.gyro_settle == 0
		and game.gyro_index_pins == 0
		and game.gyro_load_events.is_empty()
		and not game.gyro_degraded
		and not game.gyro_display.visible
		and game.station_map.visible,
		"campaign reset clears M13 state and restores the station map"
	)
	game.free()

	game = _enter_gyro_cage()
	var coherent_copy: String = game.maintenance_carrier_label.text
	game.coherence = 10
	game._refresh_all()
	_expect(
		game.maintenance_carrier_label.text != coherent_copy
		and game.maintenance_system_buttons.size() == 3
		and game.maintenance_repair_button.visible,
		"low coherence changes M13 attribution copy only and leaves ring controls available"
	)
	game.latch_gyro()
	_expect(
		game.gyro_ring_index == 0
		and game.gyro_index_pins == 1
		and game.phase == game.Phase.GYRO,
		"a bad latch spends one index pin without advancing a ring"
	)
	var degraded_integrity: int = game.integrity
	var degraded_coherence: int = game.coherence
	game.latch_gyro()
	_expect(
		game.phase == game.Phase.GYRO_SUMMARY
		and game.gyro_degraded
		and game.gyro_index_pins == 0
		and game.gyro_ring_index == 0
		and game.integrity == degraded_integrity
		and game.coherence == maxi(0, degraded_coherence - 7)
		and game.maintenance_allocations == m8_allocations
		and game.service_history == m9_history
		and game.service_failures == m10_failures
		and game.walkback_path == m11_path
		and game.walkback_witnesses == m11_witnesses
		and game.walkback_hazards == m11_hazards
		and game.walkback_exposed == m11_exposed
		and game.walkback_seal == m11_seal
		and game.splice_choices == m12_choices
		and game.splice_misfeeds == m12_misfeeds
		and game.splice_tension == m12_tension
		and game.splice_degraded == m12_degraded
		and game.splice_integrity_start == m12_integrity_start
		and game.splice_coherence_start == m12_coherence_start,
		"the second bad latch finishes M13 degraded once without rewriting M12"
	)
	_expect(
		game.gyro_load_events.is_empty()
		and "02 / 04 / 05 / 00 > 00 / 05 / 02 / 07" in game.outcome_ledger.get_parsed_text()
		and "NONE RECORDED" in game.outcome_ledger.get_parsed_text()
		and game.outcome_ledger.get_parsed_text().count("\n") == 7
		and "HAB-A>MED-2>AUX-4>HAB-C" not in game.outcome_ledger.text,
		"a zero-load cage slip reports actual angles and never claims an unrecorded habitat sequence"
	)
	game.free()

	game = _enter_gyro_cage()
	game.rotate_gyro(1)
	game.rotate_gyro(1)
	game.latch_gyro()
	game.rotate_gyro(-1)
	game.latch_gyro()
	game.rotate_gyro(1)
	game.rotate_gyro(1)
	game.rotate_gyro(1)
	game.latch_gyro()
	game.gyro_settle = 1
	game.rotate_gyro(1)
	_expect(
		game.phase == game.Phase.GYRO
		and game.gyro_ring_index == 3
		and game.gyro_angles[3] == 0
		and game.gyro_settle == 0,
		"the final available settle may land exactly on a datum without slipping the cage"
	)
	game.latch_gyro()
	_expect(
		game.phase == game.Phase.GYRO_SUMMARY
		and not game.gyro_degraded
		and game.gyro_ring_index == 4,
		"a final ring already on datum may latch cleanly with zero settle remaining"
	)
	game.free()

	game = _enter_gyro_cage()
	game.gyro_settle = 1
	game.rotate_gyro(1)
	_expect(
		game.phase == game.Phase.GYRO_SUMMARY
		and game.gyro_degraded
		and game.gyro_settle == 0
		and game.gyro_ring_index == 0,
		"exhausting settle before a reachable datum auto-finishes the cage degraded"
	)
	game.free()


func _verify_duplex_splicer() -> void:
	var game = _enter_walkback()
	game.open_splicer()
	_expect(
		game.phase == game.Phase.WALKBACK
		and game.splice_index == 0
		and game.splice_choices.is_empty(),
		"M12 refuses direct entry until the completed M11 summary"
	)
	game.free()

	game = _enter_splicer()
	_expect(
		game.phase == game.Phase.SPLICER
		and game.splice_index == 0
		and game.splice_choices.is_empty()
		and game.splice_misfeeds == 0
		and game.splice_tension == 2
		and not game.splice_degraded
		and game.splice_integrity_start == game.integrity
		and game.splice_coherence_start == game.coherence
		and game.splice_display.visible
		and not game.station_map.visible
		and "SEGMENT 00/06" in game.maintenance_map_forecast.text
		and "GATE TARGET" in game.maintenance_work_ledger.text,
		"the canonical three-witness M11 ledger alone opens M12 with fresh recorder state and display"
	)
	var expected_feeds := ["tether", "core", "badge", "tether", "badge", "core"]
	var unique_mapping := true
	for row in range(game.SPLICE_TARGET_CODES.size()):
		var matches: Array[String] = []
		for feed in game.SPLICE_FEEDS:
			if game._splice_feed_code_at(feed, row) == int(game.SPLICE_TARGET_CODES[row]):
				matches.append(feed)
		unique_mapping = (
			unique_mapping
			and matches.size() == 1
			and matches[0] == expected_feeds[row]
		)
	_expect(
		unique_mapping,
		"every M12 gate row has exactly one matching feed in the documented order"
	)
	var m8_allocations: Array = game.maintenance_allocations.duplicate()
	var m9_history: Array = game.service_history.duplicate()
	var m10_failures: Dictionary = game.service_failures.duplicate(true)
	var m11_path: Array = game.walkback_path.duplicate()
	var m11_witnesses: Array = game.walkback_witnesses.duplicate()
	var m11_hazards: Array = game.walkback_hazards.duplicate()
	var m11_exposed: bool = game.walkback_exposed
	var m11_integrity_start: int = game.walkback_integrity_start
	var m11_coherence_start: int = game.walkback_coherence_start
	var initial_log_count: int = game.log_lines.size()
	game.advance_splice_feed("invalid")
	game.maintenance_repair_button.emit_signal("pressed")
	var stamp_key := InputEventKey.new()
	stamp_key.pressed = true
	stamp_key.keycode = KEY_SPACE
	game._unhandled_key_input(stamp_key)
	_expect(
		game.splice_index == 0
		and game.splice_tension == 2
		and game.splice_misfeeds == 0
		and game.log_lines.size() == initial_log_count
		and game.maintenance_allocations == m8_allocations
		and game.service_history == m9_history
		and game.service_failures == m10_failures
		and game.walkback_path == m11_path
		and game.walkback_witnesses == m11_witnesses,
		"invalid feed and premature Space are inert without a recorder timestamp or prior-campaign mutation"
	)
	var feed_key := InputEventKey.new()
	feed_key.pressed = true
	feed_key.keycode = KEY_2
	game._unhandled_key_input(feed_key)
	game.maintenance_system_buttons["loop"].emit_signal("pressed")
	game.advance_splice_feed("badge")
	feed_key.keycode = KEY_2
	game._unhandled_key_input(feed_key)
	game.maintenance_system_buttons["carrier"].emit_signal("pressed")
	feed_key.keycode = KEY_1
	game._unhandled_key_input(feed_key)
	_expect(
		game.splice_choices == ["tether", "core", "badge", "tether", "badge", "core"]
		and game.splice_index == 6
		and game.splice_misfeeds == 0
		and game.splice_tension == 2
		and game.log_lines.size() == initial_log_count + 6,
		"keyboard, shared route buttons, and direct feeds assemble the exact six-segment duplex order"
	)
	game.integrity = 99
	game.coherence = 1
	game._refresh_all()
	var clean_integrity: int = game.integrity
	var clean_coherence: int = game.coherence
	game.maintenance_repair_button.emit_signal("pressed")
	_expect(
		game.phase == game.Phase.SPLICER_SUMMARY
		and not game.splice_degraded
		and game.integrity == mini(100, clean_integrity + 3)
		and game.coherence == maxi(0, clean_coherence - 2)
		and game.walkback_path == m11_path
		and game.walkback_witnesses == m11_witnesses
		and game.walkback_hazards == m11_hazards
		and game.walkback_exposed == m11_exposed
		and game.walkback_integrity_start == m11_integrity_start
		and game.walkback_coherence_start == m11_coherence_start
		and "MANUAL / 19:13:08" in game.outcome_ledger.text,
		"a clean cross-stamp applies bounded resources without rewriting M11"
	)
	var stamped_integrity: int = game.integrity
	var stamped_coherence: int = game.coherence
	var stamped_log_count: int = game.log_lines.size()
	game.advance_splice_feed("tether")
	game.stamp_splice()
	game.maintenance_system_buttons["loop"].emit_signal("pressed")
	feed_key.keycode = KEY_1
	game._unhandled_key_input(feed_key)
	_expect(
		game.integrity == stamped_integrity
		and game.coherence == stamped_coherence
		and game.log_lines.size() == stamped_log_count,
		"completed M12 direct, keyboard, and shared-button input remains inert"
	)
	game._reset_model()
	_expect(
		game.splice_index == 0
		and game.splice_choices.is_empty()
		and game.splice_misfeeds == 0
		and game.splice_tension == 0
		and not game.splice_degraded
		and not game.splice_display.visible
		and game.station_map.visible,
		"campaign reset clears M12 state and restores the station map"
	)
	game.free()

	game = _enter_splicer()
	var degraded_m11_path: Array = game.walkback_path.duplicate()
	var degraded_m11_witnesses: Array = game.walkback_witnesses.duplicate()
	var degraded_m11_hazards: Array = game.walkback_hazards.duplicate()
	var degraded_m11_exposed: bool = game.walkback_exposed
	game.coherence = 1
	game._refresh_all()
	var low_copy: String = game.maintenance_carrier_label.text
	_expect(
		"ONE HAND MOVING TWICE" in low_copy
		and game.maintenance_system_buttons.size() == 3
		and game.maintenance_repair_button.visible,
		"low coherence changes M12 attribution copy only and leaves every feed control available"
	)
	game.advance_splice_feed("tether")
	game.advance_splice_feed("tether")
	_expect(
		game.splice_choices == ["tether"]
		and game.splice_index == 1
		and game.splice_misfeeds == 1
		and game.splice_tension == 1
		and game.phase == game.Phase.SPLICER,
		"a wrong second-row feed tears one tension without advancing the splice"
	)
	var degraded_integrity: int = game.integrity
	var degraded_coherence: int = game.coherence
	game.advance_splice_feed("tether")
	_expect(
		game.phase == game.Phase.SPLICER_SUMMARY
		and game.splice_degraded
		and game.splice_misfeeds == 2
		and game.splice_tension == 0
		and game.splice_index == 1
		and game.integrity == degraded_integrity
		and game.coherence == maxi(0, degraded_coherence - 6)
		and game.walkback_path == degraded_m11_path
		and game.walkback_witnesses == degraded_m11_witnesses
		and game.walkback_hazards == degraded_m11_hazards
		and game.walkback_exposed == degraded_m11_exposed
		and "AUTOMATIC / THIRD FEED TORN" in game.outcome_ledger.text,
		"the second misfeed finishes degraded once without rewriting M11"
	)
	game.free()


func _verify_clock_walkback() -> void:
	var game = _enter_service_run()
	game.open_walkback()
	_expect(
		game.phase == game.Phase.SERVICE_RUN,
		"M11 refuses direct entry until the completed M10 summary"
	)
	game.free()

	game = _enter_walkback()
	_expect(
		game.phase == game.Phase.WALKBACK
		and game.walkback_seal == 9
		and game.walkback_room == "core"
		and game.walkback_path == ["core"]
		and game.walkback_witnesses.is_empty()
		and game.walkback_hazards == ["carrier"],
		"only the completed M10 summary opens M11 with its core state and retained M9 scar hazard"
	)
	_expect(
		game.maintenance_allocations.size() == 6
		and game.service_history.size() == 9
		and game.station_map.walkback_active
		and game.station_map.walkback_room == "core"
		and game.station_map.walkback_path == ["core"]
		and game.station_map.walkback_hazards == ["carrier"],
		"M11 preserves M8-M10 history and projects the active route, path, and hazard through the map"
	)
	var entry_integrity: int = game.integrity
	var entry_coherence: int = game.coherence
	_expect(
		game.walkback_integrity_start == entry_integrity
		and game.walkback_coherence_start == entry_coherence,
		"M11 snapshots its entry integrity and coherence ledger"
	)
	var rejected_log_count: int = game.log_lines.size()
	game.move_walkback(9)
	game.apply_walkback_action()
	_expect(
		game.walkback_room == "core"
		and game.walkback_seal == 9
		and game.walkback_path == ["core"]
		and game.walkback_witnesses.is_empty()
		and game.log_lines.size() == rejected_log_count,
		"invalid movement and an under-witness core lock spend nothing and record no timestamp"
	)
	var walk_key := InputEventKey.new()
	walk_key.pressed = true
	walk_key.keycode = KEY_1
	game._unhandled_key_input(walk_key)
	walk_key.keycode = KEY_SPACE
	game._unhandled_key_input(walk_key)
	_expect(
		game.walkback_room == "med"
		and game.walkback_seal == 7
		and game.walkback_path == ["core", "med"]
		and game.walkback_witnesses == ["med"],
		"keyboard 1 and Space take the first local route and spend exactly one travel plus one witness seal"
	)
	var before_repeat: int = game.walkback_seal
	game.maintenance_repair_button.emit_signal("pressed")
	game.apply_walkback_action()
	_expect(
		game.walkback_seal == before_repeat and game.walkback_witnesses == ["med"],
		"shared pressed action and repeated witness reads cannot spend seal twice"
	)
	game.maintenance_system_buttons["reserve"].emit_signal("pressed")
	game.maintenance_repair_button.emit_signal("pressed")
	_expect(
		game.walkback_room == "aux"
		and game.walkback_seal == 5
		and game.walkback_witnesses == ["med", "aux"],
		"actual route-button signals follow current neighbor order and shared action samples AUX-4"
	)
	game.move_walkback(1)
	game.apply_walkback_action()
	_expect(
		game.phase == game.Phase.WALKBACK_SUMMARY
		and not game.walkback_exposed
		and game.walkback_room == "core"
		and game.walkback_seal == 4
		and game.integrity == mini(100, entry_integrity + 3)
		and game.coherence == maxi(0, entry_coherence - 1),
		"two witnesses return to CORE with exact local travel, sample, and success accounting"
	)
	var success_integrity: int = game.integrity
	var success_coherence: int = game.coherence
	game.apply_walkback_action()
	game.move_walkback(0)
	_expect(
		game.integrity == success_integrity
		and game.coherence == success_coherence
		and game.walkback_path == ["core", "med", "aux", "core"],
		"completed M11 method calls remain inert"
	)
	game.free()

	game = _enter_walkback(["loop", "reserve", "loop", "reserve", "loop", "reserve", "loop", "reserve", "loop"])
	_expect(
		game.service_scars == ["carrier"]
		and game.service_failures.has("carrier")
		and game.walkback_hazards == ["carrier"]
		and "M9 SCAR+M10 LOSS" in game._walkback_hazard_line(),
		"an overlapping M9 scar and M10 loss produce one annotated walkback hazard"
	)
	game.move_walkback(2)
	_expect(
		game.walkback_room == "bridge"
		and game.walkback_seal == 7,
		"overlapping corridor damage adds exactly one seal surcharge"
	)
	game.free()

	game = _enter_walkback(["loop", "carrier", "loop", "carrier", "loop", "carrier", "loop", "carrier", "loop"])
	_expect(
		game.walkback_hazards == ["reserve", "carrier"]
		and "M9 SCAR" in game._walkback_hazard_line()
		and "M10 LOSS" in game._walkback_hazard_line(),
		"M11 hazard union retains distinct M9 scars and M10 service failures"
	)
	game.move_walkback(0)
	_expect(
		game.walkback_room == "med" and game.walkback_seal == 7,
		"a mapped reserve hazard costs two seal while local corridors cost one"
	)
	game.apply_walkback_action()
	game.move_walkback(1)
	game.apply_walkback_action()
	game.move_walkback(2)
	game.move_walkback(1)
	game.apply_walkback_action()
	_expect(
		game.walkback_seal == 1 and game.walkback_room == "bridge",
		"the deterministic detour preserves exact seal accounting before an unaffordable hazard"
	)
	var unaffordable_path: Array[String] = game.walkback_path.duplicate()
	var unaffordable_log_count: int = game.log_lines.size()
	game.move_walkback(1)
	_expect(
		game.phase == game.Phase.WALKBACK
		and game.walkback_room == "bridge"
		and game.walkback_seal == 1
		and game.walkback_path == unaffordable_path
		and game.log_lines.size() == unaffordable_log_count,
		"unaffordable mapped hazards are rejected without movement, seal loss, path, or log timestamp"
	)
	game.free()

	game = _enter_walkback()
	for index in [0, 1, 2, 1, 1]:
		game.move_walkback(index)
		if game.walkback_room in ["med", "aux", "bridge"] and game.walkback_room not in game.walkback_witnesses:
			game.apply_walkback_action()
	game.apply_walkback_action()
	_expect(
		game.phase == game.Phase.WALKBACK_SUMMARY
		and not game.walkback_exposed
		and game.walkback_witnesses == ["med", "aux", "bridge"]
		and game.walkback_path == ["core", "med", "aux", "airlock", "bridge", "core"]
		and game.walkback_seal == 0
		and game.integrity == mini(100, game.walkback_integrity_start + 6)
		and game.coherence == maxi(0, game.walkback_coherence_start - 4),
		"the canonical three-witness path crosses one hazard and resolves with its stronger bounded ledger effect"
	)
	game.free()

	game = _enter_walkback()
	for index in [2, 0, 0, 0, 1, 0]:
		game.move_walkback(index)
		if game.walkback_room in ["med", "aux", "bridge"] and game.walkback_room not in game.walkback_witnesses:
			game.apply_walkback_action()
	_expect(
		game.phase == game.Phase.WALKBACK_SUMMARY
		and game.walkback_exposed
		and game.integrity == maxi(0, game.walkback_integrity_start - 8)
		and game.coherence == maxi(0, game.walkback_coherence_start - 6),
		"an away-from-core exhausted tether applies the exposed penalty exactly once"
	)
	game.free()

	game = _enter_walkback()
	game.coherence = 10
	game._refresh_all()
	_expect(
		game.maintenance_work_box.visible
		and game.maintenance_action_box.visible
		and game.maintenance_system_buttons.size() == 3
		and game.maintenance_repair_button.visible,
		"low coherence changes M11 copy only and keeps all movement and witness controls readable"
	)
	game._reset_model()
	_expect(
		game.walkback_seal == 0
		and game.walkback_room == "core"
		and game.walkback_path.is_empty()
		and game.walkback_witnesses.is_empty()
		and game.walkback_hazards.is_empty()
		and not game.station_map.walkback_active,
		"campaign reset clears and hides all M11 state"
	)
	game.free()


func _verify_service_run() -> void:
	var game = _enter_final_summary("isolate", "quarantine", "handoff")
	game.open_service_run()
	_expect(
		game.phase == game.Phase.FINAL_SUMMARY,
		"M10 refuses direct service-run entry before M9's completed summary"
	)
	game.open_watch_roster()
	game.resolve_watch("manual")
	game.resolve_watch("manual")
	game.resolve_watch("manual")
	game.open_maintenance_rotation()
	game.open_service_run()
	_expect(
		game.phase == game.Phase.MAINTENANCE,
		"M10 refuses direct service-run entry while M9 remains active"
	)
	game.free()

	game = _enter_service_run()
	_expect(
		game.phase == game.Phase.SERVICE_RUN
		and game.service_action == 0
		and game.service_conditions == {"loop": 3, "reserve": 3, "carrier": 4}
		and game.service_overhauled == "carrier"
		and game.service_scars == ["carrier"]
		and game.service_failures.is_empty()
		and game.service_history.is_empty()
		and not game.service_carrier_silent,
		"only M9's completed summary enters M10, overhauls the first failed route, and preserves its scars"
	)
	_expect(
		game.maintenance_allocations.size() == 6
		and game.watch_actions.size() == 3
		and game.station_map.maintenance_active
		and game.station_map.maintenance_conditions == game.service_conditions
		and game.station_map.maintenance_condition_max == 4
		and game.station_map.maintenance_scars == game.service_scars,
		"M10 retains M8/M9 history and projects four-condition scars through the shared maintenance map"
	)
	var service_endurance_start: int = game.endurance_days
	var service_integrity_start: int = game.integrity
	var service_coherence_start: int = game.coherence
	_expect(
		game.service_endurance_start == service_endurance_start
		and game.service_integrity_start == service_integrity_start
		and game.service_coherence_start == service_coherence_start
		and game.maintenance_work_box.visible
		and game.maintenance_action_box.visible
		and "SELECTED ROUTE LOSS" in game.maintenance_selection_label.text,
		"M10 snapshots its starting ledger and reuses the visible maintenance work and action panels"
	)
	game.select_service_system("unknown")
	game.select_service_system("carrier")
	game.apply_service_action()
	_expect(
		game.service_action == 0 and game.service_conditions.carrier == 4,
		"invalid M10 selections and a full selected route reject without consuming an action"
	)
	var service_key := InputEventKey.new()
	service_key.pressed = true
	service_key.keycode = KEY_1
	game._unhandled_key_input(service_key)
	_expect(game.service_selected == "loop", "1 selects LOOP-C through the M10 keyboard path")
	service_key.keycode = KEY_2
	game._unhandled_key_input(service_key)
	_expect(game.service_selected == "reserve", "2 selects NUTRIENT RESERVE through the M10 keyboard path")
	service_key.keycode = KEY_3
	game._unhandled_key_input(service_key)
	var service_space := InputEventKey.new()
	service_space.pressed = true
	service_space.keycode = KEY_SPACE
	game._unhandled_key_input(service_space)
	_expect(
		game.service_selected == "carrier" and game.service_action == 0,
		"3 selects CARRIER LINK and Space still rejects a full M10 route without consuming an action"
	)
	game.maintenance_system_buttons["loop"].emit_signal("pressed")
	_expect(
		game.service_selected == "loop",
		"the visible shared route button selects LOOP-C during M10"
	)
	game.maintenance_repair_button.emit_signal("pressed")
	_expect(
		game.service_action == 1
		and game.service_history == ["loop"]
		and game.service_conditions == {"loop": 4, "reserve": 2, "carrier": 3},
		"the visible shared action button applies one M10 service transaction"
	)
	game.free()

	game = _enter_maintenance_rotation()
	for _pulse in range(3):
		_apply_maintenance_pair(game, "loop", "reserve")
	game.maintenance_failures.clear()
	game.open_next_order()
	_expect(
		game.phase == game.Phase.SERVICE_RUN
		and game.service_overhauled == "loop"
		and game.service_conditions == {"loop": 4, "reserve": 3, "carrier": 3}
		and game.service_scars.is_empty()
		and "NO M9 SCAR RECORDED" in game.service_notice,
		"a scar-free M9 summary falls back to overhauling LOOP-C without inventing a scar"
	)
	game.free()

	game = _enter_service_run()
	for system in ["loop", "reserve", "carrier", "loop", "reserve", "carrier", "loop", "reserve", "carrier"]:
		game.select_service_system(system)
		game.apply_service_action()
	_expect(
		game.phase == game.Phase.SERVICE_SUMMARY
		and game.service_action == 9
		and game.service_history == ["loop", "reserve", "carrier", "loop", "reserve", "carrier", "loop", "reserve", "carrier"]
		and game.service_conditions == {"loop": 2, "reserve": 3, "carrier": 4}
		and game.service_failures.is_empty(),
		"the clean nine-action M10 allocation applies +2/-1 arithmetic and resolves once"
	)
	var complete_endurance: int = game.endurance_days
	var complete_integrity: int = game.integrity
	var complete_coherence: int = game.coherence
	game.apply_service_action()
	game.select_service_system("loop")
	game.maintenance_repair_button.emit_signal("pressed")
	_expect(
		game.service_action == 9
		and game.endurance_days == complete_endurance
		and game.integrity == complete_integrity
		and game.coherence == complete_coherence,
		"completed M10 direct, selection, and shared-button calls are inert"
	)
	game.free()

	game = _enter_service_run()
	game.integrity = 2
	game.service_conditions = {"loop": 1, "reserve": 3, "carrier": 4}
	game.select_service_system("reserve")
	game.apply_service_action()
	_expect(
		game.service_conditions.loop == 0
		and game.service_failures.get("loop") == 4
		and game.integrity == 0,
		"the first LOOP-C zero posts its exact bounded four-integrity penalty"
	)
	game.select_service_system("loop")
	game.apply_service_action()
	game.select_service_system("reserve")
	game.apply_service_action()
	game.select_service_system("carrier")
	game.apply_service_action()
	_expect(
		game.service_conditions.loop == 0
		and game.service_failures.get("loop") == 4
		and game.integrity == 0,
		"repairing and re-zeroing LOOP-C does not repeat its M10 failure penalty"
	)
	game.free()

	game = _enter_service_run()
	game.endurance_days = 0
	game.service_conditions = {"loop": 3, "reserve": 1, "carrier": 4}
	game.select_service_system("loop")
	game.apply_service_action()
	_expect(
		game.service_conditions.reserve == 0
		and game.service_failures.get("reserve") == 1
		and game.endurance_days == 0,
		"the first nutrient-reserve zero posts its exact bounded one-endurance penalty"
	)
	game.free()

	game = _enter_service_run()
	game.coherence = 2
	game.service_conditions = {"loop": 3, "reserve": 4, "carrier": 1}
	game.select_service_system("loop")
	game.apply_service_action()
	_expect(
		game.service_conditions.carrier == 0
		and game.service_failures.get("carrier") == 3
		and game.coherence == 0
		and game.service_carrier_silent,
		"the first carrier zero posts its bounded coherence penalty and silences a historical survivor"
	)
	game.free()

	game = _enter_service_run(["loop", "reserve"])
	game.coherence = 10
	game._refresh_all()
	_expect(
		game.maintenance_work_box.visible
		and game.maintenance_action_box.visible
		and game.maintenance_system_buttons.size() == 3
		and game.maintenance_repair_button.visible,
		"low coherence changes M10 copy only and leaves its controls available"
	)
	game.free()

	game = _enter_final_summary("purge", "sterilize", "remote")
	game.open_watch_roster()
	game.resolve_watch("manual")
	game.resolve_watch("manual")
	game.resolve_watch("manual")
	game.open_maintenance_rotation()
	for _pulse in range(3):
		_apply_maintenance_pair(game, "loop", "reserve")
	game.open_next_order()
	game.service_conditions = {"loop": 3, "reserve": 4, "carrier": 1}
	game.select_service_system("loop")
	game.apply_service_action()
	_expect(
		game._watch_survivor_state() == "NO CERTIFIED CARRIER"
		and game.service_failures.get("carrier") == 3
		and not game.service_carrier_silent,
		"carrier failure never revives or falsely silences an absent historical survivor"
	)
	game._reset_model()
	_expect(
		game.service_action == 0
		and game.service_conditions.is_empty()
		and game.service_failures.is_empty()
		and game.service_history.is_empty()
		and not game.service_carrier_silent
		and not game.maintenance_work_box.visible
		and not game.maintenance_action_box.visible,
		"campaign reset clears and hides all M10 state"
	)
	game.free()


func _apply_maintenance_pair(game, first: String, second: String) -> void:
	game.select_maintenance_system(first)
	game.maintenance_system_buttons[first].emit_signal("pressed")
	game.apply_maintenance_stroke()
	game.select_maintenance_system(second)
	game.maintenance_repair_button.emit_signal("pressed")


func _verify_recovered_watch_continued() -> void:
	var game = _enter_final_summary("isolate", "quarantine", "handoff")
	var archive_endurance: int = game.endurance_days
	var archive_integrity: int = game.integrity
	var archive_coherence: int = game.coherence
	game.open_archive_packet()
	_expect(
		game.phase == game.Phase.FINAL_SUMMARY
		and game.endurance_days == archive_endurance
		and game.integrity == archive_integrity
		and game.coherence == archive_coherence,
		"the optional archive remains resource- and phase-neutral before watch entry"
	)
	var start_endurance: int = game.endurance_days
	var start_integrity: int = game.integrity
	var start_coherence: int = game.coherence
	var watch_key := InputEventKey.new()
	watch_key.pressed = true
	watch_key.keycode = KEY_N
	game._unhandled_key_input(watch_key)
	_expect(
		game.phase == game.Phase.WATCH
		and game.watch_day == 0
		and game.watch_endurance_start == start_endurance
		and game.watch_integrity_start == start_integrity
		and game.watch_coherence_start == start_coherence
		and not game.archive_panel.visible
		and not game.archive_button.visible,
		"N snapshots final resources and hides archive UI on watch entry"
	)
	_expect(
		game.watch_action_box.visible
		and game.watch_manual_button.visible
		and game.watch_roster_button.visible
		and game.watch_roster_uses == 0
		and game.watch_actions.size() == 0
		and game.watch_status_label.text.begins_with("NEXT ENTRY 01 / 03")
		and game._watch_survivor_state() == "RESPONDING",
		"the recovered survivor begins with exactly the available watch actions"
	)
	game.resolve_watch("manual")
	_expect(
		game.watch_day == 1
		and game.watch_actions == ["manual"]
		and game.endurance_days == maxi(0, start_endurance - 1)
		and game.integrity == mini(100, start_integrity + 2)
		and game.coherence == mini(100, start_coherence + 1)
		and game._watch_survivor_state() == "RESPONDING",
		"manual watch applies its exact first-day effect"
	)
	game.watch_roster_button.emit_signal("pressed")
	_expect(
		game.watch_day == 2
		and game.watch_actions == ["manual", "roster"]
		and game.watch_roster_uses == 1
		and game.endurance_days == start_endurance
		and game.integrity == mini(100, start_integrity + 5)
		and game.coherence == maxi(0, start_coherence - 5)
		and game.watch_status_label.text.begins_with("NEXT ENTRY 03 / 03")
		and game._watch_survivor_state() == "ECHOING",
		"the roster button applies the irreversible second-day deterioration"
	)
	var roster_key := InputEventKey.new()
	roster_key.pressed = true
	roster_key.keycode = KEY_E
	game._unhandled_key_input(roster_key)
	_expect(
		game.phase == game.Phase.WATCH_SUMMARY
		and game.watch_day == 3
		and game.watch_actions == ["manual", "roster", "roster"]
		and game.watch_roster_uses == 2
		and game._watch_survivor_state() == "COMPLIANT",
		"E completes the third roster day and records compliant survivor state"
	)
	var completed_actions: Array = game.watch_actions.duplicate()
	var completed_endurance: int = game.endurance_days
	var completed_integrity: int = game.integrity
	var completed_coherence: int = game.coherence
	var manual_key := InputEventKey.new()
	manual_key.pressed = true
	manual_key.keycode = KEY_H
	game._unhandled_key_input(manual_key)
	game.resolve_watch("roster")
	game.watch_manual_button.emit_signal("pressed")
	_expect(
		game.watch_actions == completed_actions
		and game.endurance_days == completed_endurance
		and game.integrity == completed_integrity
		and game.coherence == completed_coherence
		and game._watch_survivor_state() == "COMPLIANT",
		"the completed three-day ledger rejects direct, key, and button repeats"
	)
	game._reset_model()
	_expect(
		game.watch_day == 0
		and game.watch_roster_uses == 0
		and game.watch_actions.is_empty()
		and not game.watch_action_box.visible,
		"campaign reset clears and hides recovered-watch state"
	)
	game.free()

	game = _enter_final_summary("isolate", "quarantine", "handoff")
	game.open_watch_roster()
	var coherent_watch_copy: String = game.outcome_reveal.text
	game.free()
	game = _enter_final_summary("isolate", "quarantine", "handoff")
	game.coherence = 49
	game.open_watch_roster()
	var low_watch_copy: String = game.outcome_reveal.text
	var low_watch_endurance: int = game.endurance_days
	var low_watch_integrity: int = game.integrity
	game.resolve_watch("roster")
	_expect(
		low_watch_copy != coherent_watch_copy
		and "TWO VALID TIMEBASES" in low_watch_copy
		and game.watch_manual_button.visible
		and game.watch_roster_button.visible
		and not game.watch_manual_button.disabled
		and not game.watch_roster_button.disabled
		and game.endurance_days == low_watch_endurance + 1
		and game.integrity == mini(100, low_watch_integrity + 3)
		and game.coherence == 43,
		"low coherence changes watch attribution without changing availability or roster effects"
	)
	game.free()

	game = _enter_final_summary("bypass", "quarantine", "remote")
	game.open_watch_roster()
	var h_endurance: int = game.endurance_days
	var h_integrity: int = game.integrity
	var h_coherence: int = game.coherence
	var h_key := InputEventKey.new()
	h_key.pressed = true
	h_key.keycode = KEY_H
	game._unhandled_key_input(h_key)
	_expect(
		game.watch_actions == ["manual"]
		and game.endurance_days == maxi(0, h_endurance - 1)
		and game.integrity == mini(100, h_integrity + 2)
		and game.coherence == mini(100, h_coherence + 1),
		"H matches the manual-watch action through the top-row input path"
	)
	game.watch_manual_button.emit_signal("pressed")
	game.resolve_watch("manual")
	_expect(
		game.phase == game.Phase.WATCH_SUMMARY
		and game.watch_actions == ["manual", "manual", "manual"]
		and game.watch_roster_uses == 0
		and game._watch_survivor_state() == "RESPONDING"
		and game.endurance_days == maxi(0, h_endurance - 3)
		and game.integrity == mini(100, h_integrity + 6)
		and game.coherence == mini(100, h_coherence + 3),
		"three manual watches complete with exact costs and preserve survivor cadence"
	)
	game.free()

	game = _enter_final_summary("purge", "sterilize", "remote")
	game.open_watch_roster()
	var no_survivor_endurance: int = game.endurance_days
	var no_survivor_integrity: int = game.integrity
	var no_survivor_coherence: int = game.coherence
	game.resolve_watch("roster")
	_expect(
		game._watch_survivor_state() == "NO CERTIFIED CARRIER"
		and game.carried_mina_state == "DECEASED"
		and game.wo013_responder_result == "LOST"
		and game.endurance_days == no_survivor_endurance + 1
		and game.integrity == mini(100, no_survivor_integrity + 3)
		and game.coherence == maxi(0, no_survivor_coherence - 6),
		"a no-survivor roster applies costs without reviving a carrier"
	)
	game.coherence = 0
	game.endurance_days = 0
	game.integrity = 100
	game.resolve_watch("roster")
	_expect(
		game.endurance_days == 1 and game.integrity == 100 and game.coherence == 0,
		"recovered roster clamps integrity and coherence at their bounds"
	)
	game.coherence = 100
	game.endurance_days = 0
	game.resolve_watch("manual")
	_expect(
		game.phase == game.Phase.WATCH_SUMMARY
		and game.endurance_days == 0
		and game.integrity == 100
		and game.coherence == 100,
		"manual watch clamps resource bounds at the lower and upper limits"
	)
	game.free()


func _advance_to_seal_brace_window(game) -> void:
	game.take_evidence("telemetry")
	game.take_evidence("camera")
	game.take_evidence("mina")
	game.take_evidence("provenance")


func _complete_brace_rig(game) -> void:
	game.open_brace_rig()
	game.tension_brace_port()
	game.tension_brace_starboard()
	game.tension_brace_port()
	game.tension_brace_starboard()
	game.lock_brace_rig()


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _log_contains(game, needle: String) -> bool:
	for line in game.log_lines:
		if needle in line:
			return true
	return false
