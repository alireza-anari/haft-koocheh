extends Node2D

signal run_state_changed(state: StringName)
signal run_failed(reason: StringName)

const PlayerController = preload("res://scripts/player/player_controller.gd")
const Coin = preload("res://scripts/gameplay/coin.gd")
const ScoreManager = preload("res://scripts/systems/score_manager.gd")
const Hazard = preload("res://scripts/obstacles/hazard.gd")
@export var level_id: StringName = &"prototype_failure"
@export var world_scene: PackedScene
@export var kill_y: float = 1000.0
@export var auto_start: bool = true
var run_state: StringName = &"READY"
var failure_reason: StringName = &""
var attempt_id: int = 0
var active_player: PlayerController
var world: Node2D
var score_manager: ScoreManager
var layout_error: String = ""
var _coins_by_id: Dictionary = {}
var _events: Array[Dictionary] = []
var _restart_pending: bool = false
var _exiting: bool = false

func _init() -> void:
	process_physics_priority = -100

func _ready() -> void:
	score_manager = get_node_or_null("ScoreManager") as ScoreManager
	restart_run()

func start_run() -> bool:
	if _exiting or _restart_pending or not layout_error.is_empty() or run_state != &"READY" or not is_instance_valid(active_player):
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
	_discard_pending()
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
	_register_coins()
	if score_manager != null:
		score_manager.reset_run(level_id)
	_restart_pending = false

func _register_coins() -> void:
	_coins_by_id.clear()
	layout_error = ""
	for node: Node in world.find_children("*", "Area2D", true, false):
		if node is Coin:
			if not ScoreManager.is_valid_coin_id(node.coin_id) or _coins_by_id.has(node.coin_id):
				layout_error = "Invalid or duplicate coin_id in active World: " + String(node.coin_id)
			else:
				_coins_by_id[node.coin_id] = weakref(node)
			node.configure(active_player, attempt_id)
			node.pickup_requested.connect(_on_pickup_requested.bind(weakref(node), weakref(active_player), attempt_id))
	if not _coins_by_id.is_empty() and score_manager == null:
		layout_error = "Coin World requires a ScoreManager child of LevelController"
	if not layout_error.is_empty():
		push_warning(layout_error)

func _on_pickup_requested(id: StringName, source: WeakRef, player: WeakRef, attempt: int) -> void:
	var coin: Coin = source.get_ref() as Coin
	if not queue_pickup(id, coin, player.get_ref() as PlayerController, attempt) and is_instance_valid(coin):
		coin.reject_pickup()

func _valid_coin(id: StringName, coin: Coin, player: PlayerController, attempt: int) -> bool:
	if _exiting or _restart_pending or not layout_error.is_empty() or run_state != &"RUNNING" or score_manager == null:
		return false
	if not is_instance_valid(player) or player != active_player or attempt != attempt_id:
		return false
	if player.motion_state != PlayerController.MotionState.RUNNING:
		return false
	if not is_instance_valid(coin) or not world.is_ancestor_of(coin) or coin.coin_id != id or not coin.pending or coin.collected:
		return false
	return _coins_by_id.has(id) and _coins_by_id[id].get_ref() == coin

func queue_pickup(id: StringName, coin: Coin, player: PlayerController, attempt: int) -> bool:
	if not _valid_coin(id, coin, player, attempt):
		return false
	_events.append({"kind": &"coin", "coin_id": id, "coin": weakref(coin), "coin_instance_id": coin.get_instance_id(), "source_id": player.get_instance_id(), "attempt": attempt, "tick": Engine.get_physics_frames()})
	return true

func _discard_pending() -> void:
	for event: Dictionary in _events:
		if event.get("kind", &"failure") == &"coin":
			var coin: Coin = event["coin"].get_ref() as Coin
			if is_instance_valid(coin):
				coin.reject_pickup()

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
	_events.append({"kind": &"failure", "reason": reason, "source_id": source.get_instance_id(), "attempt": attempt, "tick": Engine.get_physics_frames()})
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
	var pickups: Array[Dictionary] = []
	for event: Dictionary in _events:
		if event["attempt"] != attempt_id or event["source_id"] != active_player.get_instance_id():
			continue
		if int(event["tick"]) >= Engine.get_physics_frames():
			current.append(event)
		elif event["kind"] == &"coin":
			pickups.append(event)
		elif selected == &"" or int(rank[event["reason"]]) > int(rank[selected]):
			selected = event["reason"]
	if selected != &"":
		_discard_pending()
		_events.clear()
		failure_reason = selected
		active_player.freeze_on_failure()
		_set_state(&"FAILED")
		run_failed.emit(selected)
		return
	_events = current
	pickups.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["coin_id"]) < String(b["coin_id"]))
	for event: Dictionary in pickups:
		var coin: Coin = event["coin"].get_ref() as Coin
		if is_instance_valid(coin) and coin.get_instance_id() == event["coin_instance_id"] and _valid_coin(event["coin_id"], coin, active_player, event["attempt"]):
			if score_manager.record_coin(event["coin_id"]):
				coin.confirm_pickup()
			else:
				coin.reject_pickup()
		elif is_instance_valid(coin):
			coin.reject_pickup()

func _set_state(state: StringName) -> void:
	if run_state != state:
		run_state = state
		run_state_changed.emit(state)

func exit_to_menu() -> void:
	_exiting = true
	_discard_pending()
	_events.clear()
	if is_instance_valid(active_player):
		active_player.freeze_on_failure()
	get_tree().paused = false
	call_deferred("_return_to_menu")

func _return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/app/main.tscn")
