# game_state.gd
extends Node

signal money_changed(new_amount: float)
signal reputation_changed(new_value: int)

const SATISFACTION_HISTORY_SIZE = 4  # Number of days to track
const MISSED_CUSTOMER_PENALTY = 0.3  # 30% satisfaction penalty per missed customer

var is_initialized: bool = false
var current_day: int = 1
var money: float = 1000.0
var reputation: int = 3
var current_weather: String = "sunny"
var daily_revenue: float = 0.0

var satisfaction_history: Array = []
var current_day_satisfaction: float = 0.0
var total_customers_today: int = 0
var satisfied_customers_today: int = 0

var cumulative_stats = {
	"total_customers_served": 0,
	"total_customers_missed": 0,
	"total_days_played": 0,
	"total_revenue": 0.0,
	"best_daily_profit": 0.0,
	"perfect_days": 0,  # Days with 0 missed customers
	"tea_types_unlocked": 1,  # Start with Builder's Tea
	# NEW - Added cost tracking
	"total_restock_costs": 0.0,
	"total_milk_costs": 0.0,
	"total_milk_spoiled_units": 0.0,
	"total_milk_spoiled_value": 0.0,
	"total_costs": 0.0
}

func initialize() -> void:
	if is_initialized:
		return
		
	is_initialized = true
	current_day = 0
	money = 1000.0
	reputation = 3
	current_weather = "sunny"
	daily_revenue = 0.0
	satisfaction_history.clear()
	
	# Reset cumulative stats on new game
	cumulative_stats = {
		"total_customers_served": 0,
		"total_customers_missed": 0,
		"total_days_played": 0,
		"total_revenue": 0.0,
		"best_daily_profit": 0.0,
		"perfect_days": 0,
		"tea_types_unlocked": 1,
		"total_restock_costs": 0.0,
		"total_milk_costs": 0.0,
		"total_milk_spoiled_units": 0.0,
		"total_milk_spoiled_value": 0.0,
		"total_costs": 0.0
	}

func add_money(amount: float) -> void:
	money += amount
	daily_revenue += amount
	emit_signal("money_changed", money)

func spend_money(amount: float) -> bool:
	if money >= amount:
		money -= amount
		emit_signal("money_changed", money)
		return true
	return false

func calculate_daily_satisfaction(served: int, missed: int, satisfaction_total: float) -> float:
	# If we served no one, it's a complete failure
	if served == 0:
		return 0.0
	
	# Calculate base satisfaction from served customers
	var base_satisfaction = satisfaction_total / served
	
	# Calculate penalty from missed customers
	var total_customers = served + missed
	var missed_ratio = float(missed) / max(total_customers, 1)
	
	# Apply penalty - more missed customers = bigger penalty
	var final_satisfaction = base_satisfaction * (1.0 - (missed_ratio * MISSED_CUSTOMER_PENALTY))
	
	# Clamp between 0 and 100
	return clamp(final_satisfaction, 0.0, 100.0)

func update_satisfaction(served: int, missed: int, satisfaction_total: float) -> void:
	var daily_satisfaction = calculate_daily_satisfaction(served, missed, satisfaction_total)
	
	# Add to history
	satisfaction_history.push_back(daily_satisfaction)
	if satisfaction_history.size() > SATISFACTION_HISTORY_SIZE:
		satisfaction_history.pop_front()
	
	# Update reputation based on rolling average
	var avg_satisfaction = get_average_satisfaction()
	update_reputation(avg_satisfaction)

func get_average_satisfaction() -> float:
	if satisfaction_history.is_empty():
		return 0.0
	
	var total = 0.0
	for s in satisfaction_history:
		total += s
	
	return total / satisfaction_history.size()

func update_reputation(satisfaction_rate: float) -> void:
	var old_reputation = reputation
	
	# More dramatic reputation changes based on satisfaction
	if satisfaction_rate >= 90.0:
		reputation = min(reputation + 1, 5)
	elif satisfaction_rate >= 75.0:
		# No change for acceptable performance
		pass
	elif satisfaction_rate <= 50.0:
		reputation = max(reputation - 1, 1)
	elif satisfaction_rate <= 25.0:
		reputation = max(reputation - 2, 1)  # Bigger penalty for very poor performance
	
	if reputation != old_reputation:
		emit_signal("reputation_changed", reputation)

func reset_daily_revenue() -> void:
	daily_revenue = 0.0

func update_weather() -> void:
	var weather_types = ["sunny", "rainy", "cold", "hot"]
	current_weather = weather_types[randi() % weather_types.size()]

func update_cumulative_stats(daily_stats: Dictionary) -> void:
	cumulative_stats.total_customers_served += daily_stats.get("customers_served", 0)
	cumulative_stats.total_customers_missed += daily_stats.get("customers_missed", 0) 
	cumulative_stats.total_days_played += 1
	cumulative_stats.total_revenue += daily_stats.get("revenue", 0.0)
	
	# NEW - Update cost tracking
	cumulative_stats.total_restock_costs += daily_stats.get("restock_costs", 0.0)
	cumulative_stats.total_milk_costs += daily_stats.get("milk_costs", 0.0)
	cumulative_stats.total_milk_spoiled_units += daily_stats.get("milk_spoiled_units", 0.0)
	cumulative_stats.total_milk_spoiled_value += daily_stats.get("milk_spoiled_value", 0.0)
	cumulative_stats.total_costs = cumulative_stats.total_restock_costs + cumulative_stats.total_milk_costs + cumulative_stats.total_milk_spoiled_value
	
	var daily_profit = daily_stats.get("profit", 0.0)
	if daily_profit > cumulative_stats.best_daily_profit:
		cumulative_stats.best_daily_profit = daily_profit
	
	if daily_stats.get("customers_missed", 0) == 0:
		cumulative_stats.perfect_days += 1

func print_cumulative_stats() -> void:
	print("=== CUMULATIVE STATISTICS ===")
	print("Total Days Played: ", cumulative_stats.total_days_played)
	print("Total Customers Served: ", cumulative_stats.total_customers_served)
	print("Total Customers Missed: ", cumulative_stats.total_customers_missed)
	print("Total Revenue: £%.2f" % cumulative_stats.total_revenue)
	print("Best Daily Profit: £%.2f" % cumulative_stats.best_daily_profit)
	print("Perfect Days: ", cumulative_stats.perfect_days)
	print("Tea Types Unlocked: ", cumulative_stats.tea_types_unlocked)
	# NEW - Print cost statistics
	print("--- COSTS ---")
	print("Total Restock Costs: £%.2f" % cumulative_stats.total_restock_costs)
	print("Total Milk Costs: £%.2f" % cumulative_stats.total_milk_costs)
	print("Total Milk Spoiled: %.1f units (£%.2f)" % [cumulative_stats.total_milk_spoiled_units, cumulative_stats.total_milk_spoiled_value])
	print("Total All Costs: £%.2f" % cumulative_stats.total_costs)
	print("Net Profit (Revenue - Costs): £%.2f" % (cumulative_stats.total_revenue - cumulative_stats.total_costs))
	print("==============================")
