extends SceneTree

const LevelController = preload("res://scripts/gameplay/level_controller.gd")
const PlayerController = preload("res://scripts/player/player_controller.gd")
const Coin = preload("res://scripts/gameplay/coin.gd")
const ScoreManager = preload("res://scripts/systems/score_manager.gd")
const Hazard = preload("res://scripts/obstacles/hazard.gd")
class Probe extends Node:
	signal sampled
	var callback: Callable
	func _physics_process(_delta: float) -> void:
		callback.call()
		sampled.emit()

var probe: Probe
var level: LevelController
var player: PlayerController
var score: ScoreManager
var counts: Dictionary = {}
var events: Array[Dictionary] = []
var trace: Array[Dictionary] = []
var failures: Array[String] = []
var results: Array[Dictionary] = []
var tick: int = 0
var case_name: String = ""
var output: String = ""
var visual: bool = false
var capture_only: String = ""
var fps_target: float = 0.0
var frames: int = 0
var measuring: bool = false
var label: Label

func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
		elif arg == "--visual":
			visual = true
		elif arg.begins_with("--capture-only="):
			capture_only = arg.trim_prefix("--capture-only=")
		elif arg.begins_with("--fps-target="):
			fps_target = float(arg.trim_prefix("--fps-target="))
	call_deferred("_run")

func _process(_delta: float) -> bool:
	if measuring:
		frames += 1
	return false

func _sample() -> void:
	tick += 1
	if is_instance_valid(level) and is_instance_valid(level.active_player):
		var p: PlayerController = level.active_player
		trace.append({"tick": tick, "engine_tick": Engine.get_physics_frames(), "attempt": level.attempt_id, "x": p.global_position.x, "y": p.global_position.y, "vx": p.velocity.x, "vy": p.velocity.y, "state": level.run_state, "reason": level.failure_reason, "score": score.score, "coins": score.coins_collected})

func _steps(n: int) -> void:
	for i: int in n:
		await probe.sampled

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _event(name: String, id: StringName = &"") -> void:
	counts[name] = int(counts.get(name, 0)) + 1
	events.append({"event": name, "id": id, "tick": tick, "engine_tick": Engine.get_physics_frames(), "attempt": level.attempt_id, "score": score.score, "coins": score.coins_collected, "state": level.run_state})

func _coin(index: int) -> Coin:
	return level.world.get_node("Coin%d" % index) as Coin

func _bind_coins() -> void:
	player = level.active_player
	for index: int in range(1, 4):
		var c: Coin = _coin(index)
		c.pickup_requested.connect(func(id: StringName) -> void: _event("pickup", id))
		_check(c.collision_layer == 8 and c.collision_mask == 2 and c.monitoring, "coin layers/monitoring")
		_check(not c.pending and not c.collected and (c.get_node("Visual") as Polygon2D).visible, "fresh coin")

func _setup(name: String, layout: String = "normal") -> void:
	case_name = name
	counts = {}
	events = []
	trace = []
	failures = []
	tick = 0
	paused = true
	level = (load("res://scenes/gameplay/coin_score_prototype.tscn") as PackedScene).instantiate() as LevelController
	level.auto_start = false
	if layout != "normal":
		var world := level.world_scene.instantiate() as Node2D
		if layout == "duplicate":
			(world.get_node("Coin2") as Coin).coin_id = (world.get_node("Coin1") as Coin).coin_id
		elif layout == "empty":
			(world.get_node("Coin1") as Coin).coin_id = &""
		elif layout == "overlap":
			(world.get_node("Hazard") as Hazard).position = (world.get_node("Coin1") as Coin).position
		var packed := PackedScene.new()
		_check(packed.pack(world) == OK, "fixture pack")
		world.free()
		level.world_scene = packed
	score = level.get_node("ScoreManager") as ScoreManager
	score.score_changed.connect(func(_score: int, _coins: int) -> void: _event("score_changed"))
	root.add_child.call_deferred(level)
	await process_frame
	while not is_instance_valid(level.active_player):
		await process_frame
	_bind_coins()
	if layout == "overlap":
		# An internal subscene override is not retained by pack(); set the live fixture before physics.
		var shape := RectangleShape2D.new()
		shape.size = Vector2(32, 32)
		(level.world.get_node("Hazard/CollisionShape2D") as CollisionShape2D).shape = shape
		_check((level.world.get_node("Hazard/CollisionShape2D") as CollisionShape2D).shape.size == (_coin(1).get_node("CollisionShape2D") as CollisionShape2D).shape.size, "actual overlapping shapes identical")
	level.run_failed.connect(func(_reason: StringName) -> void: _event("failed"))
	(level.world.get_node("Hazard") as Hazard).hazard_contact.connect(func(id: StringName, _reason: StringName) -> void: _event("hazard", id))
	_check(score.get_parent() == level and score.score == 0 and score.coins_collected == 0, "score ownership/reset")
	_check(int(counts.get("score_changed", 0)) == 1, "one initial reset")
	paused = false
	await _steps(30)

