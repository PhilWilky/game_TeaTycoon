extends Control

# Scene References
@onready var customer_queue_scene = preload("res://scenes/customer_queue.tscn")
@onready var tea_grid = $MarginContainer/MainLayout/TabContainer/Menu/GridContainer
@onready var weather_label = $MarginContainer/MainLayout/AlertPanel/AlertLabel
@onready var start_day_button = $MarginContainer/MainLayout/ActionButtons/StartDayButton
@onready var save_button = $MarginContainer/MainLayout/ActionButtons/SaveButton
@onready var money_label = $MarginContainer/MainLayout/TopBar/MoneyContainer/MoneyLabel
@onready var reputation_label = $MarginContainer/MainLayout/TopBar/ReputationContainer/ReputationLabel
@onready var phase_panel_scene = preload("res://scenes/phase_panel.tscn")
@onready var phase_panel = null

# Systems
var inventory_system: InventorySystem
var customer_demand: CustomerDemand
var customer_queue_instance: Node
@onready var milk_system: MilkSystem

# Game Constants
const DAY_DURATION = 180.0  # 3 minutes in seconds
const MIN_CUSTOMERS_PER_DAY = 15
const MAX_CUSTOMERS_PER_DAY = 30

# Game Phases
enum GamePhase {
	MORNING_PREP,
	DAY_OPERATION,
	EVENING_REVIEW
}

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
	print("TeaShop: Initializing...")
	_init_systems()
	_connect_signals()
	
	if $MarginContainer/MainLayout/TabContainer/Inventory/InventoryPanel:
		print("Found inventory panel, setting up...")
		var panel = $MarginContainer/MainLayout/TabContainer/Inventory/InventoryPanel
		panel.setup(inventory_system, milk_system)
	else:
		print("ERROR: Could not find inventory panel")
	
	_setup_phase_panel()
	_setup_initial_tea_cards()
	_setup_customer_queue()
	_update_weather_display()
	_update_ui()
	daily_stats = _init_daily_stats()
	print("TeaShop: Initialization complete")

func _init_systems() -> void:
	print("TeaShop: Initializing game systems...")
	inventory_system = InventorySystem.new()
	add_child(inventory_system)
	
	milk_system = MilkSystem.new()
	add_child(milk_system)
	
	customer_demand = CustomerDemand.new()
	customer_demand.setup(inventory_system)
	
	if not GameState.is_initialized:
		GameState.initialize()
	print("TeaShop: Game systems initialized")

func _connect_signals() -> void:
	print("TeaShop: Connecting signals...")
	
	if start_day_button:
		start_day_button.pressed.connect(_on_start_day)
	if save_button:
		save_button.pressed.connect(_on_save_game)
	
	GameState.money_changed.connect(_on_money_changed)
	GameState.reputation_changed.connect(_on_reputation_changed)
	
	Events.tea_unlocked.connect(_on_tea_unlocked)
	Events.customer_entered.connect(_on_customer_entered)
	Events.customer_left.connect(_on_customer_left)
	Events.customer_served.connect(_on_customer_served)
	Events.money_changed.connect(_on_money_changed)
	Events.reputation_changed.connect(_on_reputation_changed)
	
	if customer_demand:
		customer_demand.customer_missed.connect(_on_customer_missed)
	if inventory_system:
		inventory_system.stock_changed.connect(_on_stock_changed)
		inventory_system.stock_depleted.connect(_on_stock_depleted)
	
	print("TeaShop: Signals connected")

func _setup_phase_panel() -> void:
	phase_panel = phase_panel_scene.instantiate()
	var top_bar = $MarginContainer/MainLayout/TopBar
	top_bar.add_child(phase_panel)
	phase_panel.set_day(1)
	phase_panel.set_phase(GamePhase.MORNING_PREP)

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
		
		if tea_data.unlocked:
			inventory_system.initialize_tea(tea_data.name)

func _process(delta: float) -> void:
	if is_day_running:
		_process_day_simulation(delta)

func _process_day_simulation(delta: float) -> void:
	day_timer += delta
	
	if day_timer >= DAY_DURATION or _should_end_day():
		_end_day()
		return
	
	customer_spawn_timer += delta
	if customer_spawn_timer >= _get_spawn_interval():
		customer_spawn_timer = 0.0
		_try_spawn_customer()

