# tea_shop.gd
extends Control
const TabNotificationSystem = preload("res://scripts/ui/tab_notification_system.gd")

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
var tab_notification_system: TabNotificationSystem

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
	
		# Enable input processing for debug shortcuts
	set_process_unhandled_input(true)

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
	
	# Create PhaseManager first
	phase_manager = PhaseManager.new()
	add_child(phase_manager)
	phase_manager.setup(inventory_system, null, milk_system)  # Setup without CustomerManager first
	
	# Create CustomerManager and connect it to PhaseManager
	customer_manager = CustomerManager.new()
	add_child(customer_manager)
	customer_manager.setup(phase_manager, inventory_system, milk_system, customer_queue_instance)
	
	# Now update PhaseManager with CustomerManager reference
	phase_manager.customer_manager = customer_manager
	
	print("TeaShop: Managers initialized")

func _setup_ui() -> void:
	print("TeaShop: Setting up UI...")
	# Setup phase panel
	phase_panel = phase_panel_scene.instantiate()
	var top_bar = $MarginContainer/MainLayout/TopBar
	top_bar.add_child(phase_panel)
	phase_panel.set_day(GameState.current_day)
	
		# Initialize tab notification system
	var tab_container = $MarginContainer/MainLayout/TabContainer
	if tab_container:
		tab_notification_system = TabNotificationSystem.new(tab_container)

	# Setup tea cards
	_setup_initial_tea_cards()
	
	# Setup inventory panel
	if $MarginContainer/MainLayout/TabContainer/Inventory/InventoryPanel:
		print("Found inventory panel, setting up...")
		var panel = $MarginContainer/MainLayout/TabContainer/Inventory/InventoryPanel
		panel.setup(inventory_system, milk_system, phase_manager)
	
	# Initialize empty reports tab with placeholder
	_populate_evening_reports({})

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
				start_day_button.text = "Start Day %d" % (GameState.current_day + 1)
		PhaseManager.Phase.DAY_OPERATION:
			if start_day_button:
				start_day_button.disabled = true
				start_day_button.text = "Day In Progress"
		PhaseManager.Phase.EVENING_REVIEW:
			if start_day_button:
				start_day_button.text = "Reviewing Day..."

func _on_day_started(day: int) -> void:
	_check_unlocks()
	_update_weather_display()
	_update_ui()
	if phase_panel:
		phase_panel.set_day(day)

func _on_day_ended(_day: int, stats: Dictionary) -> void:
	print("TeaShop: Day ended with stats:", stats)
	
	# Use notification system to switch to Reports tab with indicator
	var reports_tab = $MarginContainer/MainLayout/TabContainer/Reports
	if tab_notification_system and reports_tab:
		tab_notification_system.switch_to_tab_with_notification(reports_tab)
	
	# Create reports content
	_populate_evening_reports(stats)
	_update_ui()

func _populate_evening_reports(stats: Dictionary) -> void:
	var reports_tab = $MarginContainer/MainLayout/TabContainer/Reports
	if not reports_tab:
		return
	
	# Clear existing content
	for child in reports_tab.get_children():
		child.queue_free()
	
	# Show placeholder if day is in progress
	if phase_manager and phase_manager.get_current_phase() == PhaseManager.Phase.DAY_OPERATION:
		_show_reports_placeholder(reports_tab)
		return
	
	# Show actual reports if we have stats
	if stats.is_empty():
		_show_reports_placeholder(reports_tab)
		return
	
	# Create scroll container for reports
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reports_tab.add_child(scroll)
	
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	scroll.add_child(content)
	
	# Day header
	var header = Label.new()
	header.text = "Day %d Results" % stats.day
	header.add_theme_font_size_override("font_size", 24)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(header)
	
	# Key metrics panel
	_create_metrics_panel(content, stats)
	
	# Customer breakdown
	_create_customer_panel(content, stats)
	
	# Financial summary
	_create_financial_panel(content, stats)
	
	# Future multipliers panel
	_create_multipliers_panel(content, stats)


func _create_multipliers_panel(parent: VBoxContainer, stats: Dictionary) -> void:
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	
	var title = Label.new()
	title.text = "Business Modifiers"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# TODO placeholders for future systems
	var todo_items = [
		"Staff Efficiency: Coming Soon",
		"Location Bonuses: Coming Soon", 
		"Advertising Effects: Coming Soon",
		"Equipment Upgrades: Coming Soon"
	]
	
	for item in todo_items:
		var label = Label.new()
		label.text = "• " + item
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		vbox.add_child(label)
	
	panel.add_child(vbox)
	parent.add_child(panel)

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

