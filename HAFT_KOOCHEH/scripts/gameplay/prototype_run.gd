extends Node2D

## Technical scene only. The app title does not activate gameplay.
@export var auto_start: bool = true
@onready var player: CharacterBody2D = $Player

func _physics_process(_delta: float) -> void:
	if auto_start and player.is_on_floor():
		player.set_gameplay_enabled(true)
		set_physics_process(false)
