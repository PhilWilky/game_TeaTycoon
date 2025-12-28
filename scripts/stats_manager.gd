# stats_manager.gd
class_name StatsManager
extends Node

signal daily_stats_updated(stats: Dictionary)

var daily_stats = {
	"revenue": 0.0,
	"costs": 0.0,
	"profit": 0.0,
	"customers_served": 0,
	"customers_missed": 0,
	"satisfaction_total": 0.0,
	"tea_sold": {},
	"milk_used": 0,
	"staff_costs": 0.0,
	# NEW - Added cost tracking fields
	"restock_costs": 0.0,
	"milk_costs": 0.0,
	"milk_spoiled_units": 0.0,
	"milk_spoiled_value": 0.0
}

var historical_stats = []
const MAX_HISTORY_DAYS = 7

func _ready() -> void:
	Events.customer_served.connect(_on_customer_served)
	Events.customer_missed.connect(_on_customer_missed)

func reset_daily_stats() -> void:
	daily_stats = {
		"revenue": 0.0,
		"costs": 0.0,
		"profit": 0.0,
		"customers_served": 0,
		"customers_missed": 0,
		"satisfaction_total": 0.0,
		"tea_sold": {},
		"milk_used": 0,
		"staff_costs": 0.0,
		# NEW - Reset new fields
		"restock_costs": 0.0,
		"milk_costs": 0.0,
		"milk_spoiled_units": 0.0,
		"milk_spoiled_value": 0.0
	}

func record_sale(tea_name: String, revenue: float, cost: float, satisfaction: float) -> void:
	daily_stats.revenue += revenue
	daily_stats.costs += cost
	daily_stats.profit = daily_stats.revenue - daily_stats.costs - daily_stats.staff_costs
	
	if not daily_stats.tea_sold.has(tea_name):
		daily_stats.tea_sold[tea_name] = 0
	daily_stats.tea_sold[tea_name] += 1
	
	daily_stats.customers_served += 1
	daily_stats.satisfaction_total += satisfaction * 100
	
	emit_signal("daily_stats_updated", get_current_stats())

func record_milk_usage(amount: float) -> void:
	daily_stats.milk_used += amount

func record_staff_costs(amount: float) -> void:
	daily_stats.staff_costs += amount
	daily_stats.profit = daily_stats.revenue - daily_stats.costs - daily_stats.staff_costs

# NEW - Record tea restocking costs
func record_restock_cost(cost: float) -> void:
	daily_stats.restock_costs += cost
	daily_stats.costs += cost
	# Recalculate profit including all costs
	daily_stats.profit = daily_stats.revenue - daily_stats.costs - daily_stats.staff_costs - daily_stats.restock_costs - daily_stats.milk_costs
	emit_signal("daily_stats_updated", get_current_stats())
	print("StatsManager: Recorded restock cost: £%.2f" % cost)

# NEW - Record milk purchase costs
func record_milk_purchase(cost: float) -> void:
	daily_stats.milk_costs += cost
	daily_stats.costs += cost
	# Recalculate profit including all costs
	daily_stats.profit = daily_stats.revenue - daily_stats.costs - daily_stats.staff_costs - daily_stats.restock_costs - daily_stats.milk_costs
	emit_signal("daily_stats_updated", get_current_stats())
	print("StatsManager: Recorded milk purchase: £%.2f" % cost)

# NEW - Record milk spoilage
func record_milk_spoilage(units: float, value: float) -> void:
	daily_stats.milk_spoiled_units += units
	daily_stats.milk_spoiled_value += value
	# Spoilage is a loss, subtract from profit
	daily_stats.profit -= value
	emit_signal("daily_stats_updated", get_current_stats())
	print("StatsManager: Recorded milk spoilage: %.1f units (£%.2f)" % [units, value])

func get_current_stats() -> Dictionary:
	var stats = daily_stats.duplicate(true)
	
	# Calculate averages
	if daily_stats.customers_served > 0:
		stats.average_satisfaction = daily_stats.satisfaction_total / daily_stats.customers_served
	else:
		stats.average_satisfaction = 0.0
		
	# Calculate service rate
	var total_customers = daily_stats.customers_served + daily_stats.customers_missed
	if total_customers > 0:
		stats.service_rate = float(daily_stats.customers_served) / total_customers * 100
	else:
		stats.service_rate = 0.0
	
	# NEW - Include detailed cost breakdown
	stats.total_costs = daily_stats.restock_costs + daily_stats.milk_costs + daily_stats.staff_costs
	stats.net_profit = daily_stats.revenue - stats.total_costs - daily_stats.milk_spoiled_value
		
	return stats

func end_day() -> Dictionary:
	var final_stats = get_current_stats()
	
	# Add to historical stats
	historical_stats.append(final_stats)
	if historical_stats.size() > MAX_HISTORY_DAYS:
		historical_stats.pop_front()
	
	return final_stats

func get_historical_stats() -> Array:
	return historical_stats

func get_trend_analysis() -> Dictionary:
	if historical_stats.size() < 2:
		return {}
	
	var previous = historical_stats[-2]
	var current = historical_stats[-1]
	
	return {
		"revenue_change": _calculate_percentage_change(previous.revenue, current.revenue),
		"profit_change": _calculate_percentage_change(previous.profit, current.profit),
		"satisfaction_change": _calculate_percentage_change(previous.average_satisfaction, current.average_satisfaction),
		"service_rate_change": _calculate_percentage_change(previous.service_rate, current.service_rate)
	}

func get_best_selling_tea() -> Dictionary:
	var best_tea = ""
	var best_amount = 0
	
	for tea_name in daily_stats.tea_sold:
		if daily_stats.tea_sold[tea_name] > best_amount:
			best_tea = tea_name
			best_amount = daily_stats.tea_sold[tea_name]
	
	return {
		"name": best_tea,
		"amount": best_amount
	} if best_tea != "" else {}

func _calculate_percentage_change(old_value: float, new_value: float) -> float:
	if old_value == 0:
		return 100.0 if new_value > 0 else 0.0
	return ((new_value - old_value) / old_value) * 100.0

# Signal handlers
func _on_customer_served(customer_data: Dictionary, satisfaction: float) -> void:
	var tea_name = customer_data.get("tea", "Unknown")
	var revenue = customer_data.get("revenue", 0.0)
	
	var cost = 0.0
	if TeaManager.TEA_DATA.has(tea_name):
		cost = TeaManager.TEA_DATA[tea_name].cost
	
	record_sale(tea_name, revenue, cost, satisfaction)
	print("StatsManager: Recorded sale - %s for £%.2f" % [tea_name, revenue])

func _on_customer_missed(_reason: int) -> void:
	daily_stats.customers_missed += 1
	emit_signal("daily_stats_updated", get_current_stats())