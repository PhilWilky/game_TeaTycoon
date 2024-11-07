# game_types.gd
extends Node

# Tea component configurations
const TEA_COMPONENTS = {
	"tea_leaves": {
		"cheap": {"cost": 0.2, "quality": 1},
		"standard": {"cost": 0.4, "quality": 2},
		"premium": {"cost": 0.8, "quality": 3}
	},
	"steeping_time": {
		"quick": {"time": 1, "quality": 1},
		"standard": {"time": 2, "quality": 2},
		"long": {"time": 3, "quality": 3}
	},
	"additions": {
		"none": {"cost": 0.0, "quality": 0},
		"milk": {"cost": 0.2, "quality": 1},
		"honey": {"cost": 0.3, "quality": 1},
		"lemon": {"cost": 0.2, "quality": 1}
	}
}

class TeaItem:
	var name: String
	var cost: float
	var price: float
	var quality: int
	var unlocked: bool
	var satisfaction: int
	var recipe: TeaRecipe
	
	func _init(n: String, c: float, p: float, q: int, u: bool, s: int):
		name = n
		cost = c
		price = p
		quality = q
		unlocked = u
		satisfaction = s
		recipe = TeaRecipe.new()

class TeaRecipe:
	var leaves_type: String = "standard"
	var steep_time: String = "standard"
	var additions: Array = []
	var base_cost: float = 0.0
	var quality_rating: int = 0
	
	func calculate_cost() -> float:
		var total = TEA_COMPONENTS.tea_leaves[leaves_type].cost
		for addition in additions:
			total += TEA_COMPONENTS.additions[addition].cost
		return total
	
	func calculate_quality() -> int:
		var total = TEA_COMPONENTS.tea_leaves[leaves_type].quality
		total += TEA_COMPONENTS.steeping_time[steep_time].quality
		for addition in additions:
			total += TEA_COMPONENTS.additions[addition].quality
		return total

class StaffMember:
	var id: int
	var name: String
	var type: String
	var shift: String
	var efficiency: int
	var salary: float
	var current_role: String = "general"
	var task_efficiencies: Dictionary = {
		"prepare_tea": 1.0,
		"serve_customer": 1.0,
		"clean": 1.0
	}
	var happiness: float = 1.0
	
	func _init(staff_id: int, n: String, t: String, s: String, e: int, sal: float):
		id = staff_id
		name = n
		type = t
		shift = s
		efficiency = e
		salary = sal

class Customer:
	var type: String
	var budget: float
	var patience: float
	var tea_preference: String
	var max_wait_time: float
	var satisfaction: float = 0.0
	var order_time: float = 0.0
	var served: bool = false
	
	func _init(t: String, wait_time: float):
		type = t
		max_wait_time = wait_time
		match type:
			"regular":
				budget = randf_range(4.0, 6.0)
				patience = 1.0
				tea_preference = "Builder's Tea"
			"business":
				budget = randf_range(7.0, 9.0)
				patience = 0.8
				tea_preference = "Earl Grey"
			"connoisseur":
				budget = randf_range(12.0, 18.0)
				patience = 1.2
				tea_preference = "Premium Blend"

class DailyStats:
	var day: int
	var revenue: float = 0.0
	var costs: float = 0.0
	var customers_served: int = 0
	var customers_lost: int = 0
	var average_satisfaction: float = 0.0
	var tea_sold: Dictionary = {}
	var staff_costs: float = 0.0
	var weather: String = "sunny"
	
	func calculate_profit() -> float:
		return revenue - (costs + staff_costs)
	
	func calculate_customer_satisfaction() -> float:
		return 0.0 if customers_served == 0 else average_satisfaction / customers_served
