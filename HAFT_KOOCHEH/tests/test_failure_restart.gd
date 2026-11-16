extends SceneTree

const PlayerController = preload("res://scripts/player/player_controller.gd")
const LevelController = preload("res://scripts/gameplay/level_controller.gd")
const Hazard = preload("res://scripts/obstacles/hazard.gd")
class Probe extends Node:
	signal sampled
	var callback: Callable
	func _physics_process(_delta: float) -> void:
		callback.call()
		sampled.emit()

class EarlyProducer extends Node:
	signal produced
	var callback: Callable
	func _physics_process(_delta: float) -> void:
		callback.call()
		set_physics_process(false)
		produced.emit()

var probe: Probe
var level: LevelController
var player: PlayerController
var counts: Dictionary = {}
var trace: Array[Dictionary] = []
var results: Array[Dictionary] = []
var failures: Array[String] = []
var tick: int = 0
var output: String = ""
var visual: bool = false
var capture_only: String = ""
var label: Label
var current_case: String = ""
var signal_log: Array[Dictionary] = []
var hold_seconds: float = 40.0

func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
		elif arg.begins_with("--capture-only="):
			capture_only = arg.trim_prefix("--capture-only=")
		elif arg == "--visual":
			visual = true
	call_deferred("_run")

func _sample() -> void:
	tick += 1
	if is_instance_valid(level) and is_instance_valid(level.active_player):
		var p: PlayerController = level.active_player
		var normals: Array = []
		for index: int in p.get_slide_collision_count():
			var normal: Vector2 = p.get_slide_collision(index).get_normal()
			normals.append([normal.x, normal.y])
		trace.append({"tick": tick, "engine_tick": Engine.get_physics_frames(), "attempt": level.attempt_id, "x": p.global_position.x, "y": p.global_position.y, "vx": p.velocity.x, "vy": p.velocity.y, "collision_normals": normals, "floor": p.is_on_floor(), "ceiling": p.is_on_ceiling(), "motion": p.motion_state, "state": level.run_state, "reason": level.failure_reason, "signals": counts.duplicate()})

func _steps(n: int) -> void:
	for i: int in n:
		await probe.sampled

func _until_failed(max_ticks: int = 260) -> void:
	for i: int in max_ticks:
		if level.run_state == &"FAILED":
			return
		await _steps(1)
	_check(false, "failure timeout")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _count(name: String) -> void:
	counts[name] = int(counts.get(name, 0)) + 1
	signal_log.append({"signal": name, "engine_tick": Engine.get_physics_frames(), "attempt": level.attempt_id, "state": level.run_state, "reason": level.failure_reason})

func _bind_player() -> void:
	player = level.active_player
	for name: String in ["jumped", "landed", "blocked", "out_of_bounds"]:
		player.connect(name, _count.bind(name))
	for node: Node in level.world.find_children("*", "Area2D", true, false):
		if node is Hazard:
			node.hazard_contact.connect(func(_id: StringName, _reason: StringName) -> void: _count("hazard_contact"))

func _setup(name: String) -> void:
	current_case = name
	counts = {}
	trace = []
	signal_log = []
	failures = []
	tick = 0
	var packed: PackedScene = load("res://scenes/gameplay/failure_prototype.tscn")
	level = packed.instantiate() as LevelController
	level.auto_start = false
	paused = true # Inspect spawn before the first physics step, not after gravity.
	root.add_child.call_deferred(level)
	await process_frame
	while not is_instance_valid(level.active_player):
		await process_frame
	_bind_player()
	level.run_failed.connect(func(_reason: StringName) -> void: _count("run_failed"))
	_check(level.process_physics_priority == -100 and player.process_physics_priority == 0, "physics order")
	_check(player.motion_state == PlayerController.MotionState.DISABLED, "fresh player must be DISABLED")
	_check(player.global_position == (level.world.get_node("Start") as Marker2D).global_position, "fresh start")
	_check(player.collision_layer == 2 and player.collision_mask == 1, "player layers")
	for name_world: String in ["Ground", "GroundAfterGap", "Wall"]:
		var body := level.world.get_node(name_world) as StaticBody2D
		_check(body.collision_layer == 1 and body.collision_mask == 2, "world layers")
	for name_area: String in ["Hazard", "KillZone"]:
		var area := level.world.get_node(name_area) as Area2D
		_check(area.collision_layer == 4 and area.collision_mask == 2, "hazard layers")
	_check(level.kill_y - 600.0 >= 160.0, "kill_y clearance")
	paused = false
	await _steps(30)
	_check(player.is_on_floor(), "initial settlement")

func _start() -> void:
	_check(level.start_run(), "start_run must succeed after floor settlement")

func _clean_lane() -> void:
	(level.world.get_node("Wall") as Node2D).position.x = 5000.0
	(level.world.get_node("Hazard") as Node2D).position.x = 5000.0

