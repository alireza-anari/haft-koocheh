extends SceneTree

class Probe extends Node:
	var callback: Callable
	func _physics_process(delta: float) -> void:
		callback.call(delta)

class ConsumingControl extends Control:
	var consumed: int = 0
	func _gui_input(_event: InputEvent) -> void:
		consumed += 1
		accept_event()

var cases: Array[String] = ["normal_api", "space_short", "space_hold", "space_duplicate", "touch_short", "touch_hold", "double_early", "double_mid", "coyote_4", "coyote_5", "coyote_6", "disable_coyote", "drop_calibration", "buffer_5", "buffer_7", "buffer_exact6", "buffer_multi", "buffer_disable_latch", "buffer_echo_expired", "buffer_touch_expired", "invalid_events", "secondary_touch", "ui_space", "ui_touch", "ui_touch_secondary", "disabled_input", "disable_reenable"]
var case_index: int = -1
var case_name: String = ""
var world: Node2D
var player: CharacterBody2D
var ui: ConsumingControl
var label: Label
var probe: Probe
var tick: int = 0
var arm_tick: int = -1
var leave_tick: int = -1
var drop_ticks: int = 0
var previous_floor: bool = false
var start_position: Vector2
var initial_y: float = 0.0
var jumps: Array[Dictionary] = []
var landings: Array[Dictionary] = []
var requests: Array[Dictionary] = []
var trace: Array[Dictionary] = []
var results: Array[Dictionary] = []
var wall_start: int = 0
var render_frames: int = 0
var simulation_seconds: float = 0.0
var output_path: String = ""
var fps_target: float = 0.0
var visual: bool = false
var capture_stage: String = ""
var captured: Array[String] = []
var between_cases: bool = true
var suite_failed: bool = false

func _initialize() -> void:
	Input.use_accumulated_input = false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output_path = arg.trim_prefix("--output=")
		elif arg.begins_with("--fps-target="):
			fps_target = float(arg.trim_prefix("--fps-target="))
		elif arg.begins_with("--case="):
			cases = [arg.trim_prefix("--case=")]
		elif arg == "--visual":
			visual = true
	if visual:
		cases = ["visual"]
	elif fps_target > 0.0:
		cases = ["fps"]
	if cases.size() == 1 and cases[0].begins_with("buffer_"):
		cases.push_front("drop_calibration")
	call_deferred("_start_case")

func _start_case() -> void:
	case_index += 1
	if case_index >= cases.size():
		_complete()
		return
	case_name = cases[case_index]
	tick = 0
	arm_tick = -1
	leave_tick = -1
	jumps = []
	landings = []
	requests = []
	trace = []
	captured = []
	capture_stage = ""
	ui = null
	render_frames = 0
	simulation_seconds = 0.0
	previous_floor = false
	var packed: PackedScene = load("res://scenes/gameplay/prototype_run.tscn")
	world = packed.instantiate() as Node2D
	world.set("auto_start", false)
	player = world.get_node("Player") as CharacterBody2D
	if not player.has_method("request_jump") or not player.has_signal("jumped") or not player.has_signal("landed"):
		print("TEST_FAILURE: fixed-jump API/signals missing")
		world.free()
		quit(1)
		return
	var falling: bool = case_name.begins_with("buffer_") or case_name == "drop_calibration"
	if falling:
		player.position.y = 480.0
	if case_name.begins_with("coyote_") or case_name == "disable_coyote":
		var ground := world.get_node("Ground") as StaticBody2D
		ground.position.x = 128.0
		var shape_node := ground.get_node("CollisionShape2D") as CollisionShape2D
		var shape := shape_node.shape.duplicate() as RectangleShape2D
		shape.size.x = 256.0
		shape_node.shape = shape
	player.connect("jumped", _on_jumped)
	player.connect("landed", _on_landed)
	root.add_child(world)
	var layer := CanvasLayer.new()
	world.add_child(layer)
	label = Label.new()
	label.position = Vector2(24, 24)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 22)
	layer.add_child(label)
	if case_name.begins_with("ui_"):
		ui = ConsumingControl.new()
		ui.position = Vector2.ZERO
		ui.size = Vector2(220, 140)
		ui.focus_mode = Control.FOCUS_ALL
		ui.mouse_filter = Control.MOUSE_FILTER_STOP
		layer.add_child(ui)
		ui.grab_focus()
	probe = Probe.new()
	probe.callback = _sample
	probe.process_physics_priority = 100
	world.add_child(probe)
	if falling:
		arm_tick = 0
		start_position = player.position
		wall_start = Time.get_ticks_usec()
		player.call("set_gameplay_enabled", true)
	between_cases = false

