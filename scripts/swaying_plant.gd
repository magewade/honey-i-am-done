extends Node2D

const SWAY_SPEED := 1.1

@export var is_ghost := false

var _blades: Array[Sprite2D] = []
var _amplitudes: Array[float] = []
var _phases: Array[float] = []
var _time := 0.0

func _ready() -> void:
	for child in get_children():
		if not (child is Sprite2D):
			continue
		var sprite: Sprite2D = child
		_blades.append(sprite)
		var height: int = sprite.texture.get_height()
		var base_amplitude := clampf(height / 12000.0, 0.006, 0.025)
		_amplitudes.append(base_amplitude * randf_range(0.7, 1.3))
		_phases.append(randf() * TAU)

		if not is_ghost:
			for grandchild in sprite.get_children():
				if grandchild is Marker2D:
					grandchild.add_to_group("landing_spots")
					grandchild.set_meta("reserved_count", 0)

func _process(delta: float) -> void:
	if is_ghost:
		return
	_time += delta
	for i in _blades.size():
		_blades[i].rotation = _amplitudes[i] * sin(_time * SWAY_SPEED + _phases[i])
