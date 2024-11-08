extends Control

# Scene References
@onready var customer_queue_scene = preload("res://scenes/customer_queue.tscn")
@onready var tea_grid = $MarginContainer/MainLayout/TabContainer/Menu/GridContainer
@onready var weather_label = $MarginContainer/MainLayout/AlertPanel/AlertLabel
@onready var start_day_button = $MarginContainer/MainLayout/ActionButtons/StartDayButton
@onready var save_button = $MarginContainer/MainLayout/ActionButtons/SaveButton
@onready var money_label = $MarginContainer/MainLayout/TopBar/MoneyContainer/MoneyLabel
@onready var reputation_label = $MarginContainer/MainLayout/TopBar/ReputationContainer/ReputationLabel

# Systems
var inventory_system: InventorySystem
var customer_demand: CustomerDemand
var customer_queue_instance: Node

# Game Constants
const DAY_DURATION = 180.0  # 3 minutes in seconds
const MIN_CUSTOMERS_PER_DAY = 15
const MAX_CUSTOMERS_PER_DAY = 30

# Weather modifiers
const WEATHER_MODIFIERS = {
	"sunny": {"customers": 1.3, "satisfaction": 1.1},
	"rainy": {"customers": 0.8, "tea_sales": 1.2},
	"cold": {"hot_tea": 1.4},
	"hot": {"iced_tea": 1.3}
}

# Game state
var is_day_running: bool = false
var day_timer: float = 0.0
var customer_spawn_timer: float = 0.0
var daily_stats = {
	"revenue": 0.0,
	"costs": 0.0,
	"customers_served": 0,
	"customers_missed": 0,
	"satisfaction_total": 0.0,
	"tea_sold": {}
}

# Tea Data
const INITIAL_TEA_DATA = [
	{
		"name": "Builder's Tea",
		"cost": 0.50,
		"price": 2.50,
		"quality": 3,
		"unlocked": true,
		"satisfaction": 75
	},
	{
		"name": "Earl Grey",
		"cost": 0.75,
		"price": 3.00,
		"quality": 4,
		"unlocked": false,
		"satisfaction": 85,
		"unlock_condition": "Day 3"
	},
	{
		"name": "Premium Blend",
		"cost": 1.20,
		"price": 4.50,
		"quality": 5,
		"unlocked": false,
		"satisfaction": 95,
		"unlock_condition": "Reputation 3"
	}
]

signal day_ended(stats: Dictionary)

func _ready() -> void:
	# Initialize systems
	_init_systems()
	
	# Connect signals
	_connect_signals()
	
	# Initial setup
	_setup_initial_tea_cards()
	_setup_customer_queue()
	_update_weather_display()
	_update_ui()
	
	# Initialize stats
	daily_stats = _init_daily_stats()

func _init_systems() -> void:
	inventory_system = InventorySystem.new()
	customer_demand = CustomerDemand.new()
	customer_demand.setup(inventory_system)
	
	# Initialize game state if needed
	if not GameState.is_initialized:
		GameState.initialize()

func _connect_signals() -> void:
	if start_day_button:
		start_day_button.pressed.connect(_on_start_day)
	if save_button:
		save_button.pressed.connect(_on_save_game)
		
	# Connect to Events autoload
	Events.customer_entered.connect(_on_customer_entered)
	Events.customer_left.connect(_on_customer_left)
	Events.customer_served.connect(_on_customer_served)
	Events.money_changed.connect(_on_money_changed)
	Events.reputation_changed.connect(_on_reputation_changed)
	
	# Connect system signals
	if customer_demand:
		customer_demand.customer_missed.connect(_on_customer_missed)
	if inventory_system:
		inventory_system.stock_changed.connect(_on_stock_changed)
		inventory_system.stock_depleted.connect(_on_stock_depleted)

func _init_daily_stats() -> Dictionary:
	return {
		"revenue": 0.0,
		"costs": 0.0,
		"customers_served": 0,
		"customers_missed": 0,
		"satisfaction_total": 0.0,
		"tea_sold": {}
	}

func _setup_customer_queue() -> void:
	customer_queue_instance = customer_queue_scene.instantiate()
	$MarginContainer/MainLayout.add_child(customer_queue_instance)
	customer_queue_instance.set_anchors_preset(Control.PRESET_TOP_WIDE)

func _setup_initial_tea_cards() -> void:
	if not tea_grid:
		push_error("Tea grid node not found!")
		return
		
	var tea_card_scene = preload("res://scenes/tea_card.tscn")
	
	for tea_data in INITIAL_TEA_DATA:
		var tea_card = tea_card_scene.instantiate()
		tea_grid.add_child(tea_card)
		tea_card.setup(tea_data.duplicate())
		
		# Initialize inventory for this tea
		if tea_data.unlocked:
			inventory_system.initialize_tea(tea_data.name)
