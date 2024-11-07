# game_logic.gd
extends Node

# Constants
const MIN_CUSTOMERS_PER_DAY = 15
const MAX_CUSTOMERS_PER_DAY = 30
const WEATHER_MODIFIERS = {
	"sunny": {"customers": 1.3, "satisfaction": 1.1},
	"rainy": {"customers": 0.8, "tea_sales": 1.2},
	"cold": {"hot_tea": 1.4},
	"hot": {"iced_tea": 1.3}
}

# Business stats tracking
var daily_stats = {
	"revenue": 0.0,
	"costs": 0.0,
	"customers": 0,
	"satisfaction": 0.0,
	"tea_sold": {}
}

var historical_stats = []

class Customer:
	var type: String
	var budget: float
	var patience: float
	var tea_preference: String
	var satisfaction: float = 0.0
	
	func _init(t: String):
		type = t
		match type:
			"regular":
				budget = randf_range(4.0, 6.0)
				patience = 0.5
				tea_preference = "Builder's Tea"
			"business":
				budget = randf_range(7.0, 9.0)
				patience = 0.3
				tea_preference = "Earl Grey"
			"connoisseur":
				budget = randf_range(12.0, 18.0)
				patience = 0.8
				tea_preference = "Premium Blend"

class TeaShopState:
	var money: float
	var reputation: int
	var day: int
	var available_teas: Array
	var staff: Array
	var current_weather: String
	
	func _init(initial_money: float, initial_reputation: int):
		money = initial_money
		reputation = initial_reputation
		day = 1
		available_teas = ["Builder's Tea"]
		current_weather = "sunny"

# Main simulation functions
func simulate_day(state: TeaShopState) -> Dictionary:
	# Reset daily stats
	daily_stats = {
		"revenue": 0.0,
		"costs": 0.0,
		"customers": 0,
		"satisfaction": 0.0,
		"tea_sold": {}
	}
	
	# Calculate base number of customers
	var base_customers = randi_range(MIN_CUSTOMERS_PER_DAY, MAX_CUSTOMERS_PER_DAY)
	var weather_modifier = WEATHER_MODIFIERS[state.current_weather].get("customers", 1.0)
	var reputation_modifier = 1.0 + (state.reputation * 0.1)
	var total_customers = int(base_customers * weather_modifier * reputation_modifier)
	
	# Process each customer
	for i in range(total_customers):
		var customer_type = _get_random_customer_type()
		var customer = Customer.new(customer_type)
		_process_customer(customer, state)
	
	# Calculate final satisfaction
	if daily_stats.customers > 0:
		daily_stats.satisfaction = daily_stats.satisfaction / daily_stats.customers
	
	# Update reputation based on satisfaction
	if daily_stats.satisfaction >= 0.8:
		state.reputation = min(state.reputation + 1, 5)
	elif daily_stats.satisfaction <= 0.4:
		state.reputation = max(state.reputation - 1, 1)
	
	# Update money
	state.money += daily_stats.revenue - daily_stats.costs
	
	# Save historical stats
	historical_stats.append(daily_stats.duplicate())
	
	# Check for tea unlocks
	_check_tea_unlocks(state)
	
	return daily_stats

func _process_customer(customer: Customer, state: TeaShopState) -> void:
	daily_stats.customers += 1
	
	# Check if preferred tea is available
	if customer.tea_preference in state.available_teas:
		var tea_price = _get_tea_price(customer.tea_preference)
		
		# Customer will buy if within budget
		if tea_price <= customer.budget:
			_process_sale(customer.tea_preference, tea_price, customer)
			
			# Calculate satisfaction based on various factors
			var base_satisfaction = randf_range(0.7, 1.0)
			var price_satisfaction = 1.0 - (tea_price / customer.budget)
			var weather_satisfaction = WEATHER_MODIFIERS[state.current_weather].get("satisfaction", 1.0)
			
			customer.satisfaction = (base_satisfaction + price_satisfaction) * weather_satisfaction
			daily_stats.satisfaction += customer.satisfaction
		else:
			customer.satisfaction = 0.3
			daily_stats.satisfaction += customer.satisfaction
	else:
		# Customer couldn't get preferred tea
		customer.satisfaction = 0.2
		daily_stats.satisfaction += customer.satisfaction
		
		# Try to sell them Builder's Tea instead
		if "Builder's Tea" in state.available_teas:
			var basic_tea_price = _get_tea_price("Builder's Tea")
			if basic_tea_price <= customer.budget:
				_process_sale("Builder's Tea", basic_tea_price, customer)

func _process_sale(tea_name: String, price: float, customer: Customer) -> void:
	daily_stats.revenue += price
	daily_stats.costs += _get_tea_cost(tea_name)
	
	if not daily_stats.tea_sold.has(tea_name):
		daily_stats.tea_sold[tea_name] = 0
	daily_stats.tea_sold[tea_name] += 1

func _check_tea_unlocks(state: TeaShopState) -> void:
	if state.day >= 3 and not "Earl Grey" in state.available_teas:
		state.available_teas.append("Earl Grey")
	
	if state.reputation >= 3 and not "Premium Blend" in state.available_teas:
		state.available_teas.append("Premium Blend")

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
		"Builder's Tea":
			return 2.50
		"Earl Grey":
			return 3.00
		"Premium Blend":
			return 4.50
	return 0.0

func _get_tea_cost(tea_name: String) -> float:
	match tea_name:
		"Builder's Tea":
			return 0.50
		"Earl Grey":
			return 0.75
		"Premium Blend":
			return 1.20
	return 0.0
