extends Node2D

enum State { DELAY, TO_HIVE, ENTER_HIVE, EXIT_HIVE, TO_FLOWER, ON_FLOWER, LEAVE_SCREEN }

const HIVE_FADE_TIME := 0.6
const FLOWER_PAUSE := 1.8
const ARRIVE_DISTANCE := 6.0
const SLOWDOWN_RADIUS := 150.0
const MIN_SPEED_FACTOR := 0.3
const LEAVE_DISTANCE := 1600.0
const MAX_START_DELAY := 1.5
const HIVE_ENTRANCE_CENTER := Vector2(-112, -88)
const HIVE_ENTRANCE_DIR := Vector2(0.8, 0.6)
const HIVE_ENTRANCE_HALF_LENGTH := 65.0
const HIVE_ENTRANCE_THICKNESS := 14.0
const HIVE_DIVE_SPEED := 60.0
const MAX_BEES_PER_STEM := 2
const LANDING_JITTER := 6.0

const TURN_SMOOTH_TIME := 0.5
const MAX_TURN_RATE := 4.5
const WANDER_STRENGTH := 3.2
const WANDER_FREQ := 1.4
const SPEED_NOISE_FREQ := 0.6
const SPEED_VARIATION := 0.35

var home_hive: Node2D = null
var world_root: Node2D = null

@onready var _body: Sprite2D = $Body

var _state: int = State.DELAY
var _target: Vector2
var _timer: float = 0.0
var _speed: float
var _heading_angle: float
var _noise := FastNoiseLite.new()
var _noise_x_offset: float
var _plan: Array[String] = []
var _landing_spot: Node2D = null

func _ready() -> void:
	_speed = randf_range(150.0, 230.0)
	_heading_angle = randf() * TAU
	_noise.seed = randi()
	_noise_x_offset = randf() * 1000.0
	_timer = randf_range(0.0, MAX_START_DELAY)
	_build_plan()

func _build_plan() -> void:
	var steps: Array[String] = []
	if randf() < 0.7:
		steps.append("hive")
	if randf() < 0.85:
		steps.append("flower")
	if randf() < 0.35:
		steps.append("flower")
	if steps.is_empty():
		steps.append("hive")
	steps.shuffle()
	_plan = steps

func _process(delta: float) -> void:
	match _state:
		State.DELAY:
			_timer -= delta
			if _timer <= 0.0:
				_advance_plan()
		State.TO_HIVE, State.TO_FLOWER, State.LEAVE_SCREEN:
			_fly_toward(delta)
		State.ENTER_HIVE:
			_timer -= delta
			modulate.a = clampf(_timer / HIVE_FADE_TIME, 0.0, 1.0)
			global_position += Vector2.RIGHT.rotated(_heading_angle) * HIVE_DIVE_SPEED * delta
			if _timer <= 0.0:
				_state = State.EXIT_HIVE
				_timer = HIVE_FADE_TIME
		State.EXIT_HIVE:
			_timer -= delta
			modulate.a = clampf(1.0 - _timer / HIVE_FADE_TIME, 0.0, 1.0)
			if _timer <= 0.0:
				z_index = 0
				_advance_plan()
		State.ON_FLOWER:
			_timer -= delta
			if _timer <= 0.0:
				_leave_landing_spot()
				_advance_plan()

func _fly_toward(delta: float) -> void:
	var to_target := _target - global_position
	var distance := to_target.length()
	if distance <= ARRIVE_DISTANCE:
		_arrive()
		return

	var proximity := clampf(distance / SLOWDOWN_RADIUS, 0.0, 1.0)
	var t := Time.get_ticks_msec() / 1000.0
	var desired_angle := to_target.angle()

	if distance <= SLOWDOWN_RADIUS:
		_heading_angle = desired_angle
	else:
		var angle_diff := wrapf(desired_angle - _heading_angle, -PI, PI)
		var steer_rate := clampf(angle_diff / TURN_SMOOTH_TIME, -MAX_TURN_RATE, MAX_TURN_RATE)
		var wander_rate := _noise.get_noise_1d(_noise_x_offset + t * WANDER_FREQ) * WANDER_STRENGTH
		_heading_angle += (steer_rate + wander_rate) * delta

	var speed_mod := (1.0 + _noise.get_noise_1d(_noise_x_offset + 500.0 + t * SPEED_NOISE_FREQ) * SPEED_VARIATION)
	speed_mod *= lerpf(MIN_SPEED_FACTOR, 1.0, proximity)
	var velocity := Vector2.RIGHT.rotated(_heading_angle) * _speed * speed_mod

	global_position += velocity * delta
	_body.rotation = _heading_angle

func _arrive() -> void:
	match _state:
		State.TO_HIVE:
			global_position = _target
			_state = State.ENTER_HIVE
			_timer = HIVE_FADE_TIME
		State.TO_FLOWER:
			global_position = _target
			if _landing_spot and world_root:
				var gp := global_position
				world_root.remove_child(self)
				_landing_spot.add_child(self)
				global_position = gp
			_state = State.ON_FLOWER
			_timer = FLOWER_PAUSE
		State.LEAVE_SCREEN:
			_build_plan()
			_advance_plan()

func _advance_plan() -> void:
	if _plan.is_empty():
		_start_leaving()
		return
	var step: String = _plan.pop_front()
	if step == "hive":
		var hive: Node2D = home_hive if home_hive else _pick_random(get_tree().get_nodes_in_group("hives"))
		if hive:
			_target = hive.global_position + _hive_approach_offset()
			_state = State.TO_HIVE
			z_index = 1
			return
	else:
		var spot: Node2D = _pick_landing_spot()
		if spot:
			spot.set_meta("reserved_count", int(spot.get_meta("reserved_count", 0)) + 1)
			_landing_spot = spot
			_target = spot.global_position + Vector2(randf_range(-LANDING_JITTER, LANDING_JITTER), randf_range(-LANDING_JITTER, LANDING_JITTER))
			_state = State.TO_FLOWER
			return
	_advance_plan()

func _pick_landing_spot() -> Node2D:
	var spots := get_tree().get_nodes_in_group("landing_spots")
	var available: Array = []
	for spot in spots:
		if int(spot.get_meta("reserved_count", 0)) < MAX_BEES_PER_STEM:
			available.append(spot)
	if available.is_empty():
		return null
	return available[randi() % available.size()]

func _leave_landing_spot() -> void:
	if _landing_spot == null:
		return
	var gp := global_position
	_landing_spot.remove_child(self)
	if world_root:
		world_root.add_child(self)
	global_position = gp
	_landing_spot.set_meta("reserved_count", maxi(0, int(_landing_spot.get_meta("reserved_count", 0)) - 1))
	_landing_spot = null

func _start_leaving() -> void:
	_state = State.LEAVE_SCREEN
	var direction := Vector2.RIGHT.rotated(randf() * TAU)
	_target = global_position + direction * LEAVE_DISTANCE

func _hive_approach_offset() -> Vector2:
	var along := randf_range(-HIVE_ENTRANCE_HALF_LENGTH, HIVE_ENTRANCE_HALF_LENGTH)
	var across := randf_range(-HIVE_ENTRANCE_THICKNESS, HIVE_ENTRANCE_THICKNESS)
	var perpendicular := Vector2(-HIVE_ENTRANCE_DIR.y, HIVE_ENTRANCE_DIR.x)
	return HIVE_ENTRANCE_CENTER + HIVE_ENTRANCE_DIR * along + perpendicular * across

func _pick_random(nodes: Array) -> Node:
	if nodes.is_empty():
		return null
	return nodes[randi() % nodes.size()]
