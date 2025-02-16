# customer_demand.gd
class_name CustomerDemand
extends Node

# At the top of customer_demand.gd
enum MissReason {
	NO_TEA_TYPE,      # Tea not unlocked yet
	OUT_OF_STOCK,     # Run out of tea
	NO_STAFF,         # No staff available
	TOO_BUSY,         # Queue full
	NO_MILK           # Out of milk
}

signal customer_missed(reason: MissReason)

const MAX_QUEUE_SIZE = 5

var current_queue_size: int = 0
var daily_stats = {
	"total_potential": 0,
	"served": 0,
	"missed": {
		"no_tea": 0,
		"out_of_stock": 0,
		"no_staff": 0,
		"too_busy": 0
	}
}

var inventory_system: InventorySystem
var tea_manager: TeaManager

func _init():
	reset_daily_stats()

func setup(inventory: InventorySystem) -> void:
	inventory_system = inventory
	tea_manager = TeaManager

# Main function to generate a customer and their tea preference
func generate_customer() -> Dictionary:
	# Early game - only generate customers wanting Builder's Tea
	if tea_manager.unlocked_teas.size() == 1:
		return {
			"type": "regular",
			"tea_preference": "Builder's Tea"
		}
	
	# This won't run until more teas are unlocked
	return {
		"type": "regular",
		"tea_preference": tea_manager.unlocked_teas[0]
	}

func try_add_customer(tea_preference: String) -> bool:
	daily_stats.total_potential += 1
	
	if current_queue_size >= MAX_QUEUE_SIZE:
		_record_missed_customer(MissReason.TOO_BUSY)
		return false
	
	if not inventory_system.has_stock(tea_preference):
		_record_missed_customer(MissReason.OUT_OF_STOCK)
		return false
		
	# If we get here, we can serve the customer
	current_queue_size += 1
	daily_stats.served += 1
	return true

func customer_served() -> void:
	if current_queue_size > 0:
		current_queue_size -= 1

func _record_missed_customer(reason: MissReason) -> void:
	match reason:
		MissReason.NO_TEA_TYPE:
			daily_stats.missed.no_tea += 1
		MissReason.OUT_OF_STOCK:
			daily_stats.missed.out_of_stock += 1
		MissReason.NO_STAFF:
			daily_stats.missed.no_staff += 1
		MissReason.TOO_BUSY:
			daily_stats.missed.too_busy += 1
	
	emit_signal("customer_missed", reason)

func reset_daily_stats() -> void:
	daily_stats = {
		"total_potential": 0,
		"served": 0,
		"missed": {
			"no_tea": 0,
			"out_of_stock": 0,
			"no_staff": 0,
			"too_busy": 0
		}
	}
	current_queue_size = 0

func get_detailed_stats() -> Dictionary:
	var total_missed = (daily_stats.missed.no_tea + 
					   daily_stats.missed.out_of_stock + 
					   daily_stats.missed.no_staff + 
					   daily_stats.missed.too_busy)
	
	return {
		"total_attempted": daily_stats.total_potential,
		"served": daily_stats.served,
		"total_missed": total_missed,
		"missed_details": daily_stats.missed.duplicate()
	}
