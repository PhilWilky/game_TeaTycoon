# ui/tab_notification_system.gd
class_name TabNotificationSystem
extends RefCounted

var tab_container: TabContainer
var original_titles: Dictionary = {}
var active_notifications: Dictionary = {}
var _switching_with_notification: bool = false

func _init(container: TabContainer):
	tab_container = container
	# Store original tab titles
	for i in range(tab_container.get_tab_count()):
		var control = tab_container.get_tab_control(i)
		original_titles[control] = tab_container.get_tab_title(i)
	
	# Connect to tab selection to auto-clear notifications
	tab_container.tab_selected.connect(_on_tab_selected)

func add_notification(tab_control: Control, indicator: String = "•") -> void:
	if not tab_control or not original_titles.has(tab_control):
		return
		
	var tab_index = tab_container.get_tab_idx_from_control(tab_control)
	if tab_index < 0:
		return
	
	# Store notification state
	active_notifications[tab_control] = indicator
	
	# Update tab title with indicator
	var original_title = original_titles[tab_control]
	tab_container.set_tab_title(tab_index, original_title + " " + indicator)

func clear_notification(tab_control: Control) -> void:
	if not active_notifications.has(tab_control):
		return
		
	var tab_index = tab_container.get_tab_idx_from_control(tab_control)
	if tab_index < 0:
		return
	
	# Restore original title
	var original_title = original_titles[tab_control]
	tab_container.set_tab_title(tab_index, original_title)
	
	# Remove from active notifications
	active_notifications.erase(tab_control)

func has_notification(tab_control: Control) -> bool:
	return active_notifications.has(tab_control)

func switch_to_tab_with_notification(tab_control: Control) -> void:
	var tab_index = tab_container.get_tab_idx_from_control(tab_control)
	if tab_index >= 0:
		add_notification(tab_control)
		# Switch to tab but don't auto-clear the notification immediately
		_switching_with_notification = true
		tab_container.current_tab = tab_index
		_switching_with_notification = false

func _on_tab_selected(tab_index: int) -> void:
	# Don't auto-clear when we're programmatically switching to show a notification
	if _switching_with_notification:
		return
		
	var selected_control = tab_container.get_tab_control(tab_index)
	# Auto-clear notification when tab is viewed by user interaction
	clear_notification(selected_control)
