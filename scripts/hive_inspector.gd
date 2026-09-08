extends CanvasLayer

@onready var _dim: ColorRect = $Dim
@onready var _cell_counter_label: Label = $Dim/CellCounter/Label
@onready var _comb: Honeycomb = $Dim/FrameGroup/Comb

func _ready() -> void:
	visible = false
	_dim.gui_input.connect(_on_dim_gui_input)
	Economy.bees_changed.connect(_on_bees_changed)
	_comb.cell_installed.connect(_update_cell_counter)
	_update_cell_counter()

func open() -> void:
	visible = true

func close() -> void:
	visible = false

func _on_bees_changed(_new_amount: int) -> void:
	_update_cell_counter()

func _update_cell_counter() -> void:
	_cell_counter_label.text = str(Economy.get_bees() - _comb.installed_count())

func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
