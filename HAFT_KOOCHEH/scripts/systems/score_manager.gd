extends Node

signal score_changed(score: int, coins: int)

var level_id: StringName = &""
var coins_collected: int = 0
var score: int = 0
var last_rejection: StringName = &""
var _collected_ids: Dictionary = {}

static func is_valid_coin_id(coin_id: StringName) -> bool:
	var text: String = String(coin_id)
	if text.is_empty() or text[0] < "a" or text[0] > "z":
		return false
	for character: String in text:
		if not ((character >= "a" and character <= "z") or (character >= "0" and character <= "9") or character == "_"):
			return false
	return true

func reset_run(id: StringName) -> void:
	level_id = id
	coins_collected = 0
	score = 0
	_collected_ids.clear()
	last_rejection = &""
	score_changed.emit(score, coins_collected)

func record_coin(coin_id: StringName) -> bool:
	if not is_valid_coin_id(coin_id):
		last_rejection = &"invalid_coin_id"
		push_warning("ScoreManager: invalid coin_id: " + String(coin_id))
		return false
	if _collected_ids.has(coin_id):
		last_rejection = &"duplicate_coin_id"
		return false
	_collected_ids[coin_id] = true
	coins_collected += 1
	score = 10 * coins_collected
	last_rejection = &""
	score_changed.emit(score, coins_collected)
	return true

func build_result(completed: bool) -> Dictionary:
	return {"level_id": String(level_id), "score": score, "coins": coins_collected, "completed": completed}
