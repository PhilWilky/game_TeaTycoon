# milk_system.gd
class_name MilkSystem
extends Node

signal milk_stock_changed(new_amount: int)
signal milk_depleted
signal milk_spoiled(amount_lost: int)

const MILK_COST = 1.50  # Cost per unit (1 unit = enough for 10 cups)
const MILK_MIN_ORDER = 5  # Minimum units to order
const MILK_MAX_STOCK = 20  # Maximum units that can be stored
const MILK_PER_TEA = 0.1  # One unit of milk makes 10 cups of tea

var current_milk_stock: float = 0.0
var milk_used_today: float = 0.0

func _init():
	reset_stock()

func reset_stock() -> void:
	current_milk_stock = 0.0
	milk_used_today = 0.0

func purchase_milk(units: int) -> float:
	if units < MILK_MIN_ORDER:
		return 0.0
		
	var space_available = MILK_MAX_STOCK - current_milk_stock
	var actual_purchase = min(units, space_available)
	var cost = actual_purchase * MILK_COST
	
	if GameState.spend_money(cost):
		current_milk_stock += actual_purchase
		emit_signal("milk_stock_changed", current_milk_stock)
		return cost
	
	return 0.0

func use_milk() -> bool:
	if current_milk_stock >= MILK_PER_TEA:
		current_milk_stock -= MILK_PER_TEA
		milk_used_today += MILK_PER_TEA
		emit_signal("milk_stock_changed", current_milk_stock)
		
		if current_milk_stock < MILK_PER_TEA:
			emit_signal("milk_depleted")
		return true
	return false

func end_day() -> void:
	var spoiled_milk = current_milk_stock
	if spoiled_milk > 0:
		emit_signal("milk_spoiled", spoiled_milk)
	reset_stock()

func get_current_stock() -> float:
	return current_milk_stock

func get_cups_remaining() -> int:
	return int(current_milk_stock / MILK_PER_TEA)
