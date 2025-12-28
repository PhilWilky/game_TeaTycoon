# main_menu.gd
extends Control

@onready var new_game_button = $CenterContainer/VBoxContainer/ButtonContainer/NewGameButton
@onready var load_game_button = $CenterContainer/VBoxContainer/ButtonContainer/LoadGameButton
@onready var options_button = $CenterContainer/VBoxContainer/ButtonContainer/OptionsButton
@onready var quit_button = $CenterContainer/VBoxContainer/ButtonContainer/QuitButton
@onready var save_info_label = $CenterContainer/VBoxContainer/SaveInfoContainer/SaveInfoLabel
@onready var confirmation_dialog = $ConfirmationDialog
@onready var loading_dialog = $LoadingDialog

var pending_new_game = false

func _ready() -> void:
	print("MainMenu: Initializing...")
	
	# Connect button signals
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Connect dialog signals
	confirmation_dialog.confirmed.connect(_on_confirmation_confirmed)
	
	# Check for save file
	_update_save_info()
	
	print("MainMenu: Ready")

func _update_save_info() -> void:
	# Check if SaveSystem exists and has a save file
	if not has_node("/root/SaveSystem"):
		save_info_label.text = "No save file found"
		load_game_button.disabled = true
		return
		
	var save_system = get_node("/root/SaveSystem")
	if save_system.has_method("has_save_file") and save_system.has_save_file():
		if save_system.has_method("get_save_file_info"):
			var save_info = save_system.get_save_file_info()
			if save_info.has("day"):
				save_info_label.text = "Last Save: Day %d" % save_info.day
			else:
				save_info_label.text = "Save file found"
		else:
			save_info_label.text = "Save file found"
		load_game_button.disabled = false
	else:
		save_info_label.text = "No save file found"
		load_game_button.disabled = true

func _on_new_game_pressed() -> void:
	print("MainMenu: New Game pressed")
	
	# Check if save exists
	if has_node("/root/SaveSystem"):
		var save_system = get_node("/root/SaveSystem")
		if save_system.has_method("has_save_file") and save_system.has_save_file():
			# Show confirmation if save exists
			pending_new_game = true
			confirmation_dialog.popup_centered()
			return
	
	# Start new game directly if no save exists
	_start_new_game()

func _on_confirmation_confirmed() -> void:
	if pending_new_game:
		_start_new_game()
		pending_new_game = false

func _start_new_game() -> void:
	print("MainMenu: Starting new game...")
	
	# Initialize GameState
	if has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		if game_state.has_method("initialize"):
			game_state.initialize()
	
	# Load the main game scene
	get_tree().change_scene_to_file("res://scenes/TeaShop.tscn")

func _on_load_game_pressed() -> void:
	print("MainMenu: Load Game pressed")
	
	if not has_node("/root/SaveSystem"):
		print("MainMenu: SaveSystem not found")
		return
	
	var save_system = get_node("/root/SaveSystem")
	
	# Check if save file exists
	if not save_system.has_save_file():
		print("MainMenu: No save file found")
		var error_dialog = AcceptDialog.new()
		error_dialog.dialog_text = "No save file found."
		add_child(error_dialog)
		error_dialog.popup_centered()
		error_dialog.confirmed.connect(error_dialog.queue_free)
		return
	
	loading_dialog.popup_centered()
	
	# Set flag to load after TeaShop initializes
	save_system.should_load_on_ready = true
	
	print("MainMenu: Loading game...")
	get_tree().change_scene_to_file("res://scenes/TeaShop.tscn")
	
	loading_dialog.hide()

func _on_options_pressed() -> void:
	print("MainMenu: Options pressed")
	# TODO: Implement options menu
	var placeholder = AcceptDialog.new()
	placeholder.dialog_text = "Options menu not yet implemented."
	add_child(placeholder)
	placeholder.popup_centered()
	placeholder.confirmed.connect(placeholder.queue_free)

func _on_quit_pressed() -> void:
	print("MainMenu: Quit pressed")
	get_tree().quit()
