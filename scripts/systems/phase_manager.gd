# phase_manager.gd
class_name PhaseManager
extends Node

signal phase_changed(phase: int)
signal day_started(day: int)
signal day_ended(day: int, stats: Dictionary)

enum Phase {
	MORNING_PREP,
	DAY_OPERATION,
	EVENING_REVIEW
}

const DAY_DURATION = 180.0  # 3 minutes in seconds

var current_phase: Phase = Phase.MORNING_PREP
var day_timer: float = 0.0
var is_day_running: bool = false

# System references
var inventory_system: InventorySystem
var milk_system: MilkSystem

func _ready() -> void:
	print("PhaseManager: Ready")

func setup(inventory: InventorySystem, _customer_demand, milk: MilkSystem) -> void:
	print("PhaseManager: Setting up with dependencies")
	inventory_system = inventory
	milk_system = milk

func _process(delta: float) -> void:
	if current_phase == Phase.DAY_OPERATION and is_day_running:
		day_timer += delta
		
		if day_timer >= DAY_DURATION:
			end_day()

func start_day() -> void:
	print("PhaseManager: Starting day")
	if is_day_running:
		return
		
	is_day_running = true
	day_timer = 0.0
	current_phase = Phase.DAY_OPERATION
	
	GameState.current_day += 1
	GameState.update_weather()
	
	emit_signal("phase_changed", Phase.DAY_OPERATION)
	emit_signal("day_started", GameState.current_day)
	print("PhaseManager: Day %d started" % GameState.current_day)

func end_day() -> void:
	print("PhaseManager: Ending day")
	is_day_running = false
	current_phase = Phase.EVENING_REVIEW
	day_timer = 0.0
	
	emit_signal("phase_changed", Phase.EVENING_REVIEW)
	emit_signal("day_ended", GameState.current_day, {})
	print("PhaseManager: Day %d ended" % GameState.current_day)

func start_morning_prep() -> void:
	print("PhaseManager: Starting morning prep")
	current_phase = Phase.MORNING_PREP
	emit_signal("phase_changed", Phase.MORNING_PREP)

func get_current_phase() -> int:
	return current_phase

func is_running() -> bool:
	return is_day_running

func get_time_elapsed() -> float:
	return day_timer

func get_time_remaining() -> float:
	return max(0.0, DAY_DURATION - day_timer)

func get_day_progress() -> float:
	return clamp(day_timer / DAY_DURATION, 0.0, 1.0)
