# tea_shop.gd
extends Control

# Scene References
@onready var tea_grid = $MarginContainer/MainLayout/TabContainer/Menu/GridContainer
@onready var weather_label = $MarginContainer/MainLayout/AlertPanel/AlertLabel
@onready var start_day_button = $MarginContainer/MainLayout/ActionButtons/StartDayButton
@onready var save_button = $MarginContainer/MainLayout/ActionButtons/SaveButton
@onready var money_label = $MarginContainer/MainLayout/TopBar/MoneyContainer/MoneyLabel
@onready var reputation_label = $MarginContainer/MainLayout/TopBar/ReputationContainer/ReputationLabel

# Preloaded scenes
@onready var customer_queue_scene = preload("res://scenes/customer_queue.tscn")
@onready var phase_panel_scene = preload("res://scenes/phase_panel.tscn")

# Core systems
var inventory_system: InventorySystem
var milk_system: MilkSystem
var customer_queue_instance: Node
var phase_panel: Node

# Managers
var phase_manager: PhaseManager
var customer_manager: CustomerManager
var stats_manager: StatsManager
var tea_production_manager: TeaProductionManager

# Initial tea configurations
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

func _ready() -> void:
	print("TeaShop: Initializing...")
	_init_systems()
	_init_managers()
	_connect_signals()
	_setup_ui()
	print("TeaShop: Initialization complete")

func _init_systems() -> void:
	print("TeaShop: Initializing game systems...")
	
	inventory_system = InventorySystem.new()
	add_child(inventory_system)
	
	milk_system = MilkSystem.new()
	add_child(milk_system)
	
	# Create customer queue first so it exists for the managers
	customer_queue_instance = customer_queue_scene.instantiate()
	$MarginContainer/MainLayout.add_child(customer_queue_instance)
	customer_queue_instance.set_anchors_preset(Control.PRESET_TOP_WIDE)
	print("TeaShop: Customer queue initialized")
	
	if not GameState.is_initialized:
		GameState.initialize()
	
	print("TeaShop: Game systems initialized")

func _init_managers() -> void:
	print("TeaShop: Initializing managers...")
	
	# Create and setup StatsManager (first as others depend on it)
	stats_manager = StatsManager.new()
	add_child(stats_manager)
	
	# Create and setup TeaProductionManager
	tea_production_manager = TeaProductionManager.new()
	add_child(tea_production_manager)
	tea_production_manager.setup(inventory_system, milk_system)
	
	# Create and setup PhaseManager
	phase_manager = PhaseManager.new()
	add_child(phase_manager)
	phase_manager.setup(inventory_system, null, milk_system)  # CustomerDemand will be deprecated
	
	# Create and setup CustomerManager
	customer_manager = CustomerManager.new()
	add_child(customer_manager)
	customer_manager.setup(phase_manager, inventory_system, milk_system, customer_queue_instance)
	
	print("TeaShop: Managers initialized")

func _setup_ui() -> void:
	print("TeaShop: Setting up UI...")
	
	# Setup phase panel
	phase_panel = phase_panel_scene.instantiate()
	var top_bar = $MarginContainer/MainLayout/TopBar
	top_bar.add_child(phase_panel)
	phase_panel.set_day(1)
	
	# Setup tea cards
	_setup_initial_tea_cards()
	
	# Setup inventory panel
	if $MarginContainer/MainLayout/TabContainer/Inventory/InventoryPanel:
		print("Found inventory panel, setting up...")
		var panel = $MarginContainer/MainLayout/TabContainer/Inventory/InventoryPanel
		panel.setup(inventory_system, milk_system)
	
	_update_weather_display()
	_update_ui()
	
	print("TeaShop: UI setup complete")

func _connect_signals() -> void:
	print("TeaShop: Connecting signals...")
	
	# UI signals
	if start_day_button:
		start_day_button.pressed.connect(_on_start_day)
	if save_button:
		save_button.pressed.connect(_on_save_game)
	
	# Core game signals
	GameState.money_changed.connect(_on_money_changed)
	GameState.reputation_changed.connect(_on_reputation_changed)
	
	# Phase manager signals
	phase_manager.phase_changed.connect(_on_phase_changed)
	phase_manager.day_started.connect(_on_day_started)
	phase_manager.day_ended.connect(_on_day_ended)
	
	# Customer manager signals
	customer_manager.customer_served.connect(_on_customer_served)
	customer_manager.customer_missed.connect(_on_customer_missed)
	
	# Stats manager signals
	stats_manager.daily_stats_updated.connect(_on_stats_updated)
	
	# Tea production manager signals
	tea_production_manager.tea_prepared.connect(_on_tea_prepared)
	tea_production_manager.preparation_failed.connect(_on_tea_preparation_failed)
	
	# System signals
	inventory_system.stock_changed.connect(_on_stock_changed)
	inventory_system.stock_depleted.connect(_on_stock_depleted)
	
	print("TeaShop: Signals connected")

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

# Signal handlers
func _on_start_day() -> void:
	phase_manager.start_day()
	if start_day_button:
		start_day_button.disabled = true

func _on_phase_changed(new_phase: int) -> void:
	if phase_panel:
		phase_panel.set_phase(new_phase)
	
	match new_phase:
		PhaseManager.Phase.MORNING_PREP:
			if start_day_button:
				start_day_button.disabled = false
		PhaseManager.Phase.DAY_OPERATION:
			if start_day_button:
				start_day_button.disabled = true

func _on_day_started(day: int) -> void:
	_check_unlocks()
	_update_weather_display()
	_update_ui()

func _on_day_ended(_day: int, stats: Dictionary) -> void:
	_update_ui()

func _on_customer_served(customer_data: Dictionary, satisfaction: float) -> void:
	print("Customer served with satisfaction: %.1f%%" % (satisfaction * 100))

func _on_customer_missed(reason: int) -> void:
	match reason:
		CustomerDemand.MissReason.NO_TEA_TYPE:
			print("Customer missed - Tea not unlocked")
		CustomerDemand.MissReason.OUT_OF_STOCK:
			print("Customer missed - Out of stock")
		CustomerDemand.MissReason.TOO_BUSY:
			print("Customer missed - Queue full")
		CustomerDemand.MissReason.NO_MILK:
			print("Customer missed - No milk")
			GameState.reputation = max(GameState.reputation - 1, 1)

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

func _on_save_game() -> void:
	print("Save game functionality to be implemented")

func _on_stats_updated(stats: Dictionary) -> void:
	# Update UI elements that show live stats
	if tea_grid:
		for tea_card in tea_grid.get_children():
			if tea_card.tea_data and stats.tea_sold.has(tea_card.tea_data.name):
				tea_card.update_sales(stats.tea_sold[tea_card.tea_data.name])
	
	# Update any other UI elements that show live stats
	_update_ui()

func _on_tea_prepared(tea_name: String, quality: float) -> void:
	print("Tea prepared: %s with quality: %.2f" % [tea_name, quality])
	Events.emit_signal("show_notification", 
		"Tea Prepared", 
		"%s prepared with %.0f%% quality" % [tea_name, quality * 100],
		"success")

func _on_tea_preparation_failed(tea_name: String, reason: String) -> void:
	print("Tea preparation failed: %s - %s" % [tea_name, reason])
	Events.emit_signal("show_notification",
		"Preparation Failed",
		"Could not prepare %s: %s" % [tea_name, reason],
		"error")