func _create_metrics_panel(parent: VBoxContainer, stats: Dictionary) -> void:
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	
	var title = Label.new()
	title.text = "Key Metrics"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Weather display
	var weather_container = HBoxContainer.new()
	var weather_label = Label.new()
	weather_label.text = "Weather: "
	var weather_value = Label.new()
	
	match stats.get("weather", "sunny"):
		"sunny": weather_value.text = "☀️ Sunny"
		"rainy": weather_value.text = "🌧️ Rainy"
		"cold": weather_value.text = "❄️ Cold"
		"hot": weather_value.text = "🌡️ Hot"
		_: weather_value.text = "Unknown"
	
	weather_container.add_child(weather_label)
	weather_container.add_child(weather_value)
	vbox.add_child(weather_container)
	
	# Create metrics grid
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 10)
	
	# Revenue
	var revenue_label = Label.new()
	revenue_label.text = "Revenue"
	var revenue_value = Label.new()
	revenue_value.text = "£%.2f" % stats.get("revenue", 0.0)
	revenue_value.add_theme_color_override("font_color", Color.GREEN)
	
	# Customers Served
	var customers_label = Label.new()
	customers_label.text = "Served"
	var customers_value = Label.new()
	customers_value.text = str(stats.get("customers_served", 0))
	
	# Customers Missed
	var missed_label = Label.new()
	missed_label.text = "Missed" 
	var missed_value = Label.new()
	missed_value.text = str(stats.get("customers_missed", 0))
	missed_value.add_theme_color_override("font_color", Color.RED)
	
	# Satisfaction
	var satisfaction_label = Label.new()
	satisfaction_label.text = "Satisfaction"
	var satisfaction_value = Label.new()
	satisfaction_value.text = "%.1f%%" % (stats.get("satisfaction_avg", 0.0) * 100)
	
	grid.add_child(revenue_label)
	grid.add_child(customers_label)
	grid.add_child(missed_label) 
	grid.add_child(satisfaction_label)
	grid.add_child(revenue_value)
	grid.add_child(customers_value)
	grid.add_child(missed_value)
	grid.add_child(satisfaction_value)
	
	vbox.add_child(grid)
	panel.add_child(vbox)
	parent.add_child(panel)

func _create_customer_panel(parent: VBoxContainer, stats: Dictionary) -> void:
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	
	var title = Label.new()
	title.text = "Customer Breakdown"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var tea_sold = stats.get("tea_sold", {})
	for tea_name in tea_sold:
		var hbox = HBoxContainer.new()
		var name_label = Label.new()
		name_label.text = tea_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var count_label = Label.new()
		count_label.text = str(tea_sold[tea_name])
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		
		hbox.add_child(name_label)
		hbox.add_child(count_label)
		vbox.add_child(hbox)
	
	panel.add_child(vbox)
	parent.add_child(panel)

func _create_financial_panel(parent: VBoxContainer, stats: Dictionary) -> void:
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	
	var title = Label.new()
	title.text = "Financial Summary"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Profit calculation
	var revenue = stats.get("revenue", 0.0)
	var costs = inventory_system.daily_costs if inventory_system else 0.0
	var profit = revenue - costs
	
	var profit_hbox = HBoxContainer.new()
	var profit_label = Label.new()
	profit_label.text = "Profit:"
	profit_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var profit_value = Label.new()
	profit_value.text = "£%.2f" % profit
	profit_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	profit_value.add_theme_color_override("font_color", Color.GREEN if profit > 0 else Color.RED)
	
	profit_hbox.add_child(profit_label)
	profit_hbox.add_child(profit_value)
	vbox.add_child(profit_hbox)
	
	panel.add_child(vbox)
	parent.add_child(panel)
	
func _unhandled_input(event: InputEvent) -> void:
	# Debug shortcut: Press 'E' to end day early
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			if phase_manager and phase_manager.get_current_phase() == PhaseManager.Phase.DAY_OPERATION:
				print("DEBUG: Ending day early via shortcut")
				phase_manager.end_day()
				get_viewport().set_input_as_handled()
		# Add this new shortcut
		elif event.keycode == KEY_S:
			print("DEBUG: Printing cumulative stats")
			GameState.print_cumulative_stats()
			get_viewport().set_input_as_handled()

func _show_reports_placeholder(reports_tab: Control) -> void:
	var placeholder = VBoxContainer.new()
	placeholder.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	placeholder.add_theme_constant_override("separation", 16)
	
	var icon = Label.new()
	icon.text = "📊"
	icon.add_theme_font_size_override("font_size", 48)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_child(icon)
	
	var title = Label.new()
	title.text = "Daily Reports"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_child(title)
	
	var message = Label.new()
	message.text = "Reports will be available at the end of the day\nduring tomorrow's preparation phase."
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	placeholder.add_child(message)
	
	reports_tab.add_child(placeholder)
