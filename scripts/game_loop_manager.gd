# game_loop_manager.gd
extends Node

enum GamePhase {
	MORNING_PREP,
	DAY_OPERATION,
	EVENING_REVIEW
}

const MIN_CUSTOMERS_PER_DAY = 30
const MAX_CUSTOMERS_PER_DAY = 60

var current_phase: GamePhase = GamePhase.MORNING_PREP
var day_timer: float = 0.0
var phase_duration: float = 180.0  # 3 minutes per phase

# Customer tracking
var total_customers_today: int = 0
var max_customers_today: int = 0
var customer_spawn_timer: float = 0.0
var base_spawn_interval: float = 5.0  # Seconds between customers

# System references
@onready var inventory: InventorySystem = $InventorySystem
@onready var customer_demand: CustomerDemand = $CustomerDemand
@onready var tea_manager: TeaManager = $TeaManager

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
	# Check if we've hit our customer limit
	var remaining_time = phase_duration - day_timer
	var remaining_customers = max_customers_today - total_customers_today
	
	if remaining_customers <= 0:
		return 999.0  # No more customers today
	
	# Base interval calculation
	var weather_modifier = 1.0
	match GameState.current_weather:
		"sunny": weather_modifier = 0.7  # More frequent customers
		"rainy": weather_modifier = 1.2  # Less frequent customers
	
	var time_of_day = day_timer / phase_duration
	var rush_hour_modifier = 1.0
	if time_of_day > 0.3 and time_of_day < 0.7:  # Rush hour
		rush_hour_modifier = 0.6  # More frequent customers
	
	# Adjust base interval to try to spread remaining customers over remaining time
	var target_interval = remaining_time / remaining_customers
	return max(base_spawn_interval, target_interval) * weather_modifier * rush_hour_modifier

func _try_spawn_customer() -> void:
	# Check if we've hit our customer limit for today
	if total_customers_today >= max_customers_today:
		return
		
	var generated = customer_demand.generate_customer()
	var customer = GameTypes.Customer.new(
		generated.type,
		30.0,  # wait time
		generated.tea_preference
	)
	
	if customer_demand.try_add_customer(customer.tea_preference):
		total_customers_today += 1
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
	
	# Calculate satisfaction including penalties
	var served = customer_demand.daily_stats.served
	var missed = customer_demand.daily_stats.missed.out_of_stock + customer_demand.daily_stats.missed.too_busy
	var satisfaction_total = customer_demand.get_total_satisfaction()
	
	# Update global satisfaction in GameState
	GameState.update_satisfaction(served, missed, satisfaction_total)
	
	var daily_summary = {
		"customers": {
			"total_potential": customer_demand.daily_stats.total_potential,
			"served": served,
			"missed": customer_demand.daily_stats.missed
		},
		"inventory": {
			"costs": inventory.daily_costs,
			"stock_levels": {}
		},
		"revenue": GameState.daily_revenue,
		"service_rate": customer_demand.get_service_rate(),
		"satisfaction": GameState.calculate_daily_satisfaction(served, missed, satisfaction_total),
		"average_satisfaction": GameState.get_average_satisfaction()
	}
	
	# Get end-of-day stock levels
	for tea_name in TeaManager.TEA_DATA:
		daily_summary.inventory.stock_levels[tea_name] = inventory.get_stock_level(tea_name)
	
	Events.emit_signal("day_ended", GameState.current_day, daily_summary)

func start_day() -> void:
	current_phase = GamePhase.DAY_OPERATION
	day_timer = 0.0
	customer_spawn_timer = 0.0
	
	# Set random customer count for today
	max_customers_today = randi_range(MIN_CUSTOMERS_PER_DAY, MAX_CUSTOMERS_PER_DAY)
	total_customers_today = 0
	
	# Reset daily tracking
	customer_demand.reset_daily_stats()
	inventory.reset_daily_costs()
	GameState.reset_daily_revenue()
	
	Events.emit_signal("day_started", GameState.current_day)
	
func _on_day_started(_day: int) -> void:
	tea_manager.check_unlocks(GameState.current_day, GameState.reputation)
