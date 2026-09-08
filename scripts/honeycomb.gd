extends Control
class_name Honeycomb

const COMB_TEXTURE := preload("res://sprites/Frame/Comb.png")
const TEXTURE_SIZE := Vector2(1425.0, 789.0)
const PITCH_X := 66.0
const PITCH_Y := 54.0
const ROW_COUNT := 14
const COL_COUNT := 21
const BASE_ALPHA := 0.2
const HEX_RADIUS := 38.1
const CORNER_ANGLES := [-30.0, 30.0, 90.0, 150.0, 210.0, 270.0]

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
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for angle_deg in CORNER_ANGLES:
		var angle := deg_to_rad(angle_deg)
		var corner := center + Vector2(cos(angle), sin(angle)) * HEX_RADIUS
		corner = _extend_to_frame(corner, row, col, angle_deg)
		points.append(corner * scale_factor)
		uvs.append(corner / TEXTURE_SIZE)
	draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, COMB_TEXTURE)
	_draw_side_connectors(row, col, center, scale_factor)

func _extend_to_frame(corner: Vector2, row: int, _col: int, angle_deg: float) -> Vector2:
	# top/bottom corners reach the top/bottom frame (a cell there has no interior neighbor on that side at all,
	# and same-row cells are evenly spaced so neighboring rectangles line up with no gap)
	if row == 0 and (angle_deg == 210.0 or angle_deg == 270.0 or angle_deg == -30.0):
		corner.y = 0.0
	if row == ROW_COUNT - 1 and (angle_deg == 30.0 or angle_deg == 90.0 or angle_deg == 150.0):
		corner.y = TEXTURE_SIZE.y
	return corner

func _draw_side_connectors(row: int, col: int, center: Vector2, scale_factor: float) -> void:
	# left/right columns zigzag by half a pitch between rows, so a single cell's own corners
	# don't line up with the next row's cell corners. (row-1, col) and (row+1, col) are always
	# real hex neighbors regardless of row parity, so only reach the full pitch toward one of
	# them if it's actually installed (or this is the grid edge) - otherwise stop at the cell's
	# own natural hex extent, so a lone border cell doesn't sprout a dangling nub.
	var extend_up := row == 0 or is_installed(row - 1, col)
	var extend_down := row == ROW_COUNT - 1 or is_installed(row + 1, col)
	var y_top := maxf(0.0, center.y - (PITCH_Y if extend_up else HEX_RADIUS))
	var y_bottom := minf(TEXTURE_SIZE.y, center.y + (PITCH_Y if extend_down else HEX_RADIUS))
	if col == 0:
		_draw_rect(0.0, PITCH_X, y_top, y_bottom, scale_factor)
	if col == COL_COUNT - 1:
		_draw_rect(TEXTURE_SIZE.x - PITCH_X, TEXTURE_SIZE.x, y_top, y_bottom, scale_factor)

func _draw_rect(x_min: float, x_max: float, y_min: float, y_max: float, scale_factor: float) -> void:
	var src := Rect2(x_min, y_min, x_max - x_min, y_max - y_min)
	var dst := Rect2(Vector2(x_min, y_min) * scale_factor, Vector2(x_max - x_min, y_max - y_min) * scale_factor)
	draw_texture_rect_region(COMB_TEXTURE, dst, src)

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
	return row == 0 or row == ROW_COUNT - 1 or col == 0 or col == COL_COUNT - 1

func get_neighbors(row: int, col: int) -> Array[Vector2i]:
	return _neighbor_coords(row, col)

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