func _should_end_day() -> bool:
	return day_timer >= DAY_DURATION

func _get_spawn_interval() -> float:
	var base_interval = 2.0
	var time_of_day = day_timer / DAY_DURATION
	
	var rush_modifier = 1.0
	if time_of_day > 0.3 and time_of_day < 0.7:
		rush_modifier = 0.6
	
	var weather_mod = WEATHER_MODIFIERS[GameState.current_weather].get("customers", 1.0)
	
	return base_interval * rush_modifier * weather_mod

func _try_spawn_customer() -> void:
	if not customer_queue_instance:
		return
	
	if customer_queue_instance.is_full():
		_process_missed_customer(CustomerDemand.MissReason.TOO_BUSY)
		return
	
	var reputation_modifier = 0.5 + (GameState.reputation * 0.1)
	if randf() > reputation_modifier:
		return
	
	var customer = GameTypes.Customer.new(_get_random_customer_type(), 30.0)
	var tea_data = _get_tea_data(customer.tea_preference)
	
	if tea_data and tea_data.unlocked and inventory_system.has_stock(customer.tea_preference):
		if customer_queue_instance.add_customer():
			var timer = get_tree().create_timer(randf_range(3.0, 5.0))
			timer.timeout.connect(_process_customer_order.bind(customer))
	else:
		_process_missed_customer(
			CustomerDemand.MissReason.NO_TEA_TYPE if not tea_data.unlocked 
			else CustomerDemand.MissReason.OUT_OF_STOCK
		)

func _process_customer_order(customer: GameTypes.Customer) -> void:
	if not customer_queue_instance or not is_day_running:
		return
	
	var tea_data = _get_tea_data(customer.tea_preference)
	
	# First check if we have milk (since all customers want milk)
	if not milk_system.use_milk():
		_process_missed_customer(CustomerDemand.MissReason.NO_MILK)
		return
	
	# Check if we still have tea stock
	if not inventory_system.has_stock(customer.tea_preference):
		_process_missed_customer(CustomerDemand.MissReason.OUT_OF_STOCK)
		return
	
	# Try to use tea from inventory
	if inventory_system.use_tea(customer.tea_preference):
		var satisfaction = _calculate_satisfaction(customer)
		var revenue = tea_data.price
		
		daily_stats.revenue += revenue
		daily_stats.costs += tea_data.cost
		daily_stats.satisfaction_total += satisfaction * 100
		daily_stats.customers_served += 1
		
		if not daily_stats.tea_sold.has(customer.tea_preference):
			daily_stats.tea_sold[customer.tea_preference] = 0
		daily_stats.tea_sold[customer.tea_preference] += 1
		
		GameState.add_money(revenue)
		
		Events.emit_signal("customer_served", {
			"type": customer.type,
			"tea": customer.tea_preference,
			"satisfaction": satisfaction,
			"revenue": revenue
		}, satisfaction)
	else:
		_process_missed_customer(CustomerDemand.MissReason.OUT_OF_STOCK)
	
	customer_queue_instance.remove_customer()
	_update_ui()

func _process_missed_customer(reason: CustomerDemand.MissReason) -> void:
	daily_stats.customers_missed += 1
	
	match reason:
		CustomerDemand.MissReason.TOO_BUSY:
			daily_stats.satisfaction_total -= 20.0
			print("Customer missed - Queue full")
		CustomerDemand.MissReason.OUT_OF_STOCK:
			daily_stats.satisfaction_total -= 30.0
			print("Customer missed - Out of stock")
		CustomerDemand.MissReason.NO_TEA_TYPE:
			daily_stats.satisfaction_total -= 10.0
			print("Customer missed - Tea not unlocked")
		CustomerDemand.MissReason.NO_MILK:
			daily_stats.satisfaction_total -= 40.0
			GameState.reputation = max(GameState.reputation - 1, 1)
			print("Customer missed - No milk available")
	
	Events.emit_signal("customer_missed", reason)
	
	if customer_queue_instance and reason != CustomerDemand.MissReason.TOO_BUSY:
		customer_queue_instance.remove_customer()

