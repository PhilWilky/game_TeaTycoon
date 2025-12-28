# phase_manager.gd - ULTRA DEFENSIVE + STATS INTEGRATION
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

const DAY_DURATION = 180.0 # 3 minutes in seconds

var current_phase: Phase = Phase.MORNING_PREP
var day_timer: float = 0.0
var is_day_running: bool = false

# System references
var inventory_system: InventorySystem
var milk_system: MilkSystem
var customer_manager: CustomerManager
var stats_manager: StatsManager

func _ready() -> void:
	print("PhaseManager: Ready")

func setup(inventory: InventorySystem, _customer_demand, milk: MilkSystem, c_manager: CustomerManager = null, s_manager: StatsManager = null) -> void:
	print("PhaseManager: Setting up with dependencies")
	inventory_system = inventory
	milk_system = milk
	customer_manager = c_manager
	stats_manager = s_manager
	
	# NEW - Connect customer_manager signals to stats_manager
	if customer_manager and stats_manager:
		# Forward customer_served signals to stats_manager for tracking
		customer_manager.customer_served.connect(_on_customer_served_for_stats)
		print("PhaseManager: Connected customer_manager to stats_manager")

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

# NEW - Forward customer sales to stats_manager
func _on_customer_served_for_stats(customer_data: Dictionary, satisfaction: float) -> void:
	if not stats_manager:
		return
		
	var tea_name = customer_data.get("tea", "")
	var revenue = customer_data.get("revenue", 0.0)
	var tea_data = TeaManager.TEA_DATA.get(tea_name, {})
	var cost = tea_data.get("cost", 0.0)
	
	stats_manager.record_sale(tea_name, revenue, cost, satisfaction)
	print("PhaseManager: Recorded sale - %s, £%.2f revenue" % [tea_name, revenue])

func end_day() -> void:
	# FIXED - Prevent duplicate calls
	if not is_day_running:
		print("PhaseManager: Ignoring duplicate end_day call")
		return
	
	print("PhaseManager: Ending day")
	
	# FIXED - Set this IMMEDIATELY to prevent re-entry
	is_day_running = false
	current_phase = Phase.EVENING_REVIEW
	day_timer = 0.0
	
	# Get comprehensive stats from StatsManager
	var day_stats = {}
	if stats_manager:
		day_stats = stats_manager.get_current_stats()
		print("PhaseManager: Got stats from StatsManager")
		print("  Revenue: £%.2f" % day_stats.get("revenue", 0.0))
		print("  Costs: £%.2f" % day_stats.get("total_costs", 0.0))
		print("  Customers Served: %d" % day_stats.get("customers_served", 0))
	else:
		# Fallback
		day_stats = {
			"day": GameState.current_day,
			"revenue": GameState.daily_revenue,
			"customers_served": 0,
			"customers_missed": 0,
			"tea_sold": {},
			"profit": 0.0,
			"restock_costs": 0.0,
			"milk_costs": 0.0,
			"milk_spoiled_units": 0.0,
			"milk_spoiled_value": 0.0
		}
	
	# Add additional data not in stats_manager
	day_stats["day"] = GameState.current_day
	day_stats["weather"] = GameState.current_weather
	
	# ULTRA DEFENSIVE - Safely get customer data
	if customer_manager != null and is_instance_valid(customer_manager):
		# Double-check the properties exist before accessing
		if "customers_served_today" in customer_manager:
			day_stats["customers_served"] = customer_manager.customers_served_today
			day_stats["customers_missed"] = customer_manager.customers_missed_today
			day_stats["tea_sold"] = customer_manager.tea_sold_today.duplicate() if customer_manager.tea_sold_today else {}
			
			if customer_manager.customers_served_today > 0:
				day_stats["satisfaction_avg"] = customer_manager.total_satisfaction_today / customer_manager.customers_served_today
			else:
				day_stats["satisfaction_avg"] = 0.0
			
			print("PhaseManager: Customer stats - Served: %d, Missed: %d" % [
				customer_manager.customers_served_today,
				customer_manager.customers_missed_today
			])
		else:
			print("PhaseManager: Warning - customer_manager missing expected properties")
	else:
		print("PhaseManager: Warning - customer_manager is null or invalid")
	
	# Get inventory data
	if inventory_system:
		day_stats["ending_stock"] = {}
		for tea_name in TeaManager.unlocked_teas:
			day_stats["ending_stock"][tea_name] = inventory_system.get_stock(tea_name)
	
	# Calculate profit
	var total_costs = day_stats.get("restock_costs", 0.0) + day_stats.get("milk_costs", 0.0) + day_stats.get("milk_spoiled_value", 0.0)
	day_stats["profit"] = day_stats.get("revenue", 0.0) - total_costs
	
	print("PhaseManager: Day summary")
	print("  Revenue: £%.2f" % day_stats.get("revenue", 0.0))
	print("  Total Costs: £%.2f" % total_costs)
	print("  Net Profit: £%.2f" % day_stats["profit"])
	
	emit_signal("phase_changed", Phase.EVENING_REVIEW)
	emit_signal("day_ended", GameState.current_day, day_stats)
	
	# Update cumulative statistics
	GameState.update_cumulative_stats(day_stats)
	
	print("PhaseManager: Day %d ended" % GameState.current_day)
	
	# Auto-transition to morning prep after 5 seconds
	await get_tree().create_timer(5.0).timeout
	start_morning_prep()

func start_morning_prep() -> void:
	print("PhaseManager: Starting morning prep for next day")
	current_phase = Phase.MORNING_PREP
	
	# Reset daily systems
	if milk_system:
		milk_system.end_day() # Spoil yesterday's milk
	
	# FIXED - Reset stats at START of morning prep (after day ended)
	if stats_manager:
		stats_manager.reset_daily_stats()
		print("PhaseManager: Reset daily stats for new day")
	
	# Reset customer manager stats for new day
	if customer_manager != null and is_instance_valid(customer_manager):
		customer_manager.customers_served_today = 0
		customer_manager.customers_missed_today = 0
		customer_manager.total_satisfaction_today = 0.0
		customer_manager.tea_sold_today.clear()
		print("PhaseManager: Reset customer stats for new day")
	
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
