# tea_shop.gd
extends Control

# Node references
@onready var day_label = $MarginContainer/MainLayout/TopBar/DayContainer/DayLabel
@onready var money_label = $MarginContainer/MainLayout/TopBar/MoneyContainer/MoneyLabel
@onready var reputation_label = $MarginContainer/MainLayout/TopBar/ReputationContainer/ReputationLabel
@onready var alert_label = $MarginContainer/MainLayout/AlertPanel/AlertLabel
@onready var menu_grid = $MarginContainer/MainLayout/TabContainer/Menu/GridContainer
@onready var reports_container = $MarginContainer/MainLayout/TabContainer/Reports/StatsContainer

# Game state
var game_logic = preload("res://scripts/game_logic.gd").new()
var shop_state

func _ready():
	print("Tea Shop initializing...")
	shop_state = game_logic.TeaShopState.new(1000.0, 3)
	setup_basic_ui()
	connect_signals()
	update_ui()

func setup_basic_ui():
	update_tea_cards()
	update_weather_alert()

func update_tea_cards():
	# Clear existing cards
	for child in menu_grid.get_children():
		child.queue_free()
	
	var tea_scene = preload("res://scenes/tea_card.tscn")
	
	# Builder's Tea (always available)
	var basic_tea = tea_scene.instantiate()
	var basic_tea_data = GameTypes.TeaItem.new(
		"Builder's Tea", 
		0.50, 
		2.50, 
		3, 
		true, 
		75
	)
	basic_tea.setup(basic_tea_data)
	menu_grid.add_child(basic_tea)
	
	# Earl Grey (unlocks on day 3)
	var earl_grey = tea_scene.instantiate()
	var earl_grey_data = GameTypes.TeaItem.new(
		"Earl Grey",
		0.75,
		3.00,
		4,
		"Earl Grey" in shop_state.available_teas,
		85
	)
	earl_grey.setup(earl_grey_data)
	menu_grid.add_child(earl_grey)
	
	# Premium Blend (unlocks at reputation 3)
	var premium = tea_scene.instantiate()
	var premium_data = GameTypes.TeaItem.new(
		"Premium Blend",
		1.20,
		4.50,
		5,
		"Premium Blend" in shop_state.available_teas,
		95
	)
	premium.setup(premium_data)
	menu_grid.add_child(premium)

func update_weather_alert():
	var weather_text = ""
	match shop_state.current_weather:
		"sunny":
			weather_text = "☀️ Sunny day! Expect 30% more customers today."
		"rainy":
			weather_text = "🌧️ Rainy day! Tea sales likely to increase by 20%."
		"cold":
			weather_text = "❄️ Cold day! Hot tea sales up by 40%."
		"hot":
			weather_text = "🌡️ Hot day! Iced tea sales up by 30%."
	alert_label.text = weather_text

func update_reports_view():
	# Clear existing stats
	for child in reports_container.get_children():
		child.queue_free()
	
	if game_logic.historical_stats.size() > 0:
		var latest_stats = game_logic.historical_stats[-1]
		
		# Create stat cards
		create_stat_card("Revenue", "£%.2f" % latest_stats.revenue, "green")
		create_stat_card("Customers", str(latest_stats.customers), "blue")
		create_stat_card("Satisfaction", "%d%%" % (latest_stats.satisfaction * 100), "purple")
		
		# Add tea sales breakdown
		var sales_container = VBoxContainer.new()
		var sales_label = Label.new()
		sales_label.text = "Tea Sales:"
		sales_container.add_child(sales_label)
		
		for tea in latest_stats.tea_sold:
			var tea_label = Label.new()
			tea_label.text = "- %s: %d" % [tea, latest_stats.tea_sold[tea]]
			sales_container.add_child(tea_label)
		
		reports_container.add_child(sales_container)

func create_stat_card(title: String, value: String, color: String):
	var card = PanelContainer.new()
	var vbox = VBoxContainer.new()
	
	var title_label = Label.new()
	title_label.text = title
	match color:
		"green":
			title_label.add_theme_color_override("font_color", Color(0.2, 0.7, 0.2))
		"blue":
			title_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.7))
		"purple":
			title_label.add_theme_color_override("font_color", Color(0.7, 0.2, 0.7))
	
	var value_label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 24)
	
	vbox.add_child(title_label)
	vbox.add_child(value_label)
	card.add_child(vbox)
	reports_container.add_child(card)

func on_start_day():
	# Simulate the day
	var daily_results = game_logic.simulate_day(shop_state)
	
	# Update game state
	shop_state.day += 1
	
	# Update UI
	update_ui()
	
	# Show results notification
	var notification = "Day %d Complete!\nRevenue: £%.2f\nCustomers: %d\nSatisfaction: %d%%" % [
		shop_state.day - 1,
		daily_results.revenue,
		daily_results.customers,
		daily_results.satisfaction * 100
	]
	print(notification)  # Replace with proper notification system

func update_ui():
	day_label.text = "Day %d" % shop_state.day
	money_label.text = "£%.2f" % shop_state.money
	reputation_label.text = str(shop_state.reputation)
	update_tea_cards()
	update_reports_view()

func connect_signals():
	$MarginContainer/MainLayout/ActionButtons/StartDayButton.pressed.connect(on_start_day)
	$MarginContainer/MainLayout/ActionButtons/SaveButton.pressed.connect(on_save_game)

func on_save_game():
	# Implement save game functionality
	print("Save game requested")
