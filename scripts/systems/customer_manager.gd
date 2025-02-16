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
	var base_interval = randf_range(1.0, 4.0)
	
	# Weather affects how likely people are to want tea
	var weather_mod = 1.0
	match GameState.current_weather:
		"sunny": weather_mod = 0.7  # More customers on sunny days
		"rainy": weather_mod = 1.2  # Fewer customers on rainy days
		"cold": weather_mod = 0.8   # More customers wanting hot tea
		"hot": weather_mod = 1.3    # Fewer customers on hot days
	
	return base_interval * weather_mod

func _try_spawn_customer() -> void:
	print("CustomerManager: Attempting to spawn customer")
	if not customer_queue_instance or customer_queue_instance.is_full():
		emit_signal("customer_missed", CustomerDemand.MissReason.TOO_BUSY)
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

func _process_customer_order(customer: GameTypes.Customer) -> void:
	if not is_active:
		return
	
	print("CustomerManager: Processing order for ", customer.tea_preference)
	
	# Check milk availability
	if not milk_system.use_milk():
		emit_signal("customer_missed", CustomerDemand.MissReason.NO_MILK)
		customer_queue_instance.remove_customer()
		return
	
	# Check tea availability
	if not inventory_system.has_stock(customer.tea_preference):
		emit_signal("customer_missed", CustomerDemand.MissReason.OUT_OF_STOCK)
		customer_queue_instance.remove_customer()
		return
	
	# Process order
	if inventory_system.use_tea(customer.tea_preference):
		var satisfaction = _calculate_satisfaction(customer)
		var tea_data = TeaManager.TEA_DATA[customer.tea_preference]
		var revenue = tea_data.price
		
		GameState.add_money(revenue)
		
		emit_signal("customer_served", {
			"type": customer.type,
			"tea": customer.tea_preference,
			"satisfaction": satisfaction,
			"revenue": revenue
		}, satisfaction)
		
		print("CustomerManager: Customer served - Revenue: £%.2f, Satisfaction: %.1f%%" % [revenue, satisfaction * 100])
	else:
		emit_signal("customer_missed", CustomerDemand.MissReason.OUT_OF_STOCK)
	
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

func _on_day_ended(_day: int, _stats: Dictionary) -> void:
	print("CustomerManager: Day ended")
	is_active = false
	if customer_queue_instance:
		customer_queue_instance.clear_queue()
