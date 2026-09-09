@tool
extends Node2D

const HONEYCOMB_SCRIPT := preload("res://scripts/honeycomb.gd")
const EXPORT_PATH := "res://cell_outline_export.txt"
const TEXTURE_SIZE := Vector2(1425.0, 789.0)
const DEFAULT_POINT_COUNT := 16

enum Variant { NORMAL, LEFT_EVEN, LEFT_ODD, RIGHT_EVEN, RIGHT_ODD, TOP, BOTTOM }

# A representative real cell center (in Comb.png pixel coords) for each variant - used to
# position the Reference sprite so that specific cell sits at this node's origin (0,0).
const VARIANT_CENTERS := {
	Variant.NORMAL: Vector2(199.5, 315.0),
	Variant.LEFT_EVEN: Vector2(34.5, 153.0),
	Variant.LEFT_ODD: Vector2(67.5, 99.0),
	Variant.RIGHT_EVEN: Vector2(1354.5, 153.0),
	Variant.RIGHT_ODD: Vector2(1387.5, 99.0),
	Variant.TOP: Vector2(67.5, 45.0),
	Variant.BOTTOM: Vector2(67.5, 747.0),
}

## Which variant's markers are currently visible/editable. The reference image and the frame
## guide lines (cyan) reposition to match.
@export var active_variant: Variant = Variant.NORMAL:
	set(value):
		active_variant = value
		if is_inside_tree():
			_switch_variant()

## Toggle on to (re)generate the ACTIVE variant's markers from Honeycomb's current CELL_OUTLINE.
@export var reset_active_to_default: bool = false:
	set(value):
		if value and is_inside_tree():
			_generate_default_markers(_markers_node(active_variant))
		reset_active_to_default = false

## Toggle on to write every variant's marker positions to cell_outline_export.txt, labeled by
## name, ready to hand back for pasting into honeycomb.gd.
@export var export_all: bool = false:
	set(value):
		if value and is_inside_tree():
			_export_all()
		export_all = false

func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	for variant in Variant.values():
		var node_name := _markers_node_name(variant)
		if not has_node(node_name):
			var n := Node2D.new()
			n.name = node_name
			add_child(n)
			n.owner = get_tree().edited_scene_root
		var markers_node := get_node(node_name) as Node2D
		if markers_node.get_child_count() == 0:
			_generate_default_markers(markers_node)
	_switch_variant()

func _markers_node_name(variant: Variant) -> String:
	return "Markers_" + Variant.keys()[variant]

func _markers_node(variant: Variant) -> Node2D:
	return get_node(_markers_node_name(variant)) as Node2D

func _switch_variant() -> void:
	var variant_center: Vector2 = VARIANT_CENTERS[active_variant]
	$Reference.position = -variant_center
	for variant in Variant.values():
		var node := get_node_or_null(_markers_node_name(variant))
		if node:
			node.visible = variant == active_variant

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	# frame guide lines: where the real Comb.png canvas edges are, in this variant's local space
	var variant_center: Vector2 = VARIANT_CENTERS[active_variant]
	var top_left: Vector2 = Vector2.ZERO - variant_center
	var bottom_right: Vector2 = TEXTURE_SIZE - variant_center
	draw_line(Vector2(top_left.x, -2000), Vector2(top_left.x, 2000), Color.YELLOW, 1.0)
	draw_line(Vector2(bottom_right.x, -2000), Vector2(bottom_right.x, 2000), Color.YELLOW, 1.0)
	draw_line(Vector2(-2000, top_left.y), Vector2(2000, top_left.y), Color.YELLOW, 1.0)
	draw_line(Vector2(-2000, bottom_right.y), Vector2(2000, bottom_right.y), Color.YELLOW, 1.0)

	var markers_node := _markers_node(active_variant)
	var pts := PackedVector2Array()
	for child in markers_node.get_children():
		pts.append(child.position)
	if pts.size() > 2:
		pts.append(pts[0])
		draw_polyline(pts, Color.CYAN, 2.0)
	for p in pts:
		draw_circle(p, 3.0, Color.RED)

func _generate_default_markers(markers_node: Node2D) -> void:
	for child in markers_node.get_children():
		child.queue_free()
	var source := HONEYCOMB_SCRIPT.CELL_OUTLINE
	for i in DEFAULT_POINT_COUNT:
		var src_index := int(i * source.size() / float(DEFAULT_POINT_COUNT))
		var m := Marker2D.new()
		m.position = source[src_index]
		m.name = "Point%02d" % i
		markers_node.add_child(m)
		m.owner = get_tree().edited_scene_root

func _export_all() -> void:
	var lines: Array[String] = []
	for variant in Variant.values():
		var node := _markers_node(variant)
		lines.append("# " + Variant.keys()[variant])
		for child in node.get_children():
			var p: Vector2 = child.position + node.position
			lines.append("Vector2(%s, %s)," % [snappedf(p.x, 0.5), snappedf(p.y, 0.5)])
		lines.append("")
	var f := FileAccess.open(EXPORT_PATH, FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
	print("CellMaskEditor: exported all variants to ", EXPORT_PATH)
