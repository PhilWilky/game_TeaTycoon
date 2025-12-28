# save_system.gd
# This should be added as an AutoLoad (Singleton)
extends Node

signal save_completed(success: bool)
signal load_completed(success: bool)

const SAVE_FILE_PATH = "user://tea_shop_save.dat"
const SAVE_VERSION = "1.0"

# Save data structure
var save_data_template = {
	"version": SAVE_VERSION,
	"timestamp": "",
	"game_state": {},
	"inventory": {},
	"tea_manager": {},
	"milk_system": {},
	"phase_manager": {},
	"player_settings": {
		"auto_save_enabled": false,
		"auto_save_interval": 300.0  # 5 minutes in seconds
	}
}

var auto_save_timer: Timer
var auto_save_enabled: bool = false

func _ready() -> void:
	print("SaveSystem: Initializing...")
	setup_auto_save()

func setup_auto_save() -> void:
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = 300.0  # 5 minutes
	auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)
	auto_save_timer.autostart = false
	add_child(auto_save_timer)

func save_game() -> bool:
	print("SaveSystem: Starting save operation...")
	
	var save_data = save_data_template.duplicate(true)
	save_data.timestamp = Time.get_datetime_string_from_system()
	
	# Collect data from all systems
	if not _collect_game_state_data(save_data):
		print("SaveSystem: Failed to collect game state data")
		emit_signal("save_completed", false)
		return false
	
	if not _collect_inventory_data(save_data):
		print("SaveSystem: Failed to collect inventory data")
		emit_signal("save_completed", false)
		return false
	
	if not _collect_tea_manager_data(save_data):
		print("SaveSystem: Failed to collect tea manager data")
		emit_signal("save_completed", false)
		return false
	
	if not _collect_milk_system_data(save_data):
		print("SaveSystem: Failed to collect milk system data")
		emit_signal("save_completed", false)
		return false
	
	if not _collect_phase_manager_data(save_data):
		print("SaveSystem: Failed to collect phase manager data")
		emit_signal("save_completed", false)
		return false
	
	# Write to file
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		print("SaveSystem: Failed to open save file for writing")
		emit_signal("save_completed", false)
		return false
	
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	print("SaveSystem: Save completed successfully")
	emit_signal("save_completed", true)
	return true

func load_game() -> bool:
	print("SaveSystem: Starting load operation...")
	
	if not has_save_file():
		print("SaveSystem: No save file found")
		emit_signal("load_completed", false)
		return false
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		print("SaveSystem: Failed to open save file for reading")
		emit_signal("load_completed", false)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("SaveSystem: Failed to parse save file JSON")
		emit_signal("load_completed", false)
		return false
	
	var save_data = json.data
	
	# Validate save file version
	if not _validate_save_version(save_data):
		print("SaveSystem: Save file version mismatch")
		emit_signal("load_completed", false)
		return false
	
	# Restore data to all systems
	if not _restore_game_state_data(save_data):
		print("SaveSystem: Failed to restore game state data")
		emit_signal("load_completed", false)
		return false
	
	if not _restore_inventory_data(save_data):
		print("SaveSystem: Failed to restore inventory data")
		emit_signal("load_completed", false)
		return false
	
	if not _restore_tea_manager_data(save_data):
		print("SaveSystem: Failed to restore tea manager data")
		emit_signal("load_completed", false)
		return false
	
	if not _restore_milk_system_data(save_data):
		print("SaveSystem: Failed to restore milk system data")
		emit_signal("load_completed", false)
		return false
	
	if not _restore_phase_manager_data(save_data):
		print("SaveSystem: Failed to restore phase manager data")
		emit_signal("load_completed", false)
		return false
	
	# Restore auto-save settings
	_restore_player_settings(save_data)
	
	print("SaveSystem: Load completed successfully")
	emit_signal("load_completed", true)
	return true

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

func delete_save_file() -> bool:
	if has_save_file():
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		return true
	return false

func get_save_file_info() -> Dictionary:
	if not has_save_file():
		return {}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return {}
	
	var save_data = json.data
	return {
		"timestamp": save_data.get("timestamp", "Unknown"),
		"day": save_data.get("game_state", {}).get("current_day", 1),
		"money": save_data.get("game_state", {}).get("money", 0.0),
		"reputation": save_data.get("game_state", {}).get("reputation", 3)
	}

