extends Node

const HIVE_SCENE := preload("res://scenes/Hive.tscn")
const BEE_SCENE := preload("res://scenes/Bee.tscn")
const GRASS_TEXTURE := preload("res://sprites/Garden/Grass.png")
const GROUND_TEXTURE := preload("res://sprites/Garden/Ground.png")

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var objects: Node2D = $Objects
@onready var hive_inspector: CanvasLayer = $HiveInspector

var _ghost: Node2D = null
var _known_bees := 0

func _ready() -> void:
	tile_map.set_cell(Vector2i(0, 0), 0, Vector2i(0, 0))
	_spawn_hive(Vector2i(0, 0))
	Placement.selection_changed.connect(_on_selection_changed)
	Economy.bees_changed.connect(_on_bees_changed)
	_on_bees_changed(Economy.get_bees())

func _spawn_hive(cell: Vector2i) -> void:
	var hive := HIVE_SCENE.instantiate()
	objects.add_child(hive)
	hive.position = tile_map.map_to_local(cell)
	hive.add_to_group("hives")
	hive.opened.connect(hive_inspector.open)

func _on_bees_changed(new_amount: int) -> void:
	var delta := new_amount - _known_bees
	_known_bees = new_amount
	if delta <= 0:
		return
	var hives := get_tree().get_nodes_in_group("hives")
	if hives.is_empty():
		return
	for i in delta:
		_spawn_bee(hives[randi() % hives.size()])

func _spawn_bee(hive: Node2D) -> void:
	var bee := BEE_SCENE.instantiate()
	var angle := randf() * TAU
	var distance := randf_range(900.0, 1400.0)
	bee.home_hive = hive
	bee.position = hive.position + Vector2(cos(angle), sin(angle)) * distance
	objects.add_child(bee)

func _process(_delta: float) -> void:
	if _ghost:
		var cell := tile_map.local_to_map(tile_map.to_local(tile_map.get_global_mouse_position()))
		_ghost.position = tile_map.map_to_local(cell)

func _on_selection_changed() -> void:
	if _ghost:
		_ghost.queue_free()
		_ghost = null

	match Placement.kind:
		Placement.Kind.SCENE:
			_ghost = Placement.ghost_scene.instantiate()
			_ghost.modulate.a = 0.6
			var grass_decal: Node = _ghost.get_node_or_null("GrassDecal")
			if grass_decal:
				grass_decal.visible = false
			if "is_ghost" in _ghost:
				_ghost.is_ghost = true
			objects.add_child(_ghost)
		Placement.Kind.TILE:
			var sprite := Sprite2D.new()
			sprite.texture = GRASS_TEXTURE if Placement.tile_source_id == 0 else GROUND_TEXTURE
			sprite.modulate.a = 0.6
			_ghost = sprite
			objects.add_child(_ghost)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and Placement.kind != Placement.Kind.NONE:
		Placement.clear()
		return

	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	if Placement.kind == Placement.Kind.NONE:
		return

	var cell: Vector2i = tile_map.local_to_map(tile_map.to_local(tile_map.get_global_mouse_position()))

	match Placement.kind:
		Placement.Kind.SCENE:
			if tile_map.get_cell_source_id(cell) != Placement.surface_source_id:
				return
			if not Economy.spend_currency(Placement.price):
				return
			var item := Placement.placed_scene.instantiate()
			item.position = tile_map.map_to_local(cell)
			objects.add_child(item)
			if Placement.group != "":
				item.add_to_group(Placement.group)
			if item.is_in_group("hives"):
				item.opened.connect(hive_inspector.open)
			Placement.clear()
		Placement.Kind.TILE:
			if tile_map.get_cell_source_id(cell) != -1:
				return
			if not Economy.spend_currency(Placement.price):
				return
			tile_map.set_cell(cell, Placement.tile_source_id, Vector2i(0, 0))
			Placement.clear()