func _calculate_satisfaction(customer: GameTypes.Customer) -> float:
	var tea_data = _get_tea_data(customer.tea_preference)
	if not tea_data:
		return 0.0
	
	var base_satisfaction = float(tea_data.satisfaction) / 100.0
	
	var queue_penalty = 0.0
	if customer_queue_instance:
		queue_penalty = customer_queue_instance.get_queue_size() * 0.05
	
	var weather_bonus = 0.0
	match GameState.current_weather:
		"rainy":
			if customer.tea_preference == "Builder's Tea":
				weather_bonus = 0.1
		"cold":
			if customer.tea_preference != "Iced Tea":
				weather_bonus = 0.15
		"hot":
			weather_bonus = -0.05
	
	var type_modifier = 1.0
	match customer.type:
		"regular":
			type_modifier = 1.0
		"business":
			type_modifier = 0.9
		"connoisseur":
			type_modifier = 0.8
	
	var final_satisfaction = (base_satisfaction - queue_penalty + weather_bonus) * type_modifier
	return clamp(final_satisfaction, 0.0, 1.0)

func _end_day() -> void:
	print("TeaShop: Ending day...")
	is_day_running = false
	
	# Handle milk spoilage at end of day
	milk_system.end_day()
	
	if start_day_button:
		start_day_button.disabled = false
	
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
	
	emit_signal("day_ended", final_stats)
	Events.emit_signal("day_ended", GameState.current_day, final_stats)
	
	if customer_queue_instance:
		customer_queue_instance.clear_queue()
	
	print("TeaShop: Day ended with stats:", final_stats)

func _on_start_day() -> void:
	print("TeaShop: Starting new day...")
	if is_day_running:
		return
	
	is_day_running = true
	day_timer = 0.0
	customer_spawn_timer = 0.0
	daily_stats = _init_daily_stats()
	
	GameState.current_day += 1
	GameState.update_weather()
	GameState.reset_daily_revenue()
	
	inventory_system.reset_daily_costs()
	if customer_queue_instance:
		customer_queue_instance.clear_queue()
	
	_update_weather_display()
	_update_ui()
	
	if phase_panel:
		phase_panel.set_phase(GamePhase.DAY_OPERATION)
	
	if start_day_button:
		start_day_button.disabled = true
	
	_check_unlocks()
	Events.emit_signal("day_started", GameState.current_day)
	print("TeaShop: Day", GameState.current_day, "started")

func _check_unlocks() -> void:
	if GameState.current_day >= 3:
		_unlock_tea("Earl Grey")
	if GameState.reputation >= 3:
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
			print("TeaShop: Unlocked new tea -", tea_name)

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

func _init_daily_stats() -> Dictionary:
	return {
		"revenue": 0.0,
		"costs": 0.0,
		"customers_served": 0,
		"customers_missed": 0,
		"satisfaction_total": 0.0,
		"tea_sold": {}
	}

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
	
	var day_label = $MarginContainer/MainLayout/TopBar/DayContainer/DayLabel
	if day_label:
		day_label.text = "Day %d" % GameState.current_day
	
	if tea_grid:
		for tea_card in tea_grid.get_children():
			if tea_card.tea_data:
				var current_stock = inventory_system.get_stock(tea_card.tea_data.get("name", ""))
				tea_card.update_stock(current_stock)
	
	if customer_queue_instance:
		customer_queue_instance.update_display()

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
	if tea_grid:
		for tea_card in tea_grid.get_children():
			if tea_card.tea_data.get("name", "") == tea_name:
				tea_card.update_stock(amount)
				break

func _on_stock_depleted(tea_name: String) -> void:
	print("WARNING: %s stock depleted!" % tea_name)
	Events.emit_signal("show_notification", "Stock Alert", "%s is out of stock!" % tea_name, "warning")

func _on_money_changed(new_amount: float) -> void:
	if money_label:
		money_label.text = "£%.2f" % new_amount

func _on_reputation_changed(new_value: int) -> void:
	if reputation_label:
		reputation_label.text = str(new_value)
	_check_unlocks()

func _on_tea_unlocked(tea_name: String) -> void:
	print("Tea unlocked: ", tea_name)
	Events.emit_signal("show_notification", "New Tea!", "%s is now available!" % tea_name, "success")
	_update_ui()
