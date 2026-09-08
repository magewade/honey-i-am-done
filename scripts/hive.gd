extends Node2D

signal opened

@onready var _click_area: Area2D = $ClickArea

func _ready() -> void:
	_click_area.input_event.connect(_on_click_area_input_event)

func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if Placement.kind != Placement.Kind.NONE:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		opened.emit()
