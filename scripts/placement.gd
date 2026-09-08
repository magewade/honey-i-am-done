extends Node

signal selection_changed

enum Kind { NONE, SCENE, TILE }

var kind: int = Kind.NONE
var ghost_scene: PackedScene = null
var placed_scene: PackedScene = null
var tile_source_id: int = -1
var surface_source_id: int = -1
var price: int = 0
var group: String = ""

func select_scene(p_ghost_scene: PackedScene, p_placed_scene: PackedScene, p_price: int, p_surface_source_id: int, p_group: String = "") -> void:
	kind = Kind.SCENE
	ghost_scene = p_ghost_scene
	placed_scene = p_placed_scene
	tile_source_id = -1
	surface_source_id = p_surface_source_id
	price = p_price
	group = p_group
	selection_changed.emit()

func select_tile(source_id: int, p_price: int) -> void:
	kind = Kind.TILE
	ghost_scene = null
	placed_scene = null
	tile_source_id = source_id
	price = p_price
	group = ""
	selection_changed.emit()

func clear() -> void:
	kind = Kind.NONE
	ghost_scene = null
	placed_scene = null
	tile_source_id = -1
	surface_source_id = -1
	price = 0
	group = ""
	selection_changed.emit()
