extends CanvasLayer

@onready var _dim: ColorRect = $Dim

func _ready() -> void:
	visible = false
	_dim.gui_input.connect(_on_dim_gui_input)

func open() -> void:
	visible = true

func close() -> void:
	visible = false

func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
