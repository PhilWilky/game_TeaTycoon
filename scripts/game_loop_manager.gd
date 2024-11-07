# game_loop_manager.gd
extends Node

enum GamePhase {
	MORNING_PREP,
	DAY_OPERATION,
	EVENING_REVIEW
}

var current_phase: GamePhase = GamePhase.MORNING_PREP
var day_timer: float = 0.0
var phase_duration: float = 180.0  # 3 minutes per phase

# System references
@onready var inventory: InventorySystem = $InventorySystem
@onready var customer_demand: CustomerDemand = $CustomerDemand
@onready var tea_manager: TeaManager = $TeaManager

# Customer generation
var customer_spawn_timer: float = 0.0
var base_spawn_interval: float = 5.0  # Seconds between customers

func _ready() -> void:
	Events.connect("day_started", _on_day_started)
	initialize_systems()

func initialize_systems() -> void:
	# Initialize inventory for each tea type
	for tea_name in TeaManager.TEA_DATA:
		inventory.initialize_tea(tea_name)

func _process(delta: float) -> void:
	match current_phase:
		GamePhase.DAY_OPERATION:
			_process_day_operation(delta)
		GamePhase.EVENING_REVIEW:
			# Evening review is handled by UI interaction
			pass
		GamePhase.MORNING_PREP:
			# Morning prep is handled by UI interaction
			pass

func _process_day_operation(delta: float) -> void:
	day_timer += delta
	
	if day_timer >= phase_duration:
		_end_day_operation()
		return
	
	customer_spawn_timer += delta
	if customer_spawn_timer >= _get_current_spawn_interval():
		customer_spawn_timer = 0.0
		_try_spawn_customer()

func _get_current_spawn_interval() -> float:
	var weather_modifier = 1.0
	match GameState.current_weather:
		"sunny": weather_modifier = 0.7  # More frequent customers
		"rainy": weather_modifier = 1.2  # Less frequent customers
	
	var time_of_day = day_timer / phase_duration
	var rush_hour_modifier = 1.0
	if time_of_day > 0.3 and time_of_day < 0.7:  # Rush hour
		rush_hour_modifier = 0.6  # More frequent customers
	
	return base_spawn_interval * weather_modifier * rush_hour_modifier

func _try_spawn_customer() -> void:
	var customer = GameTypes.Customer.new(_get_random_customer_type(), 30.0)
	
	# First try to add to visual queue
	if customer_demand.try_add_customer(customer.tea_preference):
		Events.emit_signal("customer_entered", customer)
		_process_customer_order(customer)

func _process_customer_order(customer: GameTypes.Customer) -> void:
	if inventory.use_tea(customer.tea_preference):
		var satisfaction = _calculate_satisfaction(customer)
		Events.emit_signal("customer_served", customer, satisfaction)
		
		var revenue = tea_manager.prices[customer.tea_preference]
		GameState.add_money(revenue)

func _calculate_satisfaction(customer: GameTypes.Customer) -> float:
	var base_satisfaction = tea_manager.get_base_satisfaction(customer.tea_preference)
	var queue_penalty = customer_demand.current_queue_size * 0.05
	var weather_bonus = 0.0
	
	if GameState.current_weather == "rainy" and customer.tea_preference == "Builder's Tea":
		weather_bonus = 0.1
	elif GameState.current_weather == "cold" and customer.tea_preference != "Iced Tea":
		weather_bonus = 0.15
	
	return clamp(base_satisfaction - queue_penalty + weather_bonus, 0.0, 1.0)

func _end_day_operation() -> void:
	current_phase = GamePhase.EVENING_REVIEW
	
	var daily_summary = {
		"customers": {
			"total_potential": customer_demand.daily_stats.total_potential,
			"served": customer_demand.daily_stats.served,
			"missed": customer_demand.daily_stats.missed
		},
		"inventory": {
			"costs": inventory.daily_costs,
			"stock_levels": {}
		},
		"revenue": GameState.daily_revenue,
		"service_rate": customer_demand.get_service_rate()
	}
	
	# Get end-of-day stock levels
	for tea_name in TeaManager.TEA_DATA:
		daily_summary.inventory.stock_levels[tea_name] = inventory.get_stock_level(tea_name)
	
	Events.emit_signal("day_ended", GameState.current_day, daily_summary)

func start_day() -> void:
	current_phase = GamePhase.DAY_OPERATION
	day_timer = 0.0
	customer_spawn_timer = 0.0
	
	# Reset daily tracking
	customer_demand.reset_daily_stats()
	inventory.reset_daily_costs()
	GameState.reset_daily_revenue()
	
	Events.emit_signal("day_started", GameState.current_day)

func _on_day_started(_day: int) -> void:
	tea_manager.check_unlocks(GameState.current_day, GameState.reputation)

# Helper functions
func _get_random_customer_type() -> String:
	var roll = randf()
	if roll < 0.5:
		return "regular"
	elif roll < 0.8:
		return "business"
	else:
		return "connoisseur"
