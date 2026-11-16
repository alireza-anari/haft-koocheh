extends "res://scripts/gameplay/level_controller.gd"

## Debug presentation and R control belong only to this technical fixture.
@onready var debug_label: Label = $Debug/Status

func _process(_delta: float) -> void:
	debug_label.text = "COIN/SCORE TECH FIXTURE | %s | attempt=%d\nscore=%d coins=%d | Space: jump | R: restart" % [run_state, attempt_id, score_manager.score, score_manager.coins_collected]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_R and event.pressed and not event.echo:
		restart_run()
