extends Area2D

signal hazard_contact(hazard_id: StringName, reason: StringName)

const PlayerController = preload("res://scripts/player/player_controller.gd")
@export var hazard_id: StringName = &"hazard_test"
@export var reason: StringName = &"hazard"
var _active_player: PlayerController
var _attempt_id: int = -1
var _contact_reported: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func configure(player: PlayerController, attempt: int) -> void:
	_active_player = player
	_attempt_id = attempt
	_contact_reported = false

func report_contact(body: Node2D, attempt: int) -> bool:
	if not is_instance_valid(_active_player) or body != _active_player or attempt != _attempt_id:
		return false
	if _active_player.motion_state != PlayerController.MotionState.RUNNING or _contact_reported:
		return false
	if reason != &"hazard" and reason != &"fall":
		return false
	_contact_reported = true
	hazard_contact.emit(hazard_id, reason)
	return true

func _on_body_entered(body: Node2D) -> void:
	report_contact(body, _attempt_id)

func _on_body_exited(body: Node2D) -> void:
	if body == _active_player:
		_contact_reported = false