func _start() -> void:
	_check(level.start_run(), "start_run")

func _wait_score(target: int, max_ticks: int = 200) -> void:
	for i: int in max_ticks:
		if score.score >= target:
			return
		await _steps(1)
	_check(false, "score timeout")

func _restart() -> void:
	var previous: int = level.attempt_id
	paused = true
	level.restart_run()
	await process_frame
	while level.attempt_id == previous:
		await process_frame
	_bind_coins()
	_check(player.motion_state == PlayerController.MotionState.DISABLED and player.global_position == Vector2(160, 550), "fresh disabled player at Start")
	_check(score.score == 0 and score.coins_collected == 0, "restart score reset")
	paused = false
	await _steps(30)

func _snapshot(stage: String) -> void:
	if not visual or (not capture_only.is_empty() and capture_only != stage):
		return
	for node: Node in level.world.find_children("*", "Node2D", true, false):
		(node as Node2D).force_update_transform()
	(player.get_node("Camera2D") as Camera2D).force_update_scroll()
	var c: Coin = _coin(1)
	label.text = "REAL RUNTIME | %s | attempt=%d | %s\nscore=%d coins=%d | Coin1 pending=%s collected=%s | x=%.2f" % [stage, level.attempt_id, level.run_state, score.score, score.coins_collected, c.pending, c.collected, player.global_position.x]
	print("CAPTURE_PAUSE ", JSON.stringify({"stage": stage, "tick": tick, "attempt": level.attempt_id, "score": score.score, "coins": score.coins_collected, "pending": c.pending, "collected": c.collected, "x": player.global_position.x, "wall_hold_seconds": 35}))
	paused = true
	await create_timer(35.0, true, false, true).timeout
	paused = false

func _finish(extra: Dictionary = {}) -> void:
	var result: Dictionary = {"case": case_name, "passed": failures.is_empty(), "failures": failures.duplicate(), "counts": counts.duplicate(), "events": events.duplicate(), "trace": trace.duplicate(), "attempt": level.attempt_id, "score": score.score, "coins": score.coins_collected, "extra": extra}
	results.append(result)
	var summary: Dictionary = result.duplicate()
	summary.erase("trace")
	print("COIN_CASE ", JSON.stringify(summary))
	level.queue_free()
	level = null
	player = null
	score = null
	await process_frame

