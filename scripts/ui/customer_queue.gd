# customer_queue.gd
extends PanelContainer

@onready var queue_display = $MarginContainer/VBoxContainer/QueueDisplay
@onready var queue_count = $MarginContainer/VBoxContainer/Header/QueueCount

const MAX_QUEUE_SIZE = 5
var current_queue = []
var empty_slots = []

func _ready():
	# Create empty slots
	_create_empty_slots()
	update_display()

func _create_empty_slots():
	# Clear any existing slots
	for child in queue_display.get_children():
		child.queue_free()
	
	# Create new empty slots
	empty_slots.clear()
	for i in range(MAX_QUEUE_SIZE):
		var slot = PanelContainer.new()
		slot.custom_minimum_size = Vector2(40, 40)
		slot.add_theme_stylebox_override("panel", get_theme_stylebox("panel"))
		slot.modulate = Color(0.5, 0.5, 0.5, 0.3)  # Make empty slots semi-transparent
		queue_display.add_child(slot)
		empty_slots.append(slot)

func add_customer() -> bool:
	if current_queue.size() >= MAX_QUEUE_SIZE:
		return false
	
	# Find first empty slot
	for i in range(MAX_QUEUE_SIZE):
		if i >= empty_slots.size():
			break
			
		if empty_slots[i].modulate.a < 1.0:  # Check if slot is empty
			var customer_slot = empty_slots[i]
			customer_slot.modulate = Color(0.8, 0.8, 1.0, 1.0)  # Make slot visible
			current_queue.append(customer_slot)
			update_display()
			return true
	
	return false

func remove_customer() -> void:
	if current_queue.size() > 0:
		var customer_slot = current_queue.pop_front()
		customer_slot.modulate = Color(0.5, 0.5, 0.5, 0.3)  # Make slot empty again
		update_display()

func update_display() -> void:
	queue_count.text = "%d/%d" % [current_queue.size(), MAX_QUEUE_SIZE]

func clear_queue() -> void:
	for slot in empty_slots:
		slot.modulate = Color(0.5, 0.5, 0.5, 0.3)
	current_queue.clear()
	update_display()

func get_queue_size() -> int:
	return current_queue.size()

func is_full() -> bool:
	return current_queue.size() >= MAX_QUEUE_SIZE
