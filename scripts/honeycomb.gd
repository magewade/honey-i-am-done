extends Control
class_name Honeycomb

signal cell_installed

const COMB_TEXTURE := preload("res://sprites/Frame/Comb.png")
const CELL_MASK := preload("res://sprites/Frame/Empty_cell.png")
const TEXTURE_SIZE := Vector2(1425.0, 789.0)
const PITCH_X := 66.0
const PITCH_Y := 54.0
const ROW_COUNT := 14
const COL_COUNT := 21
const BASE_ALPHA := 0.2
# Width of the wax tab that joins a side-column cell to the wood, measured off Comb.png. Past
# it there's a transparent gap, then the neighbouring cells' walls.
const FRAME_LEG_WIDTH := 6
# Top-right and bottom-left don't follow their column's parity - the grid leaves a gap there that
# the art fills with a wedge of wax joining both rails (37x27 and 38x21). This box covers either
# one, and reaches no other cell's wax.
const FRAME_CORNER_PATCH := Vector2i(42, 28)

var _installed: Dictionary = {}
var _comb_image: Image
var _mask_image: Image
var _stencil: Image
var _revealed: Image
var _revealed_texture: ImageTexture

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_comb_image = COMB_TEXTURE.get_image()
	_comb_image.convert(Image.FORMAT_RGBA8)
	_mask_image = CELL_MASK.get_image()
	_mask_image.convert(Image.FORMAT_RGBA8)
	var w := int(TEXTURE_SIZE.x)
	var h := int(TEXTURE_SIZE.y)
	_stencil = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	_revealed = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	_revealed_texture = ImageTexture.create_from_image(_revealed)
	gui_input.connect(_on_gui_input)

func _draw() -> void:
	draw_texture_rect(COMB_TEXTURE, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, BASE_ALPHA))
	draw_texture_rect(_revealed_texture, Rect2(Vector2.ZERO, size), false)

# Punches a cell into the stencil using Empty_cell.png's own alpha, so the cut follows the
# sprite's pixels exactly instead of a polygon edge slicing across them.
func _stamp_cell(row: int, col: int) -> void:
	var mask_size := _mask_image.get_size()
	var center := _cell_center(row, col)
	var top_left := Vector2i(
		roundi(center.x - (mask_size.x - 1) / 2.0),
		roundi(center.y - (mask_size.y - 1) / 2.0))
	_stencil_blend(_mask_image, top_left)
	if col == 0 and row % 2 == 0:
		_stencil_fill(Rect2i(0, top_left.y, FRAME_LEG_WIDTH, mask_size.y))
	if col == COL_COUNT - 1 and row % 2 == 1:
		_stencil_fill(Rect2i(int(TEXTURE_SIZE.x) - FRAME_LEG_WIDTH, top_left.y, FRAME_LEG_WIDTH, mask_size.y))
	# Top and bottom rows reach the bar through the gap the mask leaves. Opening the mask's whole
	# width is safe - the neighbouring cell's tab starts well beyond it.
	if row == 0:
		_stencil_fill(Rect2i(top_left.x, 0, mask_size.x, top_left.y))
	if row == ROW_COUNT - 1:
		var mask_bottom := top_left.y + mask_size.y
		_stencil_fill(Rect2i(top_left.x, mask_bottom, mask_size.x, int(TEXTURE_SIZE.y) - mask_bottom))
	if row == 0 and col == COL_COUNT - 1:
		_stencil_fill(Rect2i(int(TEXTURE_SIZE.x) - FRAME_CORNER_PATCH.x, 0, FRAME_CORNER_PATCH.x, FRAME_CORNER_PATCH.y))
	if row == ROW_COUNT - 1 and col == 0:
		_stencil_fill(Rect2i(0, int(TEXTURE_SIZE.y) - FRAME_CORNER_PATCH.y, FRAME_CORNER_PATCH.x, FRAME_CORNER_PATCH.y))
	_revealed.blit_rect_mask(_comb_image, _stencil, Rect2i(Vector2i.ZERO, _stencil.get_size()), Vector2i.ZERO)
	_revealed_texture.update(_revealed)
	queue_redraw()

func _stencil_blend(src: Image, dst: Vector2i) -> void:
	var src_rect := Rect2i(Vector2i.ZERO, src.get_size())
	if dst.x < 0:
		src_rect.position.x -= dst.x
		src_rect.size.x += dst.x
		dst.x = 0
	if dst.y < 0:
		src_rect.position.y -= dst.y
		src_rect.size.y += dst.y
		dst.y = 0
	src_rect.size.x -= maxi(0, dst.x + src_rect.size.x - int(TEXTURE_SIZE.x))
	src_rect.size.y -= maxi(0, dst.y + src_rect.size.y - int(TEXTURE_SIZE.y))
	if src_rect.size.x > 0 and src_rect.size.y > 0:
		_stencil.blend_rect(src, src_rect, dst)

func _stencil_fill(rect: Rect2i) -> void:
	var clipped := rect.intersection(Rect2i(Vector2i.ZERO, _stencil.get_size()))
	if clipped.size.x > 0 and clipped.size.y > 0:
		_stencil.fill_rect(clipped, Color.WHITE)

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
	_stamp_cell(row, col)
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