func _finish() -> void:
	var result: Dictionary = {"case": current_case, "passed": failures.is_empty(), "failures": failures.duplicate(), "ticks": tick, "attempt": level.attempt_id, "kill_y": level.kill_y, "lowest_safe_surface_y": 600.0, "state": level.run_state, "reason": level.failure_reason, "counts": counts.duplicate(), "signals": signal_log.duplicate(), "trace": trace.duplicate()}
	results.append(result)
	var summary: Dictionary = result.duplicate()
	summary.erase("trace")
	print("FAILURE_CASE " + JSON.stringify(summary))
	level.queue_free()
	level = null
	player = null
	await process_frame

func _assert_failed(reason: StringName) -> void:
	_check(level.run_state == &"FAILED" and level.failure_reason == reason, "failure reason/state")
	_check(int(counts.get("run_failed", 0)) == 1, "exactly one run_failed")
	_check(player.motion_state == PlayerController.MotionState.DEAD and player.velocity == Vector2.ZERO, "DEAD/frozen")

func _snapshot(stage: String) -> void:
	if not visual or (not capture_only.is_empty() and stage != capture_only):
		return
	# Flush the physical frame before pausing capture, including follow-camera scroll.
	for node: Node in level.world.find_children("*", "Node2D", true, false):
		(node as Node2D).force_update_transform()
	(player.get_node("Camera2D") as Camera2D).force_update_scroll()
	label.text = "REAL RUNTIME | %s | %s | attempt=%d | %s\nPlayer x=%.2f y=%.2f vx=%.1f vy=%.1f" % [stage, level.run_state, level.attempt_id, level.failure_reason, player.global_position.x, player.global_position.y, player.velocity.x, player.velocity.y]
	print("CAPTURE_PAUSE ", JSON.stringify({"stage": stage, "state": level.run_state, "reason": level.failure_reason, "attempt": level.attempt_id, "tick": tick, "x": player.global_position.x, "y": player.global_position.y, "wall_hold_seconds": hold_seconds}))
	paused = true
	await create_timer(hold_seconds, true, false, true).timeout
	paused = false

