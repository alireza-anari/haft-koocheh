extends Node2D

signal run_state_changed(state: StringName)
signal run_failed(reason: StringName)

const PlayerController = preload("res://scripts/player/player_controller.gd")
const Hazard = preload("res://scripts/obstacles/hazard.gd")
@export var world_scene: PackedScene
@export var kill_y: float = 1000.0
@export var auto_start: bool = true
var run_state: StringName = &"READY"
var failure_reason: StringName = &""
var attempt_id: int = 0
var active_player: PlayerController
var world: Node2D
var _events: Array[Dictionary] = []
var _restart_pending: bool = false
var _exiting: bool = false

func _init() -> void:
	process_physics_priority = -100

func _ready() -> void:
	restart_run()

func start_run() -> bool:
	if _exiting or _restart_pending or run_state != &"READY" or not is_instance_valid(active_player):
		return false
	if not active_player.is_on_floor():
		return false
	active_player.set_gameplay_enabled(true)
	_set_state(&"RUNNING")
	return true

func restart_run() -> void:
	if _exiting or _restart_pending:
		return
	_restart_pending = true
	_events.clear()
	if is_instance_valid(active_player):
		active_player.freeze_on_failure()
	_set_state(&"READY")
	call_deferred("_replace_world")

func _replace_world() -> void:
	if _exiting:
		return
	active_player = null
	if is_instance_valid(world):
		remove_child(world)
		world.free()
	attempt_id += 1
	failure_reason = &""
	world = world_scene.instantiate() as Node2D
	add_child(world)
	active_player = world.get_node("Player") as PlayerController
	active_player.configure((world.get_node("Start") as Marker2D).global_position, kill_y)
	active_player.blocked.connect(_on_player_failure.bind(&"wall", weakref(active_player), attempt_id))
	active_player.out_of_bounds.connect(_on_player_failure.bind(&"fall", weakref(active_player), attempt_id))
	for node: Node in world.find_children("*", "Area2D", true, false):
		if node is Hazard:
			node.configure(active_player, attempt_id)
			node.hazard_contact.connect(_on_hazard_contact.bind(weakref(active_player), attempt_id))
	_restart_pending = false

func _on_player_failure(reason: StringName, source: WeakRef, attempt: int) -> void:
	queue_failure(reason, source.get_ref() as PlayerController, attempt)

func _on_hazard_contact(_hazard_id: StringName, reason: StringName, source: WeakRef, attempt: int) -> void:
	queue_failure(reason, source.get_ref() as PlayerController, attempt)

func queue_failure(reason: StringName, source: PlayerController, attempt: int) -> bool:
	if _exiting or _restart_pending or run_state != &"RUNNING":
		return false
	if not is_instance_valid(source) or source != active_player or attempt != attempt_id:
		return false
	if reason not in [&"wall", &"hazard", &"fall"]:
		return false
	_events.append({"reason": reason, "source_id": source.get_instance_id(), "attempt": attempt, "tick": Engine.get_physics_frames()})
	return true

func _physics_process(_delta: float) -> void:
	if _exiting or _restart_pending:
		return
	if run_state == &"READY":
		if auto_start:
			start_run()
		return
	if run_state != &"RUNNING":
		return
	var selected: StringName = &""
	var rank: Dictionary = {&"wall": 1, &"hazard": 2, &"fall": 3}
	var current: Array[Dictionary] = []
	for event: Dictionary in _events:
		if event["attempt"] != attempt_id or event["source_id"] != active_player.get_instance_id():
			continue
		if int(event["tick"]) >= Engine.get_physics_frames():
			current.append(event)
		elif selected == &"" or int(rank[event["reason"]]) > int(rank[selected]):
			selected = event["reason"]
	_events = current
	if selected != &"":
		_events.clear()
		failure_reason = selected
		active_player.freeze_on_failure()
		_set_state(&"FAILED")
		run_failed.emit(selected)

func _set_state(state: StringName) -> void:
	if run_state != state:
		run_state = state
		run_state_changed.emit(state)

func exit_to_menu() -> void:
	_exiting = true
	_events.clear()
	if is_instance_valid(active_player):
		active_player.freeze_on_failure()
	get_tree().paused = false
	call_deferred("_return_to_menu")

func _return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/app/main.tscn")
