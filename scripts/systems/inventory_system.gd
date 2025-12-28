# inventory_system.gd
class_name InventorySystem
extends Node

signal stock_changed(tea_name: String, amount: int)
signal stock_depleted(tea_name: String)
signal restock_needed(tea_name: String)

const LOW_STOCK_THRESHOLD = 5

var inventory = {}
var daily_costs = 0.0

func _init():
	# Initialize with empty inventory
	pass

func initialize_tea(tea_name: String) -> void:
	if not tea_name in inventory:
		inventory[tea_name] = {
			"current": 20, # Starting stock
			"max": 100, # Maximum capacity
			"reorder_point": 10
		}
		emit_signal("stock_changed", tea_name, inventory[tea_name].current)

func has_stock(tea_name: String) -> bool:
	return tea_name in inventory and inventory[tea_name].current > 0

func get_stock(tea_name: String) -> int:
	return inventory[tea_name].current if tea_name in inventory else 0

func use_tea(tea_name: String) -> bool:
	if not has_stock(tea_name):
		return false
		
	inventory[tea_name].current -= 1
	emit_signal("stock_changed", tea_name, inventory[tea_name].current)
	
	if inventory[tea_name].current <= 0:
		emit_signal("stock_depleted", tea_name)
	elif inventory[tea_name].current <= LOW_STOCK_THRESHOLD:
		emit_signal("restock_needed", tea_name)
	
	return true

func restock_tea(tea_name: String, amount: int) -> void:
	print("Attempting to restock %s with %d units" % [tea_name, amount])
	if tea_name not in inventory:
		print("Warning: Attempting to restock non-existent tea: ", tea_name)
		return
		
	var space_available = inventory[tea_name].max - inventory[tea_name].current
	var actual_restock = min(amount, space_available)
	
	if actual_restock < amount:
		# Only charge for what we actually restocked
		var actual_cost = actual_restock * _get_tea_cost(tea_name)
		daily_costs += actual_cost
		print("Can only restock %d units due to capacity. Charging for actual amount: £%.2f" % [actual_restock, actual_cost])
	else:
		daily_costs += amount * _get_tea_cost(tea_name)
	
	inventory[tea_name].current += actual_restock
	emit_signal("stock_changed", tea_name, inventory[tea_name].current)
	print("Restocked %s. New amount: %d" % [tea_name, inventory[tea_name].current])

func reset_daily_costs() -> void:
	daily_costs = 0.0

func _get_tea_cost(tea_name: String) -> float:
	# This should match the costs in your tea data
	match tea_name:
		"Builder's Tea": return 0.50
		"Earl Grey": return 0.75
		"Premium Blend": return 1.20
		_: return 0.0

func get_total_daily_costs() -> float:
	return daily_costs

func get_stock_level(tea_name: String) -> int:
	return inventory[tea_name].current if tea_name in inventory else 0

func get_max_capacity(tea_name: String) -> int:
	return inventory[tea_name].max if tea_name in inventory else 0

func get_reorder_point(tea_name: String) -> int:
	return inventory[tea_name].reorder_point if tea_name in inventory else 0
