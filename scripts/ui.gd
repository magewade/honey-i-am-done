extends CanvasLayer

const HIVE_SCENE := preload("res://scenes/Hive.tscn")
const LAVENDER_CLUSTER_SCENE := preload("res://scenes/LavenderCluster.tscn")
const SUNFLOWER_CLUSTER_SCENE := preload("res://scenes/SunflowerCluster.tscn")
const HIVE_PRICE := 50
const LAVENDER_PRICE := 15
const SUNFLOWER_PRICE := 25
const GRASS_TILE_PRICE := 15
const GROUND_TILE_PRICE := 10
const SLIDE_DURATION := 0.3

@onready var shop_button: Button = $ShopPanel/ShopButton
@onready var debug_balance_input: LineEdit = $DebugBalanceInput
@onready var debug_set_balance_button: Button = $DebugSetBalanceButton
@onready var debug_bees_input: LineEdit = $DebugBeesInput
@onready var debug_set_bees_button: Button = $DebugSetBeesButton
@onready var shop_panel: Panel = $ShopPanel
@onready var balance_label: Label = $BalanceLabel
@onready var bees_label: Label = $BeesLabel
@onready var hive_buy_button: Button = $ShopPanel/HiveBuyButton
@onready var lavender_buy_button: Button = $ShopPanel/LavenderBuyButton
@onready var sunflower_buy_button: Button = $ShopPanel/SunflowerBuyButton
@onready var grass_buy_button: Button = $ShopPanel/GrassBuyButton
@onready var ground_buy_button: Button = $ShopPanel/GroundBuyButton

var _is_open := false
var _hidden_x: float
var _shown_x: float

func _ready() -> void:
	_hidden_x = shop_panel.position.x
	_shown_x = _hidden_x - shop_panel.size.x

	shop_button.pressed.connect(_on_shop_button_pressed)
	debug_set_balance_button.pressed.connect(_on_debug_set_balance_pressed)
	debug_set_bees_button.pressed.connect(_on_debug_set_bees_pressed)
	hive_buy_button.pressed.connect(_on_hive_buy_pressed)
	lavender_buy_button.pressed.connect(_on_lavender_buy_pressed)
	sunflower_buy_button.pressed.connect(_on_sunflower_buy_pressed)
	grass_buy_button.pressed.connect(_on_grass_buy_pressed)
	ground_buy_button.pressed.connect(_on_ground_buy_pressed)
	Economy.currency_changed.connect(_on_currency_changed)
	Economy.bees_changed.connect(_on_bees_changed)
	_on_currency_changed(Economy.get_currency())
	_on_bees_changed(Economy.get_bees())

func _on_shop_button_pressed() -> void:
	_set_open(not _is_open)

func _set_open(open: bool) -> void:
	_is_open = open
	var target_x := _shown_x if _is_open else _hidden_x
	create_tween().tween_property(shop_panel, "position:x", target_x, SLIDE_DURATION)

func _on_debug_set_balance_pressed() -> void:
	if debug_balance_input.text.is_valid_int():
		Economy.set_currency(int(debug_balance_input.text))

func _on_debug_set_bees_pressed() -> void:
	if debug_bees_input.text.is_valid_int():
		Economy.set_bees(int(debug_bees_input.text))

func _on_hive_buy_pressed() -> void:
	Placement.select_scene(HIVE_SCENE, HIVE_SCENE, HIVE_PRICE, 0, "hives")
	_set_open(false)

func _on_lavender_buy_pressed() -> void:
	Placement.select_scene(LAVENDER_CLUSTER_SCENE, LAVENDER_CLUSTER_SCENE, LAVENDER_PRICE, 2, "flowers")
	_set_open(false)

func _on_sunflower_buy_pressed() -> void:
	Placement.select_scene(SUNFLOWER_CLUSTER_SCENE, SUNFLOWER_CLUSTER_SCENE, SUNFLOWER_PRICE, 2, "flowers")
	_set_open(false)

func _on_grass_buy_pressed() -> void:
	Placement.select_tile(0, GRASS_TILE_PRICE)
	_set_open(false)

func _on_ground_buy_pressed() -> void:
	Placement.select_tile(2, GROUND_TILE_PRICE)
	_set_open(false)

func _on_currency_changed(new_amount: int) -> void:
	balance_label.text = "Coins: %d" % new_amount

func _on_bees_changed(new_amount: int) -> void:
	bees_label.text = "Bees: %d" % new_amount
