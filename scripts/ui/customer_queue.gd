# customer_queue.gd
extends PanelContainer

@onready var queue_display = $MarginContainer/VBoxContainer/QueueDisplay
@onready var queue_count = $MarginContainer/VBoxContainer/Header/QueueCount

const MAX_QUEUE_SIZE = 5
const EMPTY_COLOR = Color(0.5, 0.5, 0.5, 0.3)
const OCCUPIED_COLOR = Color(0.4, 0.6, 1.0, 1.0)

var customer_slots = []
var current_queue_size = 0

func _ready() -> void:
	print("CustomerQueue: Initializing...")
	create_queue_slots()
	update_display()
	print("CustomerQueue: Initialized with %d slots" % MAX_QUEUE_SIZE)

func create_queue_slots() -> void:
	print("CustomerQueue: Creating queue slots")
	# Clear any existing slots
	for child in queue_display.get_children():
		child.queue_free()
	
	customer_slots.clear()
	
	# Create new slots
	for i in range(MAX_QUEUE_SIZE):
		var slot = PanelContainer.new()
		slot.custom_minimum_size = Vector2(40, 40)
		slot.add_theme_stylebox_override("panel", get_theme_stylebox("panel"))
		slot.modulate = EMPTY_COLOR
		
		queue_display.add_child(slot)
		customer_slots.append(slot)
	
	current_queue_size = 0
	print("CustomerQueue: Created %d queue slots" % MAX_QUEUE_SIZE)

func add_customer() -> bool:
	print("CustomerQueue: Attempting to add customer. Current size: %d/%d" % [current_queue_size, MAX_QUEUE_SIZE])
	
	if current_queue_size >= MAX_QUEUE_SIZE:
		print("CustomerQueue: Queue is full!")
		return false
	
	current_queue_size += 1
	update_display()
	print("CustomerQueue: Customer added. New size: %d/%d" % [current_queue_size, MAX_QUEUE_SIZE])
	return true

func remove_customer() -> void:
	if current_queue_size > 0:
		print("CustomerQueue: Removing customer. Current size: %d/%d" % [current_queue_size, MAX_QUEUE_SIZE])
		current_queue_size -= 1
		update_display()
		print("CustomerQueue: Customer removed. New size: %d/%d" % [current_queue_size, MAX_QUEUE_SIZE])

func clear_queue() -> void:
	print("CustomerQueue: Clearing queue")
	current_queue_size = 0
	update_display()

func update_display() -> void:
	# Update queue count display
	queue_count.text = "%d/%d" % [current_queue_size, MAX_QUEUE_SIZE]
	
	# Update slot visuals
	for i in range(customer_slots.size()):
		var should_be_occupied = i < current_queue_size
		customer_slots[i].modulate = OCCUPIED_COLOR if should_be_occupied else EMPTY_COLOR

func is_full() -> bool:
	return current_queue_size >= MAX_QUEUE_SIZE

func get_queue_size() -> int:
	return current_queue_size
