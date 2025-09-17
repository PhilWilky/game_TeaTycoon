# phase_manager.gd
class_name PhaseManager
extends Node

signal phase_changed(phase: int)
signal day_started(day: int)
signal day_ended(day: int, stats: Dictionary)

enum Phase {
	MORNING_PREP,
	DAY_OPERATION,
	EVENING_REVIEW
}

const DAY_DURATION = 180.0  # 3 minutes in seconds

var current_phase: Phase = Phase.MORNING_PREP
var day_timer: float = 0.0
var is_day_running: bool = false

# System references
var inventory_system: InventorySystem
var milk_system: MilkSystem
var customer_manager: CustomerManager

func _ready() -> void:
	print("PhaseManager: Ready")

func setup(inventory: InventorySystem, _customer_demand, milk: MilkSystem, c_manager: CustomerManager = null) -> void:
	print("PhaseManager: Setting up with dependencies")
	inventory_system = inventory
	milk_system = milk
	customer_manager = c_manager

func _process(delta: float) -> void:
	if current_phase == Phase.DAY_OPERATION and is_day_running:
		day_timer += delta
		
		if day_timer >= DAY_DURATION:
			end_day()

func start_day() -> void:
	print("PhaseManager: Starting day")
	if is_day_running:
		return
		
	is_day_running = true
	day_timer = 0.0
	current_phase = Phase.DAY_OPERATION
	
	GameState.current_day += 1
	GameState.update_weather()
	
	emit_signal("phase_changed", Phase.DAY_OPERATION)
	emit_signal("day_started", GameState.current_day)
	print("PhaseManager: Day %d started" % GameState.current_day)

func end_day() -> void:
	print("PhaseManager: Ending day")
	
	# DEBUG does the customer manager  
	print("Customer manager exists: ", customer_manager != null)
	if customer_manager:
		print("Customer manager properties accessible: ", customer_manager.customers_served_today)
		
	is_day_running = false
	current_phase = Phase.EVENING_REVIEW
	day_timer = 0.0
	
	# Collect comprehensive day statistics
	var day_stats = {
		"day": GameState.current_day,
		"revenue": GameState.daily_revenue,
		"customers_served": 0,  # Will be populated by customer manager
		"customers_missed": 0,  # Will be populated by customer manager  
		"tea_sold": {},
		"milk_used": 0.0,
		"satisfaction_avg": 0.0,
		"weather": GameState.current_weather,
		"starting_stock": {},
		"ending_stock": {},
		"profit": 0.0
	}
	
	# Get customer data
	if customer_manager:
		day_stats.customers_served = customer_manager.customers_served_today
		day_stats.customers_missed = customer_manager.customers_missed_today
		day_stats.tea_sold = customer_manager.tea_sold_today.duplicate()
		if customer_manager.customers_served_today > 0:
			day_stats.satisfaction_avg = customer_manager.total_satisfaction_today / customer_manager.customers_served_today
	
	# Get inventory data
	if inventory_system:
		for tea_name in TeaManager.unlocked_teas:
			day_stats.ending_stock[tea_name] = inventory_system.get_stock(tea_name)
		day_stats.profit = GameState.daily_revenue - inventory_system.daily_costs
	
	emit_signal("phase_changed", Phase.EVENING_REVIEW)
	emit_signal("day_ended", GameState.current_day, day_stats)
	
	# Update cumulative statistics
	GameState.update_cumulative_stats(day_stats)

	print("PhaseManager: Day %d ended" % GameState.current_day)
	
	# Auto-transition to morning prep after 5 seconds (longer for reading reports)
	await get_tree().create_timer(5.0).timeout
	start_morning_prep()

func start_morning_prep() -> void:
	print("PhaseManager: Starting morning prep for next day")
	current_phase = Phase.MORNING_PREP
	
	# Reset daily systems
	if milk_system:
		milk_system.end_day()  # Spoil yesterday's milk
	
	# Don't increment day here - that happens in start_day()
	emit_signal("phase_changed", Phase.MORNING_PREP)
	print("PhaseManager: Ready for Day %d preparation" % (GameState.current_day + 1))

func get_current_phase() -> int:
	return current_phase

func is_running() -> bool:
	return is_day_running

func get_time_elapsed() -> float:
	return day_timer

func get_time_remaining() -> float:
	return max(0.0, DAY_DURATION - day_timer)

func get_day_progress() -> float:
	return clamp(day_timer / DAY_DURATION, 0.0, 1.0)
