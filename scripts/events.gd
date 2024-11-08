# events.gd
extends Node

# Customer signals
signal customer_entered(customer_data: Dictionary)
signal customer_left(customer_data: Dictionary)
signal customer_served(customer_data: Dictionary, satisfaction: float)
signal customer_patience_changed(customer_data: Dictionary)

# Business signals
signal money_changed(new_amount: float)
signal reputation_changed(new_amount: int)
signal day_started(day_number: int)
signal day_ended(day_number: int, daily_stats: Dictionary)

# Tea signals
signal tea_unlocked(tea_type: String)
signal tea_price_changed(tea_type: String, new_price: float)
signal tea_recipe_changed(tea_type: String, recipe_data: Dictionary)

# Staff signals
signal staff_hired(staff_data: Dictionary)
signal staff_fired(staff_id: int)
signal staff_task_completed(staff_id: int, task_data: Dictionary)
signal staff_role_changed(staff_id: int, new_role: String)

# UI signals
signal preparation_phase_started
signal preparation_phase_completed
signal show_notification(title: String, message: String, type: String)
signal stats_updated(stats_data: Dictionary)

# Weather signals
signal weather_changed(new_weather: String, modifiers: Dictionary)

func _ready() -> void:
	# Connect to autoload singletons if needed
	pass

func emit_game_event(event_name: String, data: Dictionary = {}) -> void:
	match event_name:
		"customer_served":
			emit_signal("customer_served", data.customer, data.satisfaction)
		"tea_unlocked":
			emit_signal("tea_unlocked", data.tea_type)
		"show_notification":
			emit_signal("show_notification", data.title, data.message, data.type)
		_:
			push_warning("Unknown event: " + event_name)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Clean up any remaining connections
		pass
