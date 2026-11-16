extends SceneTree

class TickProbe extends Node:
	var callback: Callable
	func _physics_process(delta: float) -> void:
		callback.call(delta)

var world: Node2D
var player: CharacterBody2D
var phase: String = "settling"
var settle_ticks: int = 0
var run_ticks: int = 0
var stop_ticks: int = 0
var simulation_seconds: float = 0.0
var initial_disabled_x: float = 0.0
var start_position: Vector2
var end_position: Vector2
var min_y: float = INF
var max_y: float = -INF
var max_vertical_speed: float = 0.0
var min_horizontal_speed: float = INF
var max_horizontal_speed: float = -INF
var floor_contact_ticks: int = 0
var rendered_frames: int = 0
var start_usec: int = 0
var end_usec: int = 0
var hold_for_capture: bool = false
var test_scene_auto_start: bool = false
var output_path: String = ""
var fps_target: float = 0.0
var debug_label: Label

func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--auto-start-smoke":
			test_scene_auto_start = true
		elif arg == "--hold":
			hold_for_capture = true
		elif arg.begins_with("--output="):
			output_path = arg.trim_prefix("--output=")
		elif arg.begins_with("--fps-target="):
			fps_target = float(arg.trim_prefix("--fps-target="))
	call_deferred("_setup")

func _setup() -> void:
	if not ResourceLoader.exists("res://scenes/gameplay/prototype_run.tscn"):
		print("TEST_FAILURE: missing auto-run prototype")
		quit(1)
		return
	var packed: PackedScene = load("res://scenes/gameplay/prototype_run.tscn")
	world = packed.instantiate() as Node2D
	if not test_scene_auto_start:
		world.set("auto_start", false)
	root.add_child(world)
	player = world.get_node("Player") as CharacterBody2D
	initial_disabled_x = player.position.x
	var layer := CanvasLayer.new()
	world.add_child(layer)
	debug_label = Label.new()
	debug_label.position = Vector2(24, 24)
	debug_label.add_theme_font_size_override("font_size", 24)
	layer.add_child(debug_label)
	var probe := TickProbe.new()
	probe.callback = _sample
	probe.process_physics_priority = 100
	root.add_child(probe)

func _process(_delta: float) -> bool:
	if phase == "running":
		rendered_frames += 1
	return false

func _sample(delta: float) -> void:
	if test_scene_auto_start:
		settle_ticks += 1
		if settle_ticks == 120:
			var passed: bool = player.position.x > 400.0 and player.is_on_floor() and player.velocity.x == 280.0
			print("AUTO_START_RESULT " + JSON.stringify({"passed": passed, "physics_ticks": settle_ticks, "x": player.position.x, "floor": player.is_on_floor(), "vx": player.velocity.x}))
			quit(0 if passed else 1)
		return
	debug_label.text = "AUTO-RUN TECH TEST | %s | ticks=%d | x=%.2f y=%.2f" % [phase, run_ticks, player.position.x, player.position.y]
	if phase == "settling":
		settle_ticks += 1
		if absf(player.position.x - initial_disabled_x) > 0.001 or player.velocity.x != 0.0:
			print("TEST_FAILURE: default DISABLED moved horizontally")
			quit(1)
			return
		if settle_ticks >= (180 if hold_for_capture else 30) and player.is_on_floor():
			start_position = player.position
			start_usec = Time.get_ticks_usec()
			player.call("set_gameplay_enabled", true)
			phase = "running"
		elif settle_ticks > 600:
			print("TEST_FAILURE: player did not settle")
			quit(1)
	elif phase == "running":
		run_ticks += 1
		simulation_seconds += delta
		min_y = minf(min_y, player.position.y)
		max_y = maxf(max_y, player.position.y)
		max_vertical_speed = maxf(max_vertical_speed, absf(player.velocity.y))
		min_horizontal_speed = minf(min_horizontal_speed, player.velocity.x)
		max_horizontal_speed = maxf(max_horizontal_speed, player.velocity.x)
		if player.is_on_floor():
			floor_contact_ticks += 1
		if run_ticks % 60 == 0:
			print("POSITION_SAMPLE " + JSON.stringify({"tick": run_ticks, "simulation_seconds": simulation_seconds, "x": player.position.x, "y": player.position.y, "vx": player.velocity.x}))
		if run_ticks == 600:
			end_usec = Time.get_ticks_usec()
			end_position = player.position
			player.call("set_gameplay_enabled", false)
			phase = "stopped"
	elif phase == "stopped":
		stop_ticks += 1
		if stop_ticks == 60:
			_finish()

func _finish() -> void:
	var displacement: float = end_position.x - start_position.x
	var expected: float = 280.0 * simulation_seconds
	var stop_displacement: float = player.position.x - end_position.x
	var wall_seconds: float = float(end_usec - start_usec) / 1000000.0
	var graphical: bool = DisplayServer.get_name() != "headless"
	var measured_fps: float = float(rendered_frames) / wall_seconds
	var fps_pass: bool = graphical and fps_target > 0.0 and absf(measured_fps - fps_target) <= fps_target * 0.1 and absf(wall_seconds - 10.0) <= 1.0
	var movement_pass: bool = run_ticks == 600 and Engine.physics_ticks_per_second == 60 and absf(simulation_seconds - 10.0) < 0.001 and absf(displacement - 2800.0) <= 5.0 and absf(min_horizontal_speed - 280.0) < 0.001 and absf(max_horizontal_speed - 280.0) < 0.001
	var ground_pass: bool = max_y - min_y <= 0.01 and absf(max_y - 600.0) <= 0.1 and max_vertical_speed < 0.001 and floor_contact_ticks == 600
	var stop_pass: bool = absf(stop_displacement) < 0.001 and player.velocity.x == 0.0
	var passed: bool = movement_pass and ground_pass and stop_pass and (fps_pass if fps_target > 0.0 else true)
	var result: Dictionary = {"passed": passed, "physics_hz": Engine.physics_ticks_per_second, "physics_ticks": run_ticks, "simulation_seconds": simulation_seconds, "wall_seconds": wall_seconds, "start_position": [start_position.x, start_position.y], "end_position": [end_position.x, end_position.y], "displacement_px": displacement, "expected_from_actual_ticks_px": expected, "displacement_error_px": displacement - expected, "horizontal_speed_range": [min_horizontal_speed, max_horizontal_speed], "ground_y_range": [min_y, max_y], "max_vertical_speed": max_vertical_speed, "floor_contact_ticks": floor_contact_ticks, "stop_ticks": stop_ticks, "stop_displacement_px": stop_displacement, "stopped_vx": player.velocity.x, "movement_pass": movement_pass, "ground_pass": ground_pass, "stop_pass": stop_pass, "graphical": graphical, "rendered_frames": rendered_frames, "measured_average_fps": measured_fps if graphical else null, "fps_target": fps_target, "fps_status": ("PASS" if fps_pass else "FAIL") if fps_target > 0.0 else "NOT RUN"}
	print("TEST_RESULT " + JSON.stringify(result))
	if not output_path.is_empty():
		var file := FileAccess.open(output_path, FileAccess.WRITE)
		if file == null:
			push_error("Cannot write test result: " + output_path)
			quit(1)
			return
		file.store_string(JSON.stringify(result, "\t") + "\n")
	phase = "COMPLETE" if passed else "FAILED"
	if hold_for_capture:
		get_tree_timer(passed)
	else:
		quit(0 if passed else 1)

func get_tree_timer(passed: bool) -> void:
	create_timer(30.0).timeout.connect(func() -> void: quit(0 if passed else 1))
