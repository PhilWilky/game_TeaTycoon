# game_logic.gd
extends Node

const MIN_CUSTOMERS_PER_DAY = 15
const MAX_CUSTOMERS_PER_DAY = 30

const WEATHER_TYPES = ["sunny", "rainy", "cold", "hot"]
const WEATHER_MODIFIERS = {
	"sunny": {"customers": 1.3, "satisfaction": 1.1},
	"rainy": {"customers": 0.8, "tea_sales": 1.2},
	"cold": {"hot_tea": 1.4},
	"hot": {"iced_tea": 1.3}
}

# Game state
var shop_state = {
	"money": 1000.0,
	"reputation": 3,
	"day": 1,
	"available_teas": ["Builder's Tea"],
	"current_weather": "sunny"
}

# Tracking
var active_customers = []
var daily_stats = {
	"revenue": 0.0,
	"costs": 0.0,
	"customers": 0,
	"satisfaction": 0.0,
	"tea_sold": {}
}

func _ready():
	# Connect to event signals
	Events.connect("day_started", _on_day_started)
	Events.connect("customer_served", _on_customer_served)
	Events.connect("tea_price_changed", _on_tea_price_changed)

func simulate_day() -> Dictionary:
	# Reset daily stats
	daily_stats = {
		"revenue": 0.0,
		"costs": 0.0,
		"customers": 0,
		"satisfaction": 0.0,
		"tea_sold": {}
	}
	
	# Generate customers based on modifiers
	var base_customers = randi_range(MIN_CUSTOMERS_PER_DAY, MAX_CUSTOMERS_PER_DAY)
	var weather_mod = WEATHER_MODIFIERS[shop_state.current_weather].get("customers", 1.0)
	var reputation_mod = 1.0 + (shop_state.reputation * 0.1)
	var total_customers = int(base_customers * weather_mod * reputation_mod)
	
	# Process each customer
	for i in range(total_customers):
		var customer_type = _get_random_customer_type()
		var customer = GameTypes.Customer.new(customer_type, 30.0)
		_process_customer(customer)
	
	# Calculate final satisfaction
	if daily_stats.customers > 0:
		daily_stats.satisfaction = daily_stats.satisfaction / daily_stats.customers
	
	# Update game state
	_update_game_state()
	
	return daily_stats

func _process_customer(customer: GameTypes.Customer) -> void:
	daily_stats.customers += 1
	
	if customer.tea_preference in shop_state.available_teas:
		var tea_price = _get_tea_price(customer.tea_preference)
		if tea_price <= customer.budget:
			_process_sale(customer.tea_preference, tea_price, customer)

func _process_sale(tea_name: String, price: float, customer):
	daily_stats.revenue += price
	daily_stats.costs += _get_tea_cost(tea_name)
	
	if not daily_stats.tea_sold.has(tea_name):
		daily_stats.tea_sold[tea_name] = 0
	daily_stats.tea_sold[tea_name] += 1
	
	# Calculate satisfaction
	var satisfaction = randf_range(0.7, 1.0)
	daily_stats.satisfaction += satisfaction

func _update_game_state():
	# Update money
	shop_state.money += daily_stats.revenue - daily_stats.costs
	
	# Update reputation based on satisfaction
	if daily_stats.satisfaction >= 0.8:
		shop_state.reputation = min(shop_state.reputation + 1, 5)
	elif daily_stats.satisfaction <= 0.4:
		shop_state.reputation = max(shop_state.reputation - 1, 1)
	
	# Check for unlocks
	_check_tea_unlocks()
	
	# Change weather
	shop_state.current_weather = WEATHER_TYPES[randi() % WEATHER_TYPES.size()]

func _check_tea_unlocks():
	if shop_state.day >= 3 and not "Earl Grey" in shop_state.available_teas:
		shop_state.available_teas.append("Earl Grey")
		Events.emit_signal("tea_unlocked", "Earl Grey")
	
	if shop_state.reputation >= 3 and not "Premium Blend" in shop_state.available_teas:
		shop_state.available_teas.append("Premium Blend")
		Events.emit_signal("tea_unlocked", "Premium Blend")

func _get_random_customer_type() -> String:
	var roll = randf()
	if roll < 0.5:
		return "regular"
	elif roll < 0.8:
		return "business"
	else:
		return "connoisseur"

func _get_tea_price(tea_name: String) -> float:
	match tea_name:
		"Builder's Tea": return 2.50
		"Earl Grey": return 3.00
		"Premium Blend": return 4.50
	return 0.0

func _get_tea_cost(tea_name: String) -> float:
	match tea_name:
		"Builder's Tea": return 0.50
		"Earl Grey": return 0.75
		"Premium Blend": return 1.20
	return 0.0

# Event handlers
func _on_day_started(day_number):
	shop_state.day = day_number

func _on_customer_served(customer_data, satisfaction):
	daily_stats.satisfaction += satisfaction

func _on_tea_price_changed(tea_type, new_price):
	# Implement price change logic
	pass
