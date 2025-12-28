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

# Customer cap system
var base_customers_per_day: int = 60 # Hook for upgrades/marketing
var customer_variance: int = 10 # ±10 customers randomness
var max_customers_per_day: int = 60 # Calculated each day
var customers_spawned_today: int = 0 # Daily counter

# Phase 1.5: Wave system
enum WaveState {RUSH, QUIET}
var current_wave_state: WaveState = WaveState.RUSH
var wave_timer: float = 0.0
var current_wave_duration: float = 0.0
# Wave spawn rates (calculated dynamically in _on_day_started)
var rush_spawn_rate: float = 2.0
var quiet_spawn_rate: float = 4.5

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
	
	# Update wave timer
	wave_timer += delta
	if wave_timer >= current_wave_duration:
		_switch_wave()
	
	# Spawn customers based on current wave
	customer_spawn_timer += delta
	if customer_spawn_timer >= _get_spawn_interval():
		customer_spawn_timer = 0.0
		_try_spawn_customer()

func _get_spawn_interval() -> float:
	# Use wave-based spawn rate
	var base_interval = rush_spawn_rate if current_wave_state == WaveState.RUSH else quiet_spawn_rate
	
	# Add slight randomness (±20%)
	var randomness = base_interval * 0.2
	base_interval = randf_range(base_interval - randomness, base_interval + randomness)
	
	# Weather still affects spawn rate
	var weather_mod = 1.0
	match GameState.current_weather:
		"sunny": weather_mod = 0.8
		"rainy": weather_mod = 1.3
		"cold": weather_mod = 1.0
		"hot": weather_mod = 1.4
	
	return base_interval * weather_mod

func _switch_wave() -> void:
	# Toggle between rush and quiet
	if current_wave_state == WaveState.RUSH:
		current_wave_state = WaveState.QUIET
		current_wave_duration = randf_range(20.0, 40.0) # Quiet period: 20-40 seconds
		print("CustomerManager: Wave switched to QUIET (%.1fs)" % current_wave_duration)
	else:
		current_wave_state = WaveState.RUSH
		current_wave_duration = randf_range(30.0, 50.0) # Rush period: 30-50 seconds
		print("CustomerManager: Wave switched to RUSH (%.1fs)" % current_wave_duration)
	
	wave_timer = 0.0

func _try_spawn_customer() -> void:
	# Check if we've hit the daily customer cap
	if customers_spawned_today >= max_customers_per_day:
		return # Stop spawning for the day
	
	print("CustomerManager: Attempting to spawn customer")
	if not customer_queue_instance or customer_queue_instance.is_full():
		emit_signal("customer_missed", CustomerDemand.MissReason.TOO_BUSY)
		customers_missed_today += 1
		return
	
	var customer = GameTypes.Customer.new(_get_random_customer_type(), 30.0)
	print("CustomerManager: Created customer of type: ", customer.type)
	
	if TeaManager.is_tea_unlocked(customer.tea_preference) and inventory_system.has_stock(customer.tea_preference):
		if customer_queue_instance.add_customer():
			customers_spawned_today += 1
			print("CustomerManager: Customer added to queue (spawned: %d/%d)" % [customers_spawned_today, max_customers_per_day])
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
		var customer_data = {
			"type": customer.type,
			"tea": customer.tea_preference,
			"satisfaction": satisfaction,
			"revenue": revenue
		}
		
		# Emit through Events so StatsManager receives it
		Events.emit_signal("customer_served", customer_data, satisfaction)
		emit_signal("customer_served", customer_data, satisfaction)

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
	
# Calculate daily customer cap with variance
	max_customers_per_day = base_customers_per_day + randi_range(-customer_variance, customer_variance)
	print("CustomerManager: Today's customer cap: %d" % max_customers_per_day)
	
	# Calculate wave spawn rates based on day length and customer cap
	# Note: Synced with GameLoopManager.phase_duration (180s)
	var day_length = 180.0

	var avg_spawn_rate = day_length / max_customers_per_day
	
	rush_spawn_rate = avg_spawn_rate * 0.67 # 33% faster than average
	quiet_spawn_rate = avg_spawn_rate * 1.5 # 50% slower than average
	print("CustomerManager: Wave rates - Rush: %.2fs, Quiet: %.2fs" % [rush_spawn_rate, quiet_spawn_rate])
	
	# Reset daily tracking
	customers_served_today = 0
	customers_missed_today = 0
	total_satisfaction_today = 0.0
	tea_sold_today.clear()
	customers_spawned_today = 0

	# Initialize first wave as rush
	current_wave_state = WaveState.RUSH
	current_wave_duration = randf_range(30.0, 50.0)
	wave_timer = 0.0
	print("CustomerManager: Starting with RUSH wave (%.1fs)" % current_wave_duration)

func _on_day_ended(_day: int, _stats: Dictionary) -> void:
	print("CustomerManager: Day ended - Served: %d, Missed: %d" % [customers_served_today, customers_missed_today])
	is_active = false
	if customer_queue_instance:
		customer_queue_instance.clear_queue()
