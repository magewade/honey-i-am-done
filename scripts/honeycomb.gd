extends Control
class_name Honeycomb

const COMB_TEXTURE := preload("res://sprites/Frame/Comb.png")
const TEXTURE_SIZE := Vector2(1425.0, 789.0)
const CELL_SIZE := Vector2(66.0, 108.0)
const PITCH_X := 66.0
const PITCH_Y := 54.0
const ROW_COUNT := 14
const COL_COUNT := 21
const BASE_ALPHA := 0.2

var _installed: Dictionary = {}

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func _draw() -> void:
	var scale_factor := size.x / TEXTURE_SIZE.x
	draw_texture_rect_region(COMB_TEXTURE, Rect2(Vector2.ZERO, size), Rect2(Vector2.ZERO, TEXTURE_SIZE), Color(1, 1, 1, BASE_ALPHA))
	for key in _installed:
		var center: Vector2 = _cell_center(key.x, key.y)
		var src := Rect2(center - CELL_SIZE * 0.5, CELL_SIZE)
		var dst := Rect2(center * scale_factor - CELL_SIZE * 0.5 * scale_factor, CELL_SIZE * scale_factor)
		draw_texture_rect_region(COMB_TEXTURE, dst, src)

func _cell_center(row: int, col: int) -> Vector2:
	var y := 45.0 + row * PITCH_Y
	var x_start := 34.5 if row % 2 == 0 else 67.5
	return Vector2(x_start + col * PITCH_X, y)

func total_cells() -> int:
	return ROW_COUNT * COL_COUNT

func installed_count() -> int:
	return _installed.size()

func is_installed(row: int, col: int) -> bool:
	return _installed.has(Vector2i(row, col))

func is_border(row: int, col: int) -> bool:
	return row == 0 or row == ROW_COUNT - 1 or col == 0 or col == COL_COUNT - 1

func get_neighbors(row: int, col: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = [Vector2i(row, col - 1), Vector2i(row, col + 1)]
	if row % 2 == 0:
		result.append(Vector2i(row - 1, col - 1))
		result.append(Vector2i(row - 1, col))
		result.append(Vector2i(row + 1, col - 1))
		result.append(Vector2i(row + 1, col))
	else:
		result.append(Vector2i(row - 1, col))
		result.append(Vector2i(row - 1, col + 1))
		result.append(Vector2i(row + 1, col))
		result.append(Vector2i(row + 1, col + 1))
	return result

func can_install(row: int, col: int) -> bool:
	if row < 0 or row >= ROW_COUNT or col < 0 or col >= COL_COUNT:
		return false
	if is_installed(row, col):
		return false
	if is_border(row, col):
		return true
	for n in get_neighbors(row, col):
		if is_installed(n.x, n.y):
			return true
	return false

func install_cell(row: int, col: int) -> bool:
	if not can_install(row, col):
		return false
	_installed[Vector2i(row, col)] = true
	queue_redraw()
	return true

func _closest_cell(local_pos: Vector2) -> Vector2i:
	var scale_factor := size.x / TEXTURE_SIZE.x
	var tex_pos := local_pos / scale_factor
	var approx_row := int(round((tex_pos.y - 45.0) / PITCH_Y))
	var best := Vector2i(-1, -1)
	var best_dist := INF
	for r in range(max(0, approx_row - 1), min(ROW_COUNT, approx_row + 2)):
		var x_start := 34.5 if r % 2 == 0 else 67.5
		var approx_col := int(round((tex_pos.x - x_start) / PITCH_X))
		for c in range(max(0, approx_col - 1), min(COL_COUNT, approx_col + 2)):
			var d: float = tex_pos.distance_squared_to(_cell_center(r, c))
			if d < best_dist:
				best_dist = d
				best = Vector2i(r, c)
	return best

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := _closest_cell(event.position)
		if cell.x >= 0:
			install_cell(cell.x, cell.y)
