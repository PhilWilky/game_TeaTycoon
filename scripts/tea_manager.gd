# tea_manager.gd
extends Node

const TEA_DATA = {
	"Builder's Tea": {
		"cost": 0.50,
		"price": 2.50,
		"quality": 3,
		"unlock_day": 1,
		"unlock_reputation": 1,
		"preparation_time": 1.0,
		"base_satisfaction": 0.75
	},
	"Earl Grey": {
		"cost": 0.75,
		"price": 3.00,
		"quality": 4,
		"unlock_day": 3,
		"unlock_reputation": 1,
		"preparation_time": 1.2,
		"base_satisfaction": 0.85
	},
	"Premium Blend": {
		"cost": 1.20,
		"price": 4.50,
		"quality": 5,
		"unlock_day": 1,
		"unlock_reputation": 3,
		"preparation_time": 1.5,
		"base_satisfaction": 0.95
	}
}

var unlocked_teas = ["Builder's Tea"]
var prices = {}

func _ready() -> void:
	# Initialize default prices
	for tea_name in TEA_DATA:
		prices[tea_name] = TEA_DATA[tea_name].price

func is_tea_unlocked(tea_name: String) -> bool:
	return tea_name in unlocked_teas

func check_unlocks(day: int, reputation: int) -> void:
	for tea_name in TEA_DATA:
		if tea_name not in unlocked_teas:
			if day >= TEA_DATA[tea_name].unlock_day and reputation >= TEA_DATA[tea_name].unlock_reputation:
				unlocked_teas.append(tea_name)
				Events.emit_signal("tea_unlocked", tea_name)

func get_preparation_time(tea_name: String) -> float:
	return TEA_DATA[tea_name].preparation_time if tea_name in TEA_DATA else 1.0

func get_base_satisfaction(tea_name: String) -> float:
	return TEA_DATA[tea_name].base_satisfaction if tea_name in TEA_DATA else 0.5

func set_price(tea_name: String, new_price: float) -> void:
	if tea_name in TEA_DATA:
		prices[tea_name] = new_price
		Events.emit_signal("tea_price_changed", tea_name, new_price)
