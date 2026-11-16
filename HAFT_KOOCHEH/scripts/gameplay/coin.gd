extends Area2D

signal pickup_requested(coin_id: StringName)

const PlayerController = preload("res://scripts/player/player_controller.gd")
const ScoreManager = preload("res://scripts/systems/score_manager.gd")
@export var coin_id: StringName = &""
var pending: bool = false
var collected: bool = false
var _active_player: WeakRef
var _attempt_id: int = -1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func configure(player: PlayerController, attempt: int) -> void:
	_active_player = weakref(player)
	_attempt_id = attempt

func request_pickup(body: Node2D, attempt: int) -> bool:
	if pending or collected or _active_player == null or not is_instance_valid(body):
		return false
	if body != _active_player.get_ref() or attempt != _attempt_id:
		return false
	var player := body as PlayerController
	if player == null or player.motion_state != PlayerController.MotionState.RUNNING:
		return false
	if not ScoreManager.is_valid_coin_id(coin_id):
		push_warning("Coin: invalid coin_id: " + String(coin_id))
		return false
	pending = true
	pickup_requested.emit(coin_id)
	return true

func confirm_pickup() -> void:
	if not pending or collected:
		return
	collected = true
	pending = false
	set_deferred("monitoring", false)
	($CollisionShape2D as CollisionShape2D).set_deferred("disabled", true)
	($Visual as Polygon2D).hide()

func reject_pickup() -> void:
	pending = false

func _on_body_entered(body: Node2D) -> void:
	request_pickup(body, _attempt_id)
