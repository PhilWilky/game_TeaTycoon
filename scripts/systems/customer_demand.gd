# customer_demand.gd
class_name CustomerDemand
extends Node

enum MissReason {
	NO_TEA_TYPE,      # Tea not unlocked yet
	OUT_OF_STOCK,     # Run out of tea
	NO_STAFF,         # No staff available
	TOO_BUSY         # Queue full
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

func _init():
	reset_daily_stats()

func setup(inventory: InventorySystem) -> void:
	inventory_system = inventory

func try_add_customer(tea_preference: String) -> bool:
	daily_stats.total_potential += 1
	
	if current_queue_size >= MAX_QUEUE_SIZE:
		_record_missed_customer(MissReason.TOO_BUSY)
		print("DEBUG: Customer turned away - Queue full")
		return false
	
	if not inventory_system.has_stock(tea_preference):
		_record_missed_customer(MissReason.OUT_OF_STOCK)
		print("DEBUG: Customer turned away - Out of stock: ", tea_preference)
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
			print("DEBUG: Missed - Tea not available")
		MissReason.OUT_OF_STOCK:
			daily_stats.missed.out_of_stock += 1
			print("DEBUG: Missed - Out of stock")
		MissReason.NO_STAFF:
			daily_stats.missed.no_staff += 1
			print("DEBUG: Missed - No staff")
		MissReason.TOO_BUSY:
			daily_stats.missed.too_busy += 1
			print("DEBUG: Missed - Queue full")
	
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

func get_service_rate() -> float:
	return float(daily_stats.served) / max(daily_stats.total_potential, 1)

func get_miss_rate() -> float:
	var total_missed = (daily_stats.missed.no_tea + 
					   daily_stats.missed.out_of_stock + 
					   daily_stats.missed.no_staff + 
					   daily_stats.missed.too_busy)
	return float(total_missed) / max(daily_stats.total_potential, 1)

func get_current_queue_size() -> int:
	return current_queue_size

func get_detailed_stats() -> Dictionary:
	var total_missed = (daily_stats.missed.no_tea + 
					   daily_stats.missed.out_of_stock + 
					   daily_stats.missed.no_staff + 
					   daily_stats.missed.too_busy)
	
	return {
		"total_attempted": daily_stats.total_potential,
		"served": daily_stats.served,
		"total_missed": total_missed,
		"missed_details": daily_stats.missed.duplicate(),
		"service_rate": get_service_rate(),
		"miss_rate": get_miss_rate()
	}

func is_queue_full() -> bool:
	return current_queue_size >= MAX_QUEUE_SIZE

func get_max_queue_size() -> int:
	return MAX_QUEUE_SIZE

# Helper function to check if we're ready to serve customers
func can_serve_customers() -> bool:
	return inventory_system != null and not is_queue_full()

# Debug function to print current stats
func print_current_stats() -> void:
	print("""
	Current Customer Stats:
	Queue Size: %d/%d
	Total Attempted: %d
	Served: %d
	Missed:
		No Tea: %d
		Out of Stock: %d
		No Staff: %d
		Queue Full: %d
	""" % [
		current_queue_size,
		MAX_QUEUE_SIZE,
		daily_stats.total_potential,
		daily_stats.served,
		daily_stats.missed.no_tea,
		daily_stats.missed.out_of_stock,
		daily_stats.missed.no_staff,
		daily_stats.missed.too_busy
	])