# Auto-save functionality
func enable_auto_save(enabled: bool) -> void:
	auto_save_enabled = enabled
	if enabled:
		auto_save_timer.start()
	else:
		auto_save_timer.stop()
	print("SaveSystem: Auto-save ", "enabled" if enabled else "disabled")

func set_auto_save_interval(seconds: float) -> void:
	auto_save_timer.wait_time = seconds
	print("SaveSystem: Auto-save interval set to ", seconds, " seconds")

func _on_auto_save_timer_timeout() -> void:
	if auto_save_enabled:
		print("SaveSystem: Performing auto-save...")
		save_game()

# Data collection methods (to be implemented based on your specific systems)
func _collect_game_state_data(save_data: Dictionary) -> bool:
	if not GameState:
		return false
	
	save_data.game_state = {
		"money": GameState.money,
		"reputation": GameState.reputation,
		"current_day": GameState.current_day,
		"current_weather": GameState.current_weather,
		"daily_revenue": GameState.daily_revenue,
		"satisfaction_history": GameState.satisfaction_history,
		"is_initialized": GameState.is_initialized
	}
	return true

func _collect_inventory_data(save_data: Dictionary) -> bool:
	# This will need to be implemented based on your InventorySystem structure
	# You'll need to add a get_save_data() method to your InventorySystem
	
	# Example structure:
	# save_data.inventory = inventory_system.get_save_data() if inventory_system else {}
	save_data.inventory = {}  # Placeholder
	return true

func _collect_tea_manager_data(save_data: Dictionary) -> bool:
	if not TeaManager:
		return false
	
	save_data.tea_manager = {
		"unlocked_teas": TeaManager.unlocked_teas,
		"prices": TeaManager.prices
	}
	return true

func _collect_milk_system_data(save_data: Dictionary) -> bool:
	# This will need to be implemented based on your MilkSystem structure
	save_data.milk_system = {}  # Placeholder
	return true

func _collect_phase_manager_data(save_data: Dictionary) -> bool:
	# This will need to be implemented based on your PhaseManager structure
	save_data.phase_manager = {}  # Placeholder
	return true

# Data restoration methods
func _restore_game_state_data(save_data: Dictionary) -> bool:
	if not GameState:
		return false
	
	var game_state_data = save_data.get("game_state", {})
	GameState.money = game_state_data.get("money", 1000.0)
	GameState.reputation = game_state_data.get("reputation", 3)
	GameState.current_day = game_state_data.get("current_day", 1)
	GameState.current_weather = game_state_data.get("current_weather", "sunny")
	GameState.daily_revenue = game_state_data.get("daily_revenue", 0.0)
	GameState.satisfaction_history = game_state_data.get("satisfaction_history", [])
	GameState.is_initialized = game_state_data.get("is_initialized", false)
	
	# Emit signals to update UI
	GameState.emit_signal("money_changed", GameState.money)
	GameState.emit_signal("reputation_changed", GameState.reputation)
	
	return true

func _restore_inventory_data(save_data: Dictionary) -> bool:
	# To be implemented based on your InventorySystem
	return true

func _restore_tea_manager_data(save_data: Dictionary) -> bool:
	if not TeaManager:
		return false
	
	var tea_data = save_data.get("tea_manager", {})
	TeaManager.unlocked_teas = tea_data.get("unlocked_teas", ["Builder's Tea"])
	TeaManager.prices = tea_data.get("prices", {})
	
	return true

func _restore_milk_system_data(save_data: Dictionary) -> bool:
	# To be implemented based on your MilkSystem
	return true

func _restore_phase_manager_data(save_data: Dictionary) -> bool:
	# To be implemented based on your PhaseManager
	return true

func _restore_player_settings(save_data: Dictionary) -> void:
	var settings = save_data.get("player_settings", {})
	auto_save_enabled = settings.get("auto_save_enabled", false)
	var interval = settings.get("auto_save_interval", 300.0)
	set_auto_save_interval(interval)
	enable_auto_save(auto_save_enabled)

func _validate_save_version(save_data: Dictionary) -> bool:
	var file_version = save_data.get("version", "")
	if file_version != SAVE_VERSION:
		print("SaveSystem: Version mismatch. File: ", file_version, ", Expected: ", SAVE_VERSION)
		# Here you could implement version migration logic
		return false
	return true