func _run() -> void:
	probe = Probe.new()
	probe.callback = _sample
	probe.process_physics_priority = 100
	root.add_child(probe)
	if visual:
		var layer := CanvasLayer.new()
		root.add_child(layer)
		label = Label.new()
		label.position = Vector2(24, 24)
		label.add_theme_font_size_override("font_size", 24)
		layer.add_child(label)
	# Actual wall contact and next-tick arbitration; freeze ignores all late input.
	await _setup("wall_freeze_late_input")
	_start()
	await _until_failed()
	_assert_failed(&"wall")
	_check(int(counts.get("blocked", 0)) == 1, "one blocked")
	await _snapshot("wall_failed")
	var frozen: Vector2 = player.global_position
	var old_signals: Dictionary = counts.duplicate()
	player.set_gameplay_enabled(true)
	player.configure(Vector2.ZERO, -100.0)
	player.request_jump()
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	Input.parse_input_event(key)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	Input.parse_input_event(touch)
	await _steps(20)
	_check(player.global_position == frozen and player.velocity == Vector2.ZERO, "freeze position/velocity")
	_check(player.get("_buffer_until") == -INF and player.get("_coyote_until") == -INF and not player.get("_landing_request_latched"), "freeze clears jump timers")
	_check(counts == old_signals, "no DEAD signals")
	key.pressed = false
	touch.pressed = false
	Input.parse_input_event(key)
	Input.parse_input_event(touch)
	await _finish()
	# Landing on the floor and a low ceiling are safe; jump behavior preserved.
	await _setup("safe_landing_and_ceiling")
	_clean_lane()
	_start()
	player.request_jump()
	await _steps(55)
	_check(level.run_state == &"RUNNING" and player.is_on_floor(), "safe landing")
	_check(int(counts.get("jumped", 0)) == 1 and int(counts.get("landed", 0)) == 2, "safe landing signals")
	var ceiling := StaticBody2D.new()
	ceiling.collision_layer = 1
	ceiling.collision_mask = 2
	ceiling.position = player.position + Vector2(90, -90)
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(500, 20)
	collider.shape = shape
	ceiling.add_child(collider)
	level.world.add_child.call_deferred(ceiling)
	await _steps(2)
	player.request_jump()
	await _steps(40)
	_check(level.run_state == &"RUNNING" and int(counts.get("blocked", 0)) == 0, "ceiling not failure")
	_check(trace.any(func(row: Dictionary) -> bool: return row["ceiling"]), "ceiling actually stops upward motion")
	await _finish()
	for scenario: String in ["hazard_side", "hazard_top", "killzone"]:
		await _setup(scenario)
		_clean_lane()
		var hazard: Hazard = level.world.get_node("KillZone" if scenario == "killzone" else "Hazard") as Hazard
		if scenario == "hazard_side":
			hazard.position = Vector2(350, 576)
		elif scenario == "hazard_top":
			hazard.position = Vector2(340, 440)
		else:
			hazard.position = Vector2(350, 576)
		_start()
		if scenario == "hazard_top":
			player.global_position = Vector2(260, 320)
			player.velocity.y = 100.0
		await _until_failed()
		_assert_failed(&"fall" if scenario == "killzone" else &"hazard")
		_check(int(counts.get("hazard_contact", 0)) == 1, "one actual Area contact")
		if scenario == "hazard_side":
			await _snapshot(scenario)
		await _finish()
	# Strict global threshold, equal and lower use zero speed/gravity to isolate >.
	for offset: float in [-0.25, 0.0, 0.25]:
		await _setup("kill_y_" + str(offset))
		_clean_lane()
		_start()
		player.run_speed = 0.0
		player.gravity = 0.0
		player.velocity = Vector2.ZERO
		player.global_position = Vector2(1200, level.kill_y + offset)
		await _steps(5)
		if offset > 0.0:
			_assert_failed(&"fall")
			_check(int(counts.get("out_of_bounds", 0)) == 1, "one strict bounds event")
		else:
			_check(level.run_state == &"RUNNING" and int(counts.get("out_of_bounds", 0)) == 0, "equality is inside")
		await _finish()
	# Real gap fall through kill_y; KillZone moved away so this is not an Area test.
	await _setup("natural_fall")
	_clean_lane()
	(level.world.get_node("KillZone") as Node2D).position.x = 5000.0
	_start()
	await _until_failed(350)
	_assert_failed(&"fall")
	_check(int(counts.get("out_of_bounds", 0)) == 1, "natural fall bounds")
	await _snapshot("fall_failed")
	await _finish()
	# Both order permutations prove priority independent of callback order.
	for order: Array in [[&"wall", &"hazard", &"fall"], [&"fall", &"hazard", &"wall"], [&"wall", &"hazard"]]:
		await _setup("priority_" + str(order))
		_start()
		var before: Vector2 = player.global_position
		for reason: StringName in order:
			_check(level.queue_failure(reason, player, level.attempt_id), "valid queue")
		_check(level.run_state == &"RUNNING", "callback must only enqueue")
		await _steps(1)
		_assert_failed(&"fall" if &"fall" in order else &"hazard")
		_check(player.global_position == before, "adjudicate before next player motion")
		await _finish()
	await _setup("early_callback_next_tick")
	_start()
	var producer := EarlyProducer.new()
	producer.process_physics_priority = -200
	producer.callback = func() -> void:
		level.queue_failure(&"hazard", player, level.attempt_id)
		level.queue_failure(&"wall", player, level.attempt_id)
	var position_before_event: Vector2 = player.global_position
	level.add_child.call_deferred(producer)
	await producer.produced
	await _steps(1)
	_check(level.run_state == &"RUNNING", "same-frame early event must wait")
	var position_after_event: Vector2 = player.global_position
	_check(position_after_event.x > position_before_event.x, "event frame moves normally")
	await _steps(1)
	_assert_failed(&"hazard")
	_check(player.global_position == position_after_event, "next frame freezes before motion")
	await _finish()
	# Identity, stale callback (including freed Player), non-Player and complete restart.
	await _setup("identity_and_full_restart")
	_start()
	var hazard: Hazard = level.world.get_node("Hazard") as Hazard
	var alien := Node2D.new()
	root.add_child.call_deferred(alien)
	await _steps(1)
	_check(not hazard.report_contact(alien, level.attempt_id), "non-Player rejected")
	_check(not hazard.report_contact(player, level.attempt_id - 1), "wrong attempt at Hazard")
	_check(not level.queue_failure(&"fall", player, level.attempt_id - 1), "wrong attempt at Level")
	var old_player: WeakRef = weakref(player)
	var old_world: WeakRef = weakref(level.world)
	var old_hazard: WeakRef = weakref(hazard)
	var old_attempt: int = level.attempt_id
	var late: Callable = level._on_hazard_contact.bind(old_player, old_attempt)
	player.request_jump()
	level.queue_failure(&"wall", player, level.attempt_id)
	await _steps(1)
	_assert_failed(&"wall")
	hazard.position = Vector2(42, 42)
	level.restart_run()
	level.restart_run() # Coalesced; one fresh attempt, not two worlds.
	await process_frame
	while level.attempt_id == old_attempt:
		await process_frame
	_bind_player()
	_check(old_player.get_ref() == null and old_world.get_ref() == null and old_hazard.get_ref() == null, "old world freed")
	_check(level.attempt_id == old_attempt + 1, "one increment")
	_check(player.motion_state == PlayerController.MotionState.DISABLED and player.global_position == Vector2(160, 550), "fresh disabled/start")
	_check(player.get("_buffer_until") == -INF and player.get("_coyote_until") == -INF, "fresh timers")
	_check((level.world.get_node("Hazard") as Node2D).position == Vector2(950, 576), "hazard restored")
	late.call(&"old_hazard", &"fall")
	await _steps(30)
	_start()
	late.call(&"old_hazard", &"fall")
	await _steps(2)
	_check(level.run_state == &"RUNNING", "freed prior callback rejected")
	player.request_jump()
	await _steps(1)
	_check(player.velocity.y == -480.0, "fresh jump ready")
	await _snapshot("restarted_running")
	alien.queue_free()
	await _finish()
	await _setup("ten_consecutive_restarts")
	for cycle: int in 10:
		if not player.is_on_floor():
			await _steps(30)
		_start()
		var attempt: int = level.attempt_id
		var old: WeakRef = weakref(player)
		var old_world_ref: WeakRef = weakref(level.world)
		var failed_before: int = int(counts.get("run_failed", 0))
		level.queue_failure(&"hazard", player, attempt)
		await _steps(1)
		_check(level.run_state == &"FAILED" and int(counts.get("run_failed", 0)) == failed_before + 1, "one failure per cycle")
		level.restart_run()
		await process_frame
		while level.attempt_id == attempt:
			await process_frame
		_bind_player()
		_check(level.attempt_id == attempt + 1 and old.get_ref() == null and old_world_ref.get_ref() == null, "new instance each restart")
		_check(level.get_child_count() == 1 and level.world.find_children("Player", "CharacterBody2D", true, false).size() == 1, "one world/player")
		_check(player.get_signal_connection_list("blocked").size() == 2, "no callback accumulation")
	_check(level.attempt_id == 11 and int(counts.get("run_failed", 0)) == 10, "ten new attempts/ten failures")
	await _finish()
	# Re-arm collision edge signals without a Level to verify per-contact semantics.
	await _setup("contact_signal_rearm")
	# Remove only Level's callback using actual connection list; keep test observer.
	for connection: Dictionary in player.get_signal_connection_list("blocked"):
		if connection["callable"].get_object() == level:
			player.disconnect("blocked", connection["callable"])
	_start()
	await _steps(130)
	_check(int(counts.get("blocked", 0)) == 1, "wall held contact deduplicates")
	player.global_position.x = 400.0
	await _steps(60)
	_check(int(counts.get("blocked", 0)) == 2, "wall contact rearms after separation")
	player.global_position = Vector2(1020, 600)
	await _steps(1)
	player.request_jump()
	_check(player.get("_coyote_until") > player.get("_simulation_time") and player.get("_buffer_until") > player.get("_simulation_time"), "prime real edge Coyote and pending Buffer")
	player.freeze_on_failure()
	_check(player.get("_coyote_until") == -INF and player.get("_buffer_until") == -INF and player.velocity == Vector2.ZERO, "freeze clears populated timers")
	await _finish()
	# Main loaded through real scene switch, with paused tree cleared.
	await _setup("exit_menu_unpauses")
	_start()
	level.queue_failure(&"wall", player, level.attempt_id)
	await _steps(1)
	_assert_failed(&"wall")
	var previous: WeakRef = weakref(level)
	current_scene = level
	paused = true
	level.exit_to_menu()
	_check(not paused, "exit clears pause synchronously")
	await process_frame
	await process_frame
	_check(is_instance_valid(current_scene) and current_scene.scene_file_path == "res://scenes/app/main.tscn", "real Main loaded")
	_check(previous.get_ref() == null, "old Level freed on menu")
	results.append({"case": current_case, "passed": failures.is_empty(), "failures": failures.duplicate(), "trace": trace.duplicate(), "signals": signal_log.duplicate(), "counts": counts.duplicate()})
	var passed: bool = results.all(func(row: Dictionary) -> bool: return row["passed"])
	var result: Dictionary = {"passed": passed, "physics_hz": Engine.physics_ticks_per_second, "case_count": results.size(), "visual": visual, "capture_only": capture_only, "visual_capture_pause_seconds": hold_seconds if visual else 0, "results": results}
	if not output.is_empty():
		var file := FileAccess.open(output, FileAccess.WRITE)
		if file == null:
			push_error("Cannot write failure test output")
			quit(1)
			return
		file.store_string(JSON.stringify(result, "\t") + "\n")
	print("FAILURE_SUITE ", JSON.stringify({"passed": passed, "case_count": results.size(), "physics_hz": Engine.physics_ticks_per_second}))
	quit(0 if passed else 1)
