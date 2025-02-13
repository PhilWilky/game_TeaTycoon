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
