# pause_menu.gd
extends Control

signal resume_requested
signal save_requested
signal main_menu_requested

@onready var background_overlay = $BackgroundOverlay
@onready var pause_panel = $CenterContainer/PausePanel
@onready var resume_button = $CenterContainer/PausePanel/MarginContainer/VBoxContainer/ButtonContainer/ResumeButton
@onready var save_button = $CenterContainer/PausePanel/MarginContainer/VBoxContainer/ButtonContainer/SaveButton
@onready var options_button = $CenterContainer/PausePanel/MarginContainer/VBoxContainer/ButtonContainer/OptionsButton
@onready var main_menu_button = $CenterContainer/PausePanel/MarginContainer/VBoxContainer/ButtonContainer/MainMenuButton
@onready var quit_button = $CenterContainer/PausePanel/MarginContainer/VBoxContainer/ButtonContainer/QuitButton

@onready var save_status_label = $CenterContainer/PausePanel/MarginContainer/VBoxContainer/SaveStatusLabel
@onready var confirmation_dialog = $ConfirmationDialog
@onready var save_dialog = $SaveDialog

var is_saving = false
var pending_action = ""

func _ready() -> void:
	print("PauseMenu: Initializing...")
	
	# Set process mode to always so it works when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	options_button.pressed.connect(_on_options_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Connect save system signals
	SaveSystem.save_completed.connect(_on_save_completed)
	
	# Connect dialog signals
	confirmation_dialog.confirmed.connect(_on_confirmation_confirmed)
	confirmation_dialog.canceled.connect(_on_confirmation_canceled)
	
	# Setup initial state
	_update_save_status()
	
	print("PauseMenu: Ready")

func _update_save_status() -> void:
	if SaveSystem.has_save_file():
		var save_info = SaveSystem.get_save_file_info()
		if save_info.size() > 0:
			save_status_label.text = "Last Save: Day %d - %s" % [save_info.day, save_info.timestamp]
		else:
			save_status_label.text = "Save file exists"
	else:
		save_status_label.text = "No save file found"

func _on_resume_pressed() -> void:
	print("PauseMenu: Resume pressed")
	emit_signal("resume_requested")

func _on_save_pressed() -> void:
	if is_saving:
		return
		
	print("PauseMenu: Save pressed")
	is_saving = true
	save_button.disabled = true
	save_button.text = "Saving..."
	
	# Show save dialog
	save_dialog.dialog_text = "Saving game..."
	save_dialog.popup_centered()
	
	# Start save operation
	SaveSystem.save_game()

func _on_save_completed(success: bool) -> void:
	is_saving = false
	save_button.disabled = false
	save_button.text = "Save Game"
	
	if save_dialog.visible:
		save_dialog.hide()
	
	if success:
		print("PauseMenu: Save completed successfully")
		_update_save_status()
		
		# Show brief success message
		var success_dialog = AcceptDialog.new()
		success_dialog.dialog_text = "Game saved successfully!"
		success_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(success_dialog)
		success_dialog.popup_centered()
		
		# Auto-close after 2 seconds
		var timer = Timer.new()
		timer.wait_time = 2.0
		timer.one_shot = true
		timer.timeout.connect(func(): 
			if success_dialog and is_instance_valid(success_dialog):
				success_dialog.queue_free()
			if timer and is_instance_valid(timer):
				timer.queue_free()
		)
		add_child(timer)
		timer.start()
		
		emit_signal("save_requested")
	else:
		print("PauseMenu: Save failed")
		var error_dialog = AcceptDialog.new()
		error_dialog.dialog_text = "Failed to save game. Please try again."
		error_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(error_dialog)
		error_dialog.popup_centered()
		error_dialog.confirmed.connect(error_dialog.queue_free)

func _on_options_pressed() -> void:
	print("PauseMenu: Options pressed")
	# TODO: Implement options menu
	var placeholder_dialog = AcceptDialog.new()
	placeholder_dialog.dialog_text = "Options menu not yet implemented."
	placeholder_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(placeholder_dialog)
	placeholder_dialog.popup_centered()
	placeholder_dialog.confirmed.connect(placeholder_dialog.queue_free)

func _on_main_menu_pressed() -> void:
	print("PauseMenu: Main Menu pressed")
	pending_action = "main_menu"
	confirmation_dialog.dialog_text = "Return to main menu? Any unsaved progress will be lost."
	confirmation_dialog.popup_centered()

func _on_quit_pressed() -> void:
	print("PauseMenu: Quit pressed")
	pending_action = "quit"
	confirmation_dialog.dialog_text = "Quit game? Any unsaved progress will be lost."
	confirmation_dialog.popup_centered()

func _on_confirmation_confirmed() -> void:
	match pending_action:
		"main_menu":
			print("PauseMenu: Confirmed return to main menu")
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		"quit":
			print("PauseMenu: Confirmed quit")
			get_tree().quit()
	pending_action = ""

func _on_confirmation_canceled() -> void:
	print("PauseMenu: Confirmation canceled")
	pending_action = ""

# Handle input
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not confirmation_dialog.visible and not save_dialog.visible:
		_on_resume_pressed()

# Scene file structure for PauseMenu.tscn:
# This is what you need to create in the Godot editor:

# PauseMenu (Control) - Full Rect
# ├── BackgroundOverlay (ColorRect) - Full Rect, Color: (0, 0, 0, 0.7)
# ├── CenterContainer - Center
# │   └── PausePanel (PanelContainer)
# │       └── MarginContainer
# │           └── VBoxContainer
# │               ├── TitleLabel (Label) - "Game Paused"
# │               ├── SaveStatusLabel (Label) - Shows save info
# │               └── ButtonContainer (VBoxContainer)
# │                   ├── ResumeButton (Button) - "Resume"
# │                   ├── SaveButton (Button) - "Save Game"
# │                   ├── OptionsButton (Button) - "Options"
# │                   ├── MainMenuButton (Button) - "Main Menu"
# │                   └── QuitButton (Button) - "Quit Game"
# ├── ConfirmationDialog (ConfirmationDialog)
# └── SaveDialog (AcceptDialog)