func _process(delta: float) -> void:
	if is_day_running:
		_process_day_simulation(delta)

func _process_day_simulation(delta: float) -> void:
	day_timer += delta
	
	# Check for day end condition
	if day_timer >= DAY_DURATION or _should_end_day():
		_end_day()
		return
		
	customer_spawn_timer += delta
	if customer_spawn_timer >= _get_spawn_interval():
		customer_spawn_timer = 0.0
		_try_spawn_customer()

func _should_end_day() -> bool:
	# End day if we're out of stock and have no customers in queue
	var all_out_of_stock = true
	for tea_data in INITIAL_TEA_DATA:
		if tea_data.unlocked and inventory_system.has_stock(tea_data.name):
			all_out_of_stock = false
			break
	
	return all_out_of_stock and (not customer_queue_instance or customer_queue_instance.get_queue_size() == 0)

func _get_spawn_interval() -> float:
	var base_interval = 2.0  # Reduced for more frequent spawns
	var time_of_day = day_timer / DAY_DURATION
	
	# Rush hour modifier (busier during middle of day)
	var rush_modifier = 1.0
	if time_of_day > 0.3 and time_of_day < 0.7:
		rush_modifier = 0.6
	
	# Weather modifier
	var weather_mod = WEATHER_MODIFIERS[GameState.current_weather].get("customers", 1.0)
	
	return base_interval * rush_modifier * weather_mod

func _try_spawn_customer() -> void:
	if not customer_queue_instance:
		return
		
	# Only try to spawn if we haven't hit max queue size
	if customer_queue_instance.current_queue.size() >= customer_queue_instance.MAX_QUEUE_SIZE:
		daily_stats.customers_missed += 1
		print("Customer missed - Queue full")
		return
	
	var customer = GameTypes.Customer.new(_get_random_customer_type(), 30.0)
	var tea_data = _get_tea_data(customer.tea_preference)
	
	# Check if tea is unlocked and in stock
	if tea_data and tea_data.unlocked and inventory_system.has_stock(customer.tea_preference):
		if customer_queue_instance.add_customer():
			# Process the order after a delay
			var timer = get_tree().create_timer(randf_range(3.0, 5.0))
			timer.timeout.connect(_process_customer_order.bind(customer))
	else:
		daily_stats.customers_missed += 1
		if not tea_data.unlocked:
			print("Customer missed - Tea not unlocked: ", customer.tea_preference)
		else:
			print("Customer missed - Out of stock: ", customer.tea_preference)

func _process_customer_order(customer: GameTypes.Customer) -> void:
	if not customer_queue_instance or not is_day_running:
		return
		
	# Process the sale
	var tea_data = _get_tea_data(customer.tea_preference)
	if tea_data and inventory_system.use_tea(customer.tea_preference):
		# Calculate revenue and satisfaction
		var revenue = tea_data.price
		var satisfaction = _calculate_satisfaction(customer)
		
		# Update stats
		daily_stats.revenue += revenue
		daily_stats.costs += tea_data.cost
		daily_stats.satisfaction_total += satisfaction * 100  # Convert to percentage
		daily_stats.customers_served += 1
		
		# Update game state
		GameState.add_money(revenue)
		
		# Track tea sales
		if not daily_stats.tea_sold.has(customer.tea_preference):
			daily_stats.tea_sold[customer.tea_preference] = 0
		daily_stats.tea_sold[customer.tea_preference] += 1
		
		print("Customer served: %s - Revenue: £%.2f - Satisfaction: %.1f%%" % [
			customer.tea_preference,
			revenue,
			satisfaction * 100
		])
	
	# Remove customer from queue
	customer_queue_instance.remove_customer()

func _calculate_satisfaction(customer: GameTypes.Customer) -> float:
	var base_satisfaction = float(_get_tea_data(customer.tea_preference).satisfaction) / 100.0
	var queue_penalty = customer_queue_instance.current_queue.size() * 0.05
	var weather_bonus = 0.0
	
	# Apply weather bonuses
	match GameState.current_weather:
		"rainy":
			if customer.tea_preference == "Builder's Tea":
				weather_bonus = 0.1
		"cold":
			if customer.tea_preference != "Iced Tea":
				weather_bonus = 0.15
	
	return clamp(base_satisfaction - queue_penalty + weather_bonus, 0.0, 1.0)

