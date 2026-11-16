extends CharacterBody2D

## Movement and fixed jump only. Input metadata never changes velocity.
enum MotionState { DISABLED, RUNNING, DEAD }
signal jumped()
signal landed()
signal blocked()
signal out_of_bounds()

@export var run_speed: float = 280.0
@export var gravity: float = 1200.0
@export var jump_velocity: float = -480.0
@export var coyote_time: float = 0.08
@export var jump_buffer: float = 0.10
var motion_state: MotionState = MotionState.DISABLED

const TIME_EPSILON: float = 0.00000001
var _simulation_time: float = 0.0
var _buffer_until: float = -INF
var _coyote_until: float = -INF
var _landing_request_latched: bool = false
var _space_down: bool = false
var _space_edge: bool = false
var _touches_down: Dictionary = {}
var _primary_touch: int = -1
var _touch_press_edge: int = -1
var _kill_y: float = INF
var _wall_contact: bool = false
var _outside_bounds: bool = false

func configure(start: Vector2, kill_y: float) -> void:
	# Only a fresh instance may be configured; DEAD cannot be resurrected.
	if motion_state == MotionState.DEAD:
		return
	global_position = start
	_kill_y = kill_y
	_wall_contact = false
	_outside_bounds = false
	velocity = Vector2.ZERO
	set_gameplay_enabled(false)

func freeze_on_failure() -> void:
	set_gameplay_enabled(false)
	motion_state = MotionState.DEAD
	velocity = Vector2.ZERO

func set_gameplay_enabled(enabled: bool) -> void:
	if motion_state == MotionState.DEAD:
		return
	motion_state = MotionState.RUNNING if enabled else MotionState.DISABLED
	if not enabled:
		velocity.x = 0.0
		_buffer_until = -INF
		_coyote_until = -INF
		_landing_request_latched = false

func request_jump() -> void:
	if motion_state != MotionState.RUNNING:
		return
	# A single pending request cannot be refreshed while it is still valid.
	if _landing_request_latched or _simulation_time <= _buffer_until + TIME_EPSILON:
		return
	_buffer_until = _simulation_time + jump_buffer

func _input(event: InputEvent) -> void:
	# Track releases even if a Control consumes them; do not jump here.
	if event is InputEventKey and (event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE):
		_space_edge = event.pressed and not event.echo and not _space_down
		_space_down = event.pressed
	elif event is InputEventScreenTouch:
		_touch_press_edge = -1
		if event.pressed:
			if _touches_down.is_empty():
				_primary_touch = event.index
				_touch_press_edge = event.index
			_touches_down[event.index] = true
		else:
			_touches_down.erase(event.index)
			if event.index == _primary_touch:
				_primary_touch = -1
			if _touches_down.is_empty():
				_primary_touch = -1

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE):
		if event.pressed and not event.echo and _space_edge:
			_space_edge = false
			request_jump()
	elif event is InputEventScreenTouch and event.pressed:
		if event.index == _primary_touch and event.index == _touch_press_edge:
			_touch_press_edge = -1
			request_jump()

func _physics_process(delta: float) -> void:
	if motion_state == MotionState.DEAD:
		return
	var running: bool = motion_state == MotionState.RUNNING
	var was_on_floor: bool = is_on_floor()
	var jumped_this_tick: bool = false
	velocity.x = run_speed if running else 0.0
	if running:
		if not _landing_request_latched and _simulation_time > _buffer_until + TIME_EPSILON:
			_buffer_until = -INF
		var has_request: bool = _landing_request_latched or _simulation_time <= _buffer_until + TIME_EPSILON
		var can_jump: bool = was_on_floor or _simulation_time <= _coyote_until + TIME_EPSILON
		if has_request and can_jump:
			velocity.y = jump_velocity
			_buffer_until = -INF
			_coyote_until = -INF
			_landing_request_latched = false
			jumped_this_tick = true
			jumped.emit()
	if not jumped_this_tick:
		if not was_on_floor:
			velocity.y += gravity * delta
		else:
			velocity.y = 0.0
	move_and_slide()
	var end_time: float = _simulation_time + delta if running else _simulation_time
	if is_on_floor():
		velocity.y = 0.0
		_coyote_until = -INF
		if not was_on_floor:
			if running and end_time <= _buffer_until + TIME_EPSILON:
				_landing_request_latched = true
			landed.emit()
	elif running and was_on_floor and not jumped_this_tick:
		# Only walking off an edge creates this deadline; intentional jump does not.
		_coyote_until = end_time + coyote_time
	_simulation_time = end_time

	if running:
		var touching_wall: bool = false
		for index: int in get_slide_collision_count():
			if get_slide_collision(index).get_normal().x < -0.7 and run_speed > 0.0:
				touching_wall = true
		if touching_wall and not _wall_contact:
			blocked.emit()
		_wall_contact = touching_wall
		var outside: bool = global_position.y > _kill_y
		if outside and not _outside_bounds:
			out_of_bounds.emit()
		_outside_bounds = outside
