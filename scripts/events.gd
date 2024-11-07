# events.gd
extends Node

# Customer signals
signal customer_entered(customer_data)
signal customer_left(customer_data)
signal customer_served(customer_data, satisfaction)
signal customer_patience_changed(customer_data)

# Business signals
signal money_changed(new_amount)
signal reputation_changed(new_amount)
signal day_started(day_number)
signal day_ended(day_number, daily_stats)

# Tea signals
signal tea_unlocked(tea_type)
signal tea_price_changed(tea_type, new_price)
signal tea_recipe_changed(tea_type, recipe_data)

# Staff signals
signal staff_hired(staff_data)
signal staff_fired(staff_id)
signal staff_task_completed(staff_id, task_data)
signal staff_role_changed(staff_id, new_role)

# UI signals
signal preparation_phase_started
signal preparation_phase_completed
signal show_notification(title, message, type)
signal stats_updated(stats_data)
