# tea_production_manager.gd
class_name TeaProductionManager
extends Node

signal tea_prepared(tea_name: String, quality: float)
signal preparation_failed(tea_name: String, reason: String)

# Tea preparation states
enum PreparationState {
	IDLE,
	HEATING_WATER,
	STEEPING,
	ADDING_MILK,
	COMPLETE
}

# Quality modifiers
const QUALITY_MODIFIERS = {
	"water_temp": {
		"perfect": 1.0,
		"too_hot": 0.8,
		"too_cool": 0.7
	},
	"steep_time": {
		"perfect": 1.0,
		"too_long": 0.8,
		"too_short": 0.7
	},
	"milk_amount": {
		"perfect": 1.0,
		"too_much": 0.8,
		"too_little": 0.9
	}
}

# Tea-specific requirements
const TEA_REQUIREMENTS = {
	"Builder's Tea": {
		"water_temp": 95.0,
		"steep_time": 3.0,
		"milk_standard": true
	},
	"Earl Grey": {
		"water_temp": 85.0,
		"steep_time": 4.0,
		"milk_optional": true
	},
	"Premium Blend": {
		"water_temp": 90.0,
		"steep_time": 5.0,
		"milk_standard": true
	}
}

var inventory_system: InventorySystem
var milk_system: MilkSystem
var staff_manager  # Will be added later when we create StaffManager

var current_state: PreparationState = PreparationState.IDLE
var active_preparations: Dictionary = {}

func setup(inventory: InventorySystem, milk: MilkSystem) -> void:
	inventory_system = inventory
	milk_system = milk

func start_preparation(tea_name: String, with_milk: bool = true) -> bool:
	if not can_prepare_tea(tea_name, with_milk):
		return false
	
	var prep_id = Time.get_unix_time_from_system()
	active_preparations[prep_id] = {
		"tea_name": tea_name,
		"with_milk": with_milk,
		"state": PreparationState.HEATING_WATER,
		"water_temp": 0.0,
		"steep_time": 0.0,
		"quality_modifiers": {
			"water_temp": 1.0,
			"steep_time": 1.0,
			"milk_amount": 1.0 if with_milk else 0.0
		}
	}
	
	# Start the preparation process
	_begin_water_heating(prep_id)
	return true

func can_prepare_tea(tea_name: String, with_milk: bool = true) -> bool:
	if not inventory_system.has_stock(tea_name):
		emit_signal("preparation_failed", tea_name, "No tea in stock")
		return false
	
	if with_milk and not milk_system.get_cups_remaining() > 0:
		emit_signal("preparation_failed", tea_name, "No milk available")
		return false
	
	return true

func _process(delta: float) -> void:
	var completed_preps = []
	
	for prep_id in active_preparations:
		var prep = active_preparations[prep_id]
		
		match prep.state:
			PreparationState.HEATING_WATER:
				_process_water_heating(prep_id, delta)
			PreparationState.STEEPING:
				_process_steeping(prep_id, delta)
			PreparationState.ADDING_MILK:
				_process_milk_adding(prep_id)
			PreparationState.COMPLETE:
				completed_preps.append(prep_id)
	
	# Clean up completed preparations
	for prep_id in completed_preps:
		var prep = active_preparations[prep_id]
		_finalize_preparation(prep_id)
		active_preparations.erase(prep_id)

func _begin_water_heating(prep_id: int) -> void:
	if not active_preparations.has(prep_id):
		return
	
	var prep = active_preparations[prep_id]
	prep.state = PreparationState.HEATING_WATER
	prep.water_temp = 0.0

func _process_water_heating(prep_id: int, delta: float) -> void:
	var prep = active_preparations[prep_id]
	var target_temp = TEA_REQUIREMENTS[prep.tea_name].water_temp
	
	# Simulate water heating
	prep.water_temp += delta * 30.0  # Heat up by 30 degrees per second
	
	if prep.water_temp >= target_temp:
		# Calculate quality modifier based on final temperature
		var temp_diff = abs(prep.water_temp - target_temp)
		if temp_diff <= 2.0:
			prep.quality_modifiers.water_temp = QUALITY_MODIFIERS.water_temp.perfect
		elif temp_diff <= 5.0:
			prep.quality_modifiers.water_temp = QUALITY_MODIFIERS.water_temp.too_hot
		else:
			prep.quality_modifiers.water_temp = QUALITY_MODIFIERS.water_temp.too_cool
		
		prep.state = PreparationState.STEEPING
		prep.steep_time = 0.0

func _process_steeping(prep_id: int, delta: float) -> void:
	var prep = active_preparations[prep_id]
	var target_time = TEA_REQUIREMENTS[prep.tea_name].steep_time
	
	prep.steep_time += delta
	
	if prep.steep_time >= target_time:
		# Calculate quality modifier based on steeping time
		var time_diff = abs(prep.steep_time - target_time)
		if time_diff <= 0.5:
			prep.quality_modifiers.steep_time = QUALITY_MODIFIERS.steep_time.perfect
		elif prep.steep_time > target_time:
			prep.quality_modifiers.steep_time = QUALITY_MODIFIERS.steep_time.too_long
		else:
			prep.quality_modifiers.steep_time = QUALITY_MODIFIERS.steep_time.too_short
		
		prep.state = PreparationState.ADDING_MILK if prep.with_milk else PreparationState.COMPLETE

func _process_milk_adding(prep_id: int) -> void:
	var prep = active_preparations[prep_id]
	
	if milk_system.use_milk():
		prep.quality_modifiers.milk_amount = QUALITY_MODIFIERS.milk_amount.perfect
	else:
		prep.quality_modifiers.milk_amount = 0.0
	
	prep.state = PreparationState.COMPLETE

func _finalize_preparation(prep_id: int) -> void:
	var prep = active_preparations[prep_id]
	
	# Calculate final quality
	var quality = _calculate_final_quality(prep)
	
	# Use tea from inventory
	if inventory_system.use_tea(prep.tea_name):
		emit_signal("tea_prepared", prep.tea_name, quality)
	else:
		emit_signal("preparation_failed", prep.tea_name, "Tea unavailable")

func _calculate_final_quality(prep: Dictionary) -> float:
	var base_quality = TeaManager.TEA_DATA[prep.tea_name].quality
	var modifier = (
		prep.quality_modifiers.water_temp *
		prep.quality_modifiers.steep_time *
		prep.quality_modifiers.milk_amount
	)
	
	return base_quality * modifier

func get_preparation_progress(prep_id: int) -> float:
	if not active_preparations.has(prep_id):
		return 1.0
		
	var prep = active_preparations[prep_id]
	match prep.state:
		PreparationState.HEATING_WATER:
			return prep.water_temp / TEA_REQUIREMENTS[prep.tea_name].water_temp
		PreparationState.STEEPING:
			return prep.steep_time / TEA_REQUIREMENTS[prep.tea_name].steep_time
		PreparationState.ADDING_MILK:
			return 0.9
		PreparationState.COMPLETE:
			return 1.0
		_:
			return 0.0

func get_active_preparations() -> Array:
	var preps = []
	for prep_id in active_preparations:
		preps.append({
			"id": prep_id,
			"tea": active_preparations[prep_id].tea_name,
			"state": active_preparations[prep_id].state,
			"progress": get_preparation_progress(prep_id)
		})
	return preps
