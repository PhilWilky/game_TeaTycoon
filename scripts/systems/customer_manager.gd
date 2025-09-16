# customer_manager.gd
class_name CustomerManager
extends Node

signal customer_served(customer_data: Dictionary, satisfaction: float)
signal customer_missed(reason: int)

const MIN_SPAWN_INTERVAL = 3.0
const MAX_SPAWN_INTERVAL = 8.0

var customer_spawn_timer: float = 0.0
var phase_manager: PhaseManager
var inventory_system: InventorySystem
var milk_system: MilkSystem
var customer_queue_instance: Node
var is_active: bool = false
var customers_served_today: int = 0
var customers_missed_today: int = 0
var total_satisfaction_today: float = 0.0
var tea_sold_today: Dictionary = {}

func _ready() -> void:
	print("CustomerManager: Ready")

func setup(p_manager: PhaseManager, inventory: InventorySystem, milk: MilkSystem, queue: Node) -> void:
	print("CustomerManager: Setting up with dependencies")
	phase_manager = p_manager
	inventory_system = inventory
	milk_system = milk
	customer_queue_instance = queue
	
	# Connect to phase manager signals
	if phase_manager:
		phase_manager.day_started.connect(_on_day_started)
		phase_manager.day_ended.connect(_on_day_ended)
		print("CustomerManager: Connected to phase manager signals")

func _process(delta: float) -> void:
	if not is_active:
		return
		
	customer_spawn_timer += delta
	if customer_spawn_timer >= _get_spawn_interval():
		customer_spawn_timer = 0.0
		_try_spawn_customer()

func _get_spawn_interval() -> float:
	# Base interval randomly between 1 and 4 seconds
	# Reduced customer frequency for better game balance
	var base_interval = randf_range(3.0, 7.0)  # Changed from 1.0-4.0
	
	# Weather affects how likely people are to want tea
	var weather_mod = 1.0
	match GameState.current_weather:
		"sunny": weather_mod = 0.8  # Changed from 0.7
		"rainy": weather_mod = 1.3  # Changed from 1.2
		"cold": weather_mod = 1.0   # Changed from 0.8
		"hot": weather_mod = 1.4    # Changed from 1.3
	
	return base_interval * weather_mod

func _try_spawn_customer() -> void:
	print("CustomerManager: Attempting to spawn customer")
	if not customer_queue_instance or customer_queue_instance.is_full():
		emit_signal("customer_missed", CustomerDemand.MissReason.TOO_BUSY)
		customers_missed_today += 1
		return
	
	var customer = GameTypes.Customer.new(_get_random_customer_type(), 30.0)
	print("CustomerManager: Created customer of type: ", customer.type)
	
	if TeaManager.is_tea_unlocked(customer.tea_preference) and inventory_system.has_stock(customer.tea_preference):
		if customer_queue_instance.add_customer():
			print("CustomerManager: Customer added to queue")
			var timer = get_tree().create_timer(randf_range(3.0, 5.0))
			timer.timeout.connect(_process_customer_order.bind(customer))
	else:
		emit_signal("customer_missed", 
			CustomerDemand.MissReason.NO_TEA_TYPE if not TeaManager.is_tea_unlocked(customer.tea_preference)
			else CustomerDemand.MissReason.OUT_OF_STOCK
		)
		customers_missed_today += 1

func _process_customer_order(customer: GameTypes.Customer) -> void:
	if not is_active:
		return
	
	print("CustomerManager: Processing order for ", customer.tea_preference)
	
	# Check milk availability
	print("CustomerManager: Checking milk availability... Current stock: %.1f units" % milk_system.get_current_stock())
	if not milk_system.use_milk():
		print("CustomerManager: No milk available!")
		emit_signal("customer_missed", CustomerDemand.MissReason.NO_MILK)
		customers_missed_today += 1
		customer_queue_instance.remove_customer()
		return
	else:
		print("CustomerManager: Milk used successfully. Remaining: %.1f units" % milk_system.get_current_stock())
	
	# Check tea availability
	if not inventory_system.has_stock(customer.tea_preference):
		emit_signal("customer_missed", CustomerDemand.MissReason.OUT_OF_STOCK)
		customers_missed_today += 1
		customer_queue_instance.remove_customer()
		return
	
	# Process order
	if inventory_system.use_tea(customer.tea_preference):
		var satisfaction = _calculate_satisfaction(customer)
		var tea_data = TeaManager.TEA_DATA[customer.tea_preference]
		var revenue = tea_data.price
		
		GameState.add_money(revenue)
		
		# after successful serving
		emit_signal("customer_served", {
			"type": customer.type,
			"tea": customer.tea_preference,
			"satisfaction": satisfaction,
			"revenue": revenue
		}, satisfaction)

		# Add tracking
		customers_served_today += 1
		total_satisfaction_today += satisfaction
		if not tea_sold_today.has(customer.tea_preference):
			tea_sold_today[customer.tea_preference] = 0
		tea_sold_today[customer.tea_preference] += 1

		
		print("CustomerManager: Customer served - Revenue: £%.2f, Satisfaction: %.1f%%" % [revenue, satisfaction * 100])
	else:
		emit_signal("customer_missed", CustomerDemand.MissReason.OUT_OF_STOCK)
		customers_missed_today += 1
	
	customer_queue_instance.remove_customer()

func _calculate_satisfaction(customer: GameTypes.Customer) -> float:
	var tea_data = TeaManager.TEA_DATA[customer.tea_preference]
	var base_satisfaction = tea_data.base_satisfaction
	
	var queue_penalty = customer_queue_instance.get_queue_size() * 0.05
	
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
		"regular": type_modifier = 1.0
		"business": type_modifier = 0.9
		"connoisseur": type_modifier = 0.8
	
	var final_satisfaction = (base_satisfaction - queue_penalty + weather_bonus) * type_modifier
	return clamp(final_satisfaction, 0.0, 1.0)

func _get_random_customer_type() -> String:
	var roll = randf()
	if roll < 0.5:
		return "regular"
	elif roll < 0.8:
		return "business"
	else:
		return "connoisseur"

func _on_day_started(_day: int) -> void:
	print("CustomerManager: Day started")
	is_active = true
	customer_spawn_timer = 0.0
	
	# Reset daily tracking
	customers_served_today = 0
	customers_missed_today = 0
	total_satisfaction_today = 0.0
	tea_sold_today.clear()

func _on_day_ended(_day: int, _stats: Dictionary) -> void:
	print("CustomerManager: Day ended - Served: %d, Missed: %d" % [customers_served_today, customers_missed_today])
	is_active = false
	if customer_queue_instance:
		customer_queue_instance.clear_queue()