func _on_jumped() -> void:
	jumps.append({"tick": tick + 1, "y": player.position.y, "vy": player.velocity.y})

func _on_landed() -> void:
	landings.append({"tick": tick + 1, "y": player.position.y, "vy": player.velocity.y})

func _process(_delta: float) -> bool:
	if not between_cases and arm_tick >= 0 and case_name == "fps":
		render_frames += 1
	return false

func _request() -> void:
	requests.append({"tick": tick, "source": "request_jump"})
	player.call("request_jump")

func _space(pressed: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.physical_keycode = KEY_SPACE
	event.pressed = pressed
	event.echo = echo
	requests.append({"tick": tick, "source": "Space", "pressed": pressed, "echo": echo})
	Input.parse_input_event(event)

func _touch(index: int, pressed: bool, outside_ui: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	var logical_position: Vector2 = Vector2(80, 80) if ui != null and not outside_ui else Vector2(1100, 300)
	# Input.parse_input_event expects window pixels, before viewport stretching.
	event.position = root.get_final_transform() * logical_position
	requests.append({"tick": tick, "source": "Touch", "index": index, "pressed": pressed})
	Input.parse_input_event(event)

func _drag() -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = root.get_final_transform() * Vector2(1110, 300)
	event.relative = Vector2(10, 0)
	Input.parse_input_event(event)

func _sample(delta: float) -> void:
	if between_cases:
		return
	tick += 1
	var floor_now: bool = player.is_on_floor()
	trace.append({"tick": tick, "x": player.position.x, "y": player.position.y, "vy": player.velocity.y, "vx": player.velocity.x, "floor": floor_now, "jumps": jumps.size()})
	label.text = "JUMP TEST %s | %s | tick=%d x=%.2f y=%.2f vy=%.2f" % [case_name, capture_stage, tick, player.position.x, player.position.y, player.velocity.y]
	if arm_tick < 0:
		if tick >= 30 and floor_now:
			arm_tick = tick
			start_position = player.position
			initial_y = player.position.y
			wall_start = Time.get_ticks_usec()
			render_frames = 0
			if case_name != "disabled_input":
				player.call("set_gameplay_enabled", true)
		elif tick > 180:
			print("TEST_FAILURE: could not settle")
			quit(1)
		previous_floor = floor_now
		return
	simulation_seconds += delta
	var age: int = tick - arm_tick
	var first_jump: int = int(jumps[0]["tick"]) if not jumps.is_empty() else -10000
	if previous_floor and not floor_now and jumps.is_empty() and leave_tick < 0:
		leave_tick = tick
	previous_floor = floor_now
	if case_name == "drop_calibration":
		if floor_now:
			drop_ticks = tick
			_finish_case()
		return
	if case_name.begins_with("buffer_"):
		var before: int = 7 if case_name in ["buffer_7", "buffer_echo_expired", "buffer_touch_expired"] else (6 if case_name == "buffer_exact6" else 5)
		if tick == drop_ticks - before:
			if case_name == "buffer_echo_expired":
				_space(true)
			elif case_name == "buffer_touch_expired":
				_touch(0, true)
			else:
				_request()
		if case_name == "buffer_multi" and tick == drop_ticks - 4:
			_request()
		if tick > drop_ticks - before and tick < drop_ticks + 20:
			if case_name == "buffer_echo_expired":
				_space(true, true)
			elif case_name == "buffer_touch_expired":
				_touch(0, true)
		if case_name == "buffer_disable_latch" and tick == drop_ticks:
			player.call("set_gameplay_enabled", false)
			player.call("set_gameplay_enabled", true)
		if tick >= drop_ticks + 120:
			_finish_case()
		return
	if case_name.begins_with("coyote_") or case_name == "disable_coyote":
		if leave_tick > 0:
			if case_name == "disable_coyote":
				if tick == leave_tick + 1:
					player.call("set_gameplay_enabled", false)
				if tick == leave_tick + 2:
					player.call("set_gameplay_enabled", true)
					_request()
			elif tick == leave_tick + int(case_name.trim_prefix("coyote_")):
				_request()
			if tick >= leave_tick + 35:
				_finish_case()
		elif age > 120:
			print("TEST_FAILURE: edge fixture did not leave floor")
			quit(1)
		return
	if case_name == "fps":
		if age == 60:
			_space(true)
		if age == 61:
			_space(false)
		if age == 600:
			_finish_case()
		return
	if case_name == "invalid_events":
		if age == 1:
			_space(true, true)
			_space(false)
			_touch(1, false)
			_drag()
	elif case_name == "disabled_input":
		if age == 1:
			_request()
			_space(true)
			_touch(0, true)
		if age == 20:
			player.call("set_gameplay_enabled", true)
	elif case_name == "secondary_touch":
		if age == 1 or age == 2:
			_touch(0, true)
		if age == 80:
			_touch(1, true)
		if age == 82:
			_touch(0, false)
		if age == 83:
			_touch(2, true)
		if age == 85:
			_touch(1, false)
			_touch(2, false)
		if age == 90:
			_touch(3, true)
	elif case_name.begins_with("ui_"):
		if age == 1:
			if case_name == "ui_space":
				_space(true)
			else:
				_touch(0, true)
		if case_name == "ui_touch_secondary" and age == 5:
			_touch(1, true, true)
	elif age == 1:
		if case_name.begins_with("space") or case_name == "visual":
			_space(true)
		elif case_name.begins_with("touch"):
			_touch(0, true)
		else:
			_request()
	if first_jump > 0:
		if tick == first_jump + 1:
			if case_name == "space_short":
				_space(false)
			if case_name == "touch_short":
				_touch(0, false)
		if case_name == "space_hold" and tick < first_jump + 120:
			_space(true, true)
		if case_name == "space_duplicate" and tick < first_jump + 120:
			_space(true)
		if case_name == "touch_hold" and tick < first_jump + 120:
			_touch(0, true)
			_drag()
		if case_name == "double_early" and tick == first_jump + 2:
			_request()
		if case_name == "double_mid" and tick == first_jump + 12:
			_request()
		if case_name == "disable_reenable":
			if tick == first_jump + 44:
				_space(true)
				player.call("set_gameplay_enabled", false)
				_request()
			if tick == first_jump + 46:
				player.call("set_gameplay_enabled", true)
		if visual:
			if tick == first_jump:
				_capture_pause("launch")
			elif player.velocity.y >= 0.0 and not floor_now and not "apex" in captured:
				_capture_pause("apex")
			elif floor_now and not "landed" in captured:
				_capture_pause("landed")
	if age >= 180:
		_finish_case()

func _capture_pause(stage: String) -> void:
	captured.append(stage)
	capture_stage = stage
	label.text = "REAL RUNTIME CAPTURE: %s | tick=%d y=%.3f vy=%.1f" % [stage, tick, player.position.y, player.velocity.y]
	print("CAPTURE_PAUSE " + JSON.stringify({"stage": stage, "tick": tick, "x": player.position.x, "y": player.position.y, "vy": player.velocity.y, "wall_hold_seconds": 20}))
	paused = true
	create_timer(20.0, true, false, true).timeout.connect(func() -> void:
		paused = false
		capture_stage = ""
	)

func _finish_case() -> void:
	var failures: Array[String] = []
	var transitions: int = 0
	var prior_floor: bool = false
	for row: Dictionary in trace:
		var floor_value: bool = bool(row["floor"])
		if floor_value and not prior_floor:
			transitions += 1
		prior_floor = floor_value
		if int(row["tick"]) > arm_tick and case_name not in ["disabled_input", "disable_reenable", "disable_coyote"] and float(row["vx"]) != 280.0:
			failures.append("horizontal movement changed during jump")
	if landings.size() != transitions:
		failures.append("landed signal must match actual air-to-floor transitions")
	var expected_jumps: int = 1
	if case_name in ["coyote_5", "coyote_6", "disable_coyote", "drop_calibration", "buffer_disable_latch", "buffer_7", "buffer_echo_expired", "buffer_touch_expired", "invalid_events", "ui_space", "ui_touch", "ui_touch_secondary", "disabled_input"]:
		expected_jumps = 0
	elif case_name == "secondary_touch":
		expected_jumps = 2
	if jumps.size() != expected_jumps:
		failures.append("jump count %d expected %d" % [jumps.size(), expected_jumps])
	var apex_height: float = 0.0
	var flight_ticks: int = -1
	if not jumps.is_empty():
		var j: Dictionary = jumps[0]
		var min_y: float = float(j["y"])
		for row: Dictionary in trace:
			if int(row["tick"]) >= int(j["tick"]):
				min_y = minf(min_y, float(row["y"]))
		for landing: Dictionary in landings:
			if int(landing["tick"]) >= int(j["tick"]):
				flight_ticks = int(landing["tick"]) - int(j["tick"]) + 1
				break
		apex_height = float(j["y"]) - min_y
		if float(j["vy"]) != -480.0:
			failures.append("launch velocity must be -480")
		if not case_name.begins_with("coyote_"):
			if absf(apex_height - 96.0) > 8.0:
				failures.append("apex outside 96 +/-8")
			if flight_ticks < 0 or absf(float(flight_ticks) / 60.0 - 0.80) > 0.04:
				failures.append("flight outside 0.80 +/-0.04")
	if case_name in ["buffer_5", "buffer_exact6", "buffer_multi"] and not jumps.is_empty():
		if landings.is_empty() or int(jumps[0]["tick"]) - int(landings[0]["tick"]) != 1:
			failures.append("buffer must execute in next tick after landing")
	if case_name.begins_with("ui_") and ui.consumed == 0:
		failures.append("UI did not actually consume event")
	if case_name == "disable_reenable" and not jumps.is_empty():
		var first: int = int(jumps[0]["tick"])
		for row: Dictionary in trace:
			if int(row["tick"]) in [first + 45, first + 46] and float(row["vx"]) != 0.0:
				failures.append("disable did not stop horizontal speed")
	var wall_seconds: float = float(Time.get_ticks_usec() - wall_start) / 1000000.0
	var measured_fps: float = float(render_frames) / wall_seconds
	var dx: float = player.position.x - start_position.x
	if case_name == "fps":
		if DisplayServer.get_name() == "headless":
			failures.append("FPS comparison requires graphical rendering")
		if absf(measured_fps - fps_target) > fps_target * 0.1 or absf(wall_seconds - 10.0) > 1.0:
			failures.append("actual render rate/wall time does not match target")
		if absf(dx - 2800.0) > 5.0 or tick - arm_tick != 600:
			failures.append("600-tick horizontal regression failed")
	var result: Dictionary = {"case": case_name, "passed": failures.is_empty(), "failures": failures, "case_ticks": tick, "arm_tick": arm_tick, "leave_tick": leave_tick, "drop_calibration_ticks": drop_ticks, "jumps": jumps.duplicate(), "landings": landings.duplicate(), "requests": requests.duplicate(), "apex_height_px": apex_height, "flight_ticks_including_launch": flight_ticks, "flight_seconds": float(flight_ticks) / 60.0 if flight_ticks >= 0 else null, "simulation_seconds": simulation_seconds, "dx": dx, "render_frames": render_frames, "wall_seconds": wall_seconds, "fps_target": fps_target, "measured_fps": measured_fps if case_name == "fps" else null, "ui_consumed": ui.consumed if ui != null else 0, "trace": trace.duplicate()}
	results.append(result)
	var summary: Dictionary = result.duplicate()
	summary.erase("trace")
	print("CASE_RESULT " + JSON.stringify(summary))
	if not failures.is_empty():
		suite_failed = true
	between_cases = true
	world.queue_free()
	call_deferred("_start_case")

func _complete() -> void:
	var result: Dictionary = {"passed": not suite_failed, "physics_hz": Engine.physics_ticks_per_second, "results": results, "touch_hardware": "NOT RUN; InputEvent injection only", "visual_pauses": visual, "visual_pause_wall_seconds": 20 if visual else 0}
	if not output_path.is_empty():
		var file := FileAccess.open(output_path, FileAccess.WRITE)
		if file == null:
			print("TEST_FAILURE: cannot write output")
			quit(1)
			return
		file.store_string(JSON.stringify(result, "\t") + "\n")
	print("JUMP_SUITE " + JSON.stringify({"passed": not suite_failed, "case_count": results.size(), "physics_hz": Engine.physics_ticks_per_second}))
	quit(1 if suite_failed else 0)