func _run() -> void:
	probe = Probe.new()
	probe.callback = _sample
	probe.process_physics_priority = 100
	root.add_child(probe)
	if visual:
		var layer := CanvasLayer.new()
		layer.layer = 100
		root.add_child(layer)
		label = Label.new()
		label.position = Vector2(24, 110)
		label.add_theme_font_size_override("font_size", 22)
		layer.add_child(label)
	if fps_target > 0.0:
		await _setup("fps")
		(level.world.get_node("Hazard") as Hazard).position.x = 5000
		_start()
		frames = 0
		measuring = true
		var start_tick: int = tick
		var started: int = Time.get_ticks_usec()
		await _steps(600)
		measuring = false
		var wall_seconds: float = float(Time.get_ticks_usec() - started) / 1000000.0
		var actual_fps: float = frames / wall_seconds
		_check(DisplayServer.get_name() != "headless", "real FPS needs graphical renderer")
		_check(absf(actual_fps - fps_target) <= fps_target * 0.1 and absf(wall_seconds - 10.0) <= 1.0, "actual FPS/time")
		_check(tick - start_tick == 600 and Engine.physics_ticks_per_second == 60, "600physics ticks/60Hz")
		_check(score.score == 30 and score.coins_collected == 3 and int(counts.get("pickup", 0)) == 3, "FPS score result")
		await _finish({"actual_fps": actual_fps, "fps_target": fps_target, "frames": frames, "wall_seconds": wall_seconds, "physics_ticks": 600, "simulation_seconds": 10.0, "input_sequence": "start_run after30settle ticks; no Jump or Restart input"})
		_complete()
		return
	await _setup("normal_duplicate_contact_and_visual")
	await _snapshot("before_contact")
	_start()
	for i: int in 90:
		if _coin(1).pending:
			break
		await _steps(1)
	_check(_coin(1).pending and not _coin(1).collected and score.score == 0, "real contact remains pending before arbitration")
	_coin(1).body_entered.emit(player)
	_coin(1).body_entered.emit(player)
	_check(int(counts.get("pickup", 0)) == 1, "pending contact emits once")
	await _snapshot("contact_pending")
	await _wait_score(10)
	await process_frame
	_check(_coin(1).collected and not _coin(1).pending and not _coin(1).monitoring, "confirmed coin disabled")
	_check((_coin(1).get_node("CollisionShape2D") as CollisionShape2D).disabled and not (_coin(1).get_node("Visual") as Polygon2D).visible, "deferred collider/visual")
	_coin(1).body_entered.emit(player)
	_check(score.score == 10 and score.coins_collected == 1 and int(counts.get("pickup", 0)) == 1, "repeat collected contact ignored")
	await _snapshot("coin_collected")
	await _steps(2)
	await _snapshot("score_increased")
	await _restart()
	await _snapshot("restart_coins_restored")
	await _finish()
	if visual:
		_complete()
		return
	await _setup("score_api_dedupe_invalid_snapshots")
	_check(score.record_coin(&"unit_coin_a"), "new ID accepted")
	_check(not score.record_coin(&"unit_coin_a"), "duplicate rejected")
	for invalid: StringName in [&"", &"bad id", &"123coin", &"coin-1"]:
		_check(not score.record_coin(invalid) and score.last_rejection == &"invalid_coin_id", "invalid ID diagnostic")
	_check(score.score == 10 and score.coins_collected == 1 and int(counts.get("score_changed", 0)) == 2, "invalid/duplicate do not score/signal")
	for completed: bool in [false, true]:
		var snapshot: Dictionary = score.build_result(completed)
		var keys: Array = snapshot.keys()
		keys.sort()
		_check(keys == ["coins", "completed", "level_id", "score"], "exact snapshot keys")
		_check(typeof(snapshot["level_id"]) == TYPE_STRING and typeof(snapshot["score"]) == TYPE_INT and typeof(snapshot["coins"]) == TYPE_INT and typeof(snapshot["completed"]) == TYPE_BOOL, "snapshot types")
		_check(snapshot == {"level_id": String(level.level_id), "score": 10, "coins": 1, "completed": completed}, "snapshot values")
		snapshot["score"] = -999
		_check(score.score == 10, "snapshot independent")
	await _finish()
	await _setup("three_real_coins")
	_start()
	await _wait_score(30)
	_check(score.coins_collected == 3 and int(counts.get("pickup", 0)) == 3 and int(counts.get("score_changed", 0)) == 4, "three unique pickups")
	for index: int in range(1, 4):
		_check(_coin(index).collected, "all three confirmed")
	await _finish()
	for layout: String in ["duplicate", "empty"]:
		await _setup("invalid_layout_" + layout, layout)
		_check(not level.layout_error.is_empty() and not level.start_run(), "invalid layout prevents start")
		_check(score.score == 0 and level.run_state == &"READY", "invalid layout safe")
		await _finish()
	for coin_first: bool in [true, false]:
		await _setup("arbitration_coin_first" if coin_first else "arbitration_hazard_first")
		_start()
		var hazard := level.world.get_node("Hazard") as Hazard
		if coin_first:
			_coin(1).request_pickup(player, level.attempt_id)
			hazard.report_contact(player, level.attempt_id)
		else:
			hazard.report_contact(player, level.attempt_id)
			_coin(1).request_pickup(player, level.attempt_id)
		_check(score.score == 0 and level.run_state == &"RUNNING", "callbacks only enqueue")
		await _steps(1)
		_check(level.run_state == &"FAILED" and player.motion_state == PlayerController.MotionState.DEAD and int(counts.get("failed", 0)) == 1, "failure wins once")
		_check(score.score == 0 and not _coin(1).collected and not _coin(1).pending and _coin(1).monitoring, "no coin confirmation on failure")
		await _finish()
	await _setup("real_simultaneous_contact", "overlap")
	_start()
	for i: int in 120:
		if level.run_state == &"FAILED":
			break
		await _steps(1)
	var contact_frames: Array[int] = []
	for event: Dictionary in events:
		if event["event"] in ["pickup", "hazard"]:
			contact_frames.append(event["engine_tick"])
	_check(contact_frames.size() == 2 and contact_frames[0] == contact_frames[1], "real Area callbacks share physics frame")
	_check(score.score == 0 and not _coin(1).collected and level.run_state == &"FAILED", "physical failure/coin arbitration")
	await _finish()
	await _setup("identity_states_and_old_attempt")
	_check(not _coin(1).request_pickup(player, level.attempt_id), "READY rejects")
	_start()
	# Isolate Level guards while Player identity, pending and RUNNING remain valid.
	for state: StringName in [&"READY", &"FAILED"]:
		level.run_state = state
		_coin(1).pending = true
		_check(not level.queue_pickup(_coin(1).coin_id, _coin(1), player, level.attempt_id), "isolated Level state guard")
		_coin(1).reject_pickup()
	level.run_state = &"RUNNING"
	var other: PlayerController = (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerController
	_check(not _coin(1).request_pickup(other, level.attempt_id), "wrong player")
	other.free()
	_check(not _coin(1).request_pickup(player, level.attempt_id - 1), "wrong attempt")
	var external: Coin = (load("res://scenes/collectibles/coin.tscn") as PackedScene).instantiate() as Coin
	external.coin_id = _coin(1).coin_id
	external.configure(player, level.attempt_id)
	root.add_child.call_deferred(external)
	await process_frame
	external.request_pickup(player, level.attempt_id)
	_check(not level.queue_pickup(external.coin_id, external, player, level.attempt_id), "external World rejected")
	external.queue_free()
	var old_player: WeakRef = weakref(player)
	var old_coin: WeakRef = weakref(_coin(1))
	var old_world: WeakRef = weakref(level.world)
	var old_attempt: int = level.attempt_id
	var late: Callable = level._on_pickup_requested.bind(old_coin, old_player, old_attempt)
	await _restart()
	_start()
	late.call(&"bazaar_01_coin_001")
	_check(not level.queue_pickup(_coin(1).coin_id, _coin(1), player, old_attempt), "old attempt rejected on fresh coin")
	await _steps(2)
	_check(old_player.get_ref() == null and old_coin.get_ref() == null and old_world.get_ref() == null and score.score == 0, "old instances freed/no score")
	level.queue_failure(&"wall", player, level.attempt_id)
	await _steps(1)
	_check(not _coin(1).request_pickup(player, level.attempt_id) and not level.queue_pickup(_coin(1).coin_id, _coin(1), player, level.attempt_id), "FAILED rejects")
	await _finish()
	await _setup("duplicate_queued_event_and_rejection")
	_start()
	_coin(1).request_pickup(player, level.attempt_id)
	level._on_pickup_requested(_coin(1).coin_id, weakref(_coin(1)), weakref(player), level.attempt_id)
	await _steps(1)
	_check(score.score == 10 and score.coins_collected == 1, "duplicate queued event cannot rescore")
	_coin(2).request_pickup(player, level.attempt_id)
	_coin(2).coin_id = &"mutated_source_id"
	await _steps(1)
	_check(score.score == 10 and not _coin(2).pending and not _coin(2).collected, "changed source safely rejected")
	await _finish()
	await _setup("kill_y_score_reset_after_failure")
	_start()
	await _wait_score(20)
	player.run_speed = 0.0
	player.gravity = 0.0
	player.velocity = Vector2.ZERO
	player.global_position = Vector2(1200, level.kill_y)
	await _steps(2)
	_check(level.run_state == &"RUNNING" and score.score == 20, "kill_y equality preserves score/run")
	player.global_position.y = level.kill_y + 0.25
	await _steps(2)
	_check(level.run_state == &"FAILED" and level.failure_reason == &"fall" and score.score == 20 and int(counts.get("failed", 0)) == 1, "kill_y crossing fails once without erasing earned score")
	await _restart()
	_check(score.score == 0 and score.coins_collected == 0 and player.run_speed == 280.0 and player.gravity == 1200.0, "FAILED restart restores score and fresh prototype parameters")
	await _finish()
	await _setup("restart_after_two_coins_and_ten_cycles")
	var stable_score_id: int = score.get_instance_id()
	for cycle: int in 10:
		_start()
		await _wait_score(20)
		_check(score.score == 20 and score.coins_collected == 2, "two coins per attempt")
		var old: WeakRef = weakref(player)
		var cycle_world: WeakRef = weakref(level.world)
		var attempt: int = level.attempt_id
		var signals_before: int = int(counts.get("score_changed", 0))
		await _restart()
		_check(level.attempt_id == attempt + 1 and old.get_ref() == null and cycle_world.get_ref() == null, "fresh World and Player")
		_check(score.get_instance_id() == stable_score_id and int(counts.get("score_changed", 0)) == signals_before + 1, "stable ScoreManager one reset")
		_check(level.find_children("World", "Node2D", false, false).size() == 1, "one World")
		_check(_coin(1).get_signal_connection_list("pickup_requested").size() == 2, "no signal accumulation")
	_check(level.attempt_id == 11, "ten new attempts")
	await _finish()
	_complete()

func _complete() -> void:
	var passed: bool = results.all(func(row: Dictionary) -> bool: return row["passed"])
	var result: Dictionary = {"passed": passed, "case_count": results.size(), "physics_hz": Engine.physics_ticks_per_second, "visual": visual, "fps_target": fps_target, "results": results}
	if not output.is_empty():
		var file := FileAccess.open(output, FileAccess.WRITE)
		if file == null:
			push_error("Cannot write coin test output")
			quit(1)
			return
		file.store_string(JSON.stringify(result, "\t") + "\n")
	print("COIN_SUITE ", JSON.stringify({"passed": passed, "case_count": results.size(), "physics_hz": Engine.physics_ticks_per_second}))
	quit(0 if passed else 1)
