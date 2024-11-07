# game_state.gd
extends Node

signal money_changed(new_amount: float)
signal reputation_changed(new_value: int)

var is_initialized: bool = false
var current_day: int = 1
var money: float = 1000.0
var reputation: int = 3
var current_weather: String = "sunny"
var daily_revenue: float = 0.0

func initialize() -> void:
	if is_initialized:
		return
		
	is_initialized = true
	current_day = 1
	money = 1000.0
	reputation = 3
	current_weather = "sunny"
	daily_revenue = 0.0

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

func update_reputation(satisfaction_rate: float) -> void:
	var old_reputation = reputation
	
	if satisfaction_rate >= 0.9:
		reputation = min(reputation + 1, 5)
	elif satisfaction_rate <= 0.5:
		reputation = max(reputation - 1, 1)
	
	if reputation != old_reputation:
		emit_signal("reputation_changed", reputation)

func reset_daily_revenue() -> void:
	daily_revenue = 0.0

func update_weather() -> void:
	var weather_types = ["sunny", "rainy", "cold", "hot"]
	current_weather = weather_types[randi() % weather_types.size()]
