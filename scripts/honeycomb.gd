extends Control
class_name Honeycomb

signal cell_installed

const COMB_TEXTURE := preload("res://sprites/Frame/Comb.png")
const TEXTURE_SIZE := Vector2(1425.0, 789.0)
const PITCH_X := 66.0
const PITCH_Y := 54.0
const ROW_COUNT := 14
const COL_COUNT := 21
const BASE_ALPHA := 0.2

# Outline of Empty_cell.png's alpha mask (offsets from the cell's own center): flat top, two
# diagonals, a vertical side edge, and the same mirrored below. Used purely as a shape - the
# colors always come from Comb.png at the matching position, never from the mask file itself.
# The flats sit at +-42 rather than the sprite's +-40 because Comb.png draws its cells a couple
# of pixels taller; being slightly generous avoids seams between neighbours.
const CELL_OUTLINE: Array[Vector2] = [
	Vector2(-11.5, -42.0), Vector2(11.5, -42.0),
	Vector2(32.5, -28.0), Vector2(41.5, -19.0),
	Vector2(41.5, 19.0), Vector2(32.5, 28.0),
	Vector2(11.5, 42.0), Vector2(-11.5, 42.0),
	Vector2(-32.5, 28.0), Vector2(-41.5, 19.0),
	Vector2(-41.5, -19.0), Vector2(-32.5, -28.0),
]

var _installed: Dictionary = {}

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func _draw() -> void:
	var scale_factor := size.x / TEXTURE_SIZE.x
	draw_texture_rect_region(COMB_TEXTURE, Rect2(Vector2.ZERO, size), Rect2(Vector2.ZERO, TEXTURE_SIZE), Color(1, 1, 1, BASE_ALPHA))
	for key in _installed:
		_draw_cell(key.x, key.y, scale_factor)

func _draw_cell(row: int, col: int, scale_factor: float) -> void:
	var center: Vector2 = _cell_center(row, col)
	# Only the sides a cell genuinely touches get flattened onto the wood, so its contact spans
	# the cell's full extent instead of just the sliver that pokes past the canvas edge.
	var touches_top := row == 0
	var touches_bottom := row == ROW_COUNT - 1
	var touches_left := col == 0 and row % 2 == 0
	var touches_right := col == COL_COUNT - 1 and row % 2 == 1

	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for offset in CELL_OUTLINE:
		var p := center + offset
		if touches_top and offset.y < 0.0:
			p.y = 0.0
		if touches_bottom and offset.y > 0.0:
			p.y = TEXTURE_SIZE.y
		if touches_left and offset.x < 0.0:
			p.x = 0.0
		if touches_right and offset.x > 0.0:
			p.x = TEXTURE_SIZE.x
		points.append(p * scale_factor)
		uvs.append(p / TEXTURE_SIZE)
	draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, COMB_TEXTURE)

func _cell_center(row: int, col: int) -> Vector2:
	var y := 45.0 + row * PITCH_Y
	var x_start := 34.5 if row % 2 == 0 else 67.5
	return Vector2(x_start + col * PITCH_X, y)

func _neighbor_coords(row: int, col: int) -> Array[Vector2i]:
	if row % 2 == 0:
		return [
			Vector2i(row, col + 1),
			Vector2i(row + 1, col),
			Vector2i(row + 1, col - 1),
			Vector2i(row, col - 1),
			Vector2i(row - 1, col - 1),
			Vector2i(row - 1, col),
		]
	else:
		return [
			Vector2i(row, col + 1),
			Vector2i(row + 1, col + 1),
			Vector2i(row + 1, col),
			Vector2i(row, col - 1),
			Vector2i(row - 1, col),
			Vector2i(row - 1, col + 1),
		]

func total_cells() -> int:
	return ROW_COUNT * COL_COUNT

func installed_count() -> int:
	return _installed.size()

func is_installed(row: int, col: int) -> bool:
	return _installed.has(Vector2i(row, col))

func is_border(row: int, col: int) -> bool:
	if row == 0 or row == ROW_COUNT - 1:
		return true
	if col == 0 and row % 2 == 0:
		return true
	if col == COL_COUNT - 1 and row % 2 == 1:
		return true
	return false

func get_neighbors(row: int, col: int) -> Array[Vector2i]:
	return _neighbor_coords(row, col)

func can_install(row: int, col: int) -> bool:
	if installed_count() >= Economy.get_bees():
		return false
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
	cell_installed.emit()
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
