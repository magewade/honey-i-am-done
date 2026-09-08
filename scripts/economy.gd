extends Node

signal currency_changed(new_amount: int)
signal bees_changed(new_amount: int)
var _currency: int = 300
var _bees: int = 10

func add_currency(amount: int) -> void:
    _currency += amount
    currency_changed.emit(_currency)

func set_currency(amount: int) -> void:
    _currency = amount
    currency_changed.emit(_currency)

func spend_currency(amount: int) -> bool:
    if _currency >= amount:
        _currency -= amount
        currency_changed.emit(_currency)
        return true
    else:
        return false


func get_currency() -> int:
    return _currency

func add_bees(amount: int) -> void:
    _bees += amount
    bees_changed.emit(_bees)

func set_bees(amount: int) -> void:
    _bees = amount
    bees_changed.emit(_bees)

func spend_bees(amount: int) -> bool:
    if _bees >= amount:
        _bees -= amount
        bees_changed.emit(_bees)
        return true
    else:
        return false

func get_bees() -> int:
    return _bees