func _end_day() -> void:
	is_day_running = false
	if start_day_button:
		start_day_button.disabled = false
	
	# Calculate final stats
	var avg_satisfaction = 0.0
	if daily_stats.customers_served > 0:
		avg_satisfaction = daily_stats.satisfaction_total / daily_stats.customers_served
	
	var final_stats = {
		"revenue": daily_stats.revenue,
		"costs": daily_stats.costs,
		"profit": daily_stats.revenue - daily_stats.costs,
		"customers_served": daily_stats.customers_served,
		"customers_missed": daily_stats.customers_missed,
		"satisfaction": avg_satisfaction,
		"tea_sold": daily_stats.tea_sold.duplicate()
	}
	
	# Format detailed end of day message
	var day_summary = "Day %d Complete!\n" % GameState.current_day
	day_summary += "Revenue: £%.2f\n" % final_stats.revenue
	day_summary += "Costs: £%.2f\n" % final_stats.costs
	day_summary += "Profit: £%.2f\n" % final_stats.profit
	day_summary += "Customers Served: %d\n" % final_stats.customers_served
	day_summary += "Customers Missed: %d\n" % final_stats.customers_missed
	day_summary += "Average Satisfaction: %.1f%%\n" % avg_satisfaction
	
	# Add tea sales breakdown
	day_summary += "Tea Sales:\n"
	for tea_name in final_stats.tea_sold:
		day_summary += "- %s: %d\n" % [tea_name, final_stats.tea_sold[tea_name]]
	
	print(day_summary)
	
	# Emit day ended signals
	emit_signal("day_ended", final_stats)
	Events.emit_signal("day_ended", GameState.current_day, final_stats)
	
	# Clean up
	if customer_queue_instance:
		customer_queue_instance.clear_queue()


func _on_start_day() -> void:
	if is_day_running:
		return
		
	is_day_running = true
	day_timer = 0.0
	customer_spawn_timer = 0.0
	
	# Reset systems
	customer_demand.reset_daily_stats()
	inventory_system.reset_daily_costs()
	daily_stats = _init_daily_stats()
	
	# Update game state
	GameState.current_day += 1
	GameState.update_weather()
	
	# Update UI
	_update_weather_display()
	if start_day_button:
		start_day_button.disabled = true
	
	# Check for unlocks
	_check_unlocks()

func _check_unlocks() -> void:
	if GameState.current_day >= 3:  # Unlock Earl Grey
		_unlock_tea("Earl Grey")
	if GameState.reputation >= 3:  # Unlock Premium Blend
		_unlock_tea("Premium Blend")

func _unlock_tea(tea_name: String) -> void:
	if not tea_grid:
		return
	
	for tea_card in tea_grid.get_children():
		if tea_card.tea_data.name == tea_name and not tea_card.tea_data.unlocked:
			var updated_data = tea_card.tea_data.duplicate()
			updated_data.unlocked = true
			tea_card.setup(updated_data)
			inventory_system.initialize_tea(tea_name)
			Events.emit_signal("tea_unlocked", tea_name)

func _get_random_customer_type() -> String:
	var roll = randf()
	if roll < 0.5:
		return "regular"
	elif roll < 0.8:
		return "business"
	else:
		return "connoisseur"

func _get_tea_data(tea_name: String) -> Dictionary:
	for tea in INITIAL_TEA_DATA:
		if tea.name == tea_name:
			return tea.duplicate()
	return {}

func _update_weather_display() -> void:
	if not weather_label:
		return
		
	match GameState.current_weather:
		"sunny":
			weather_label.text = "☀️ Sunny day! Expect 30% more customers today."
		"rainy":
			weather_label.text = "🌧️ Rainy day! Tea sales likely to increase by 20%."
		"cold":
			weather_label.text = "❄️ Cold day! Hot tea sales up by 40%."
		"hot":
			weather_label.text = "🌡️ Hot day! Iced tea sales up by 30%."

func _update_ui() -> void:
	if money_label:
		money_label.text = "£%.2f" % GameState.money
	if reputation_label:
		reputation_label.text = str(GameState.reputation)

func _on_save_game() -> void:
	print("Save game functionality to be implemented")

# Signal handlers
func _on_customer_entered(customer_data) -> void:
	print("Customer entered with tea preference: ", customer_data.tea_preference)

func _on_customer_left(customer_data) -> void:
	print("Customer left")

func _on_customer_served(customer_data, satisfaction: float) -> void:
	print("Customer served with satisfaction: %.1f%%" % (satisfaction * 100))

func _on_customer_missed(reason: int) -> void:
	print("Customer missed, reason: ", reason)

func _on_stock_changed(tea_name: String, amount: int) -> void:
	print("Stock changed for %s: %d" % [tea_name, amount])

func _on_stock_depleted(tea_name: String) -> void:
	print("WARNING: %s stock depleted!" % tea_name)

func _on_money_changed(new_amount: float) -> void:
	_update_ui()

func _on_reputation_changed(new_value: int) -> void:
	_update_ui()
	_check_unlocks()
