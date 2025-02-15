extends PanelContainer

@onready var queue_display = $MarginContainer/VBoxContainer/QueueDisplay
@onready var queue_count = $MarginContainer/VBoxContainer/Header/QueueCount

const MAX_QUEUE_SIZE = 5
const EMPTY_COLOR = Color(0.5, 0.5, 0.5, 0.3)
const OCCUPIED_COLOR = Color(0.4, 0.6, 1.0, 1.0)

var current_queue = []
var slot_nodes = []
var update_pending = false

func _ready():
	_create_empty_slots()
	update_display()

func _create_empty_slots():
	for child in queue_display.get_children():
		child.queue_free()
	
	slot_nodes.clear()
	for i in range(MAX_QUEUE_SIZE):
		var slot = PanelContainer.new()
		slot.custom_minimum_size = Vector2(40, 40)
		slot.add_theme_stylebox_override("panel", get_theme_stylebox("panel"))
		slot.modulate = EMPTY_COLOR
		queue_display.add_child(slot)
		slot_nodes.append(slot)

func add_customer() -> bool:
	if current_queue.size() >= MAX_QUEUE_SIZE:
		return false
	
	current_queue.append(true)
	_request_update()
	return true

func remove_customer() -> void:
	if current_queue.size() > 0:
		current_queue.pop_front()
		_request_update()

func _request_update() -> void:
	if !update_pending:
		update_pending = true
		call_deferred("_perform_update")

func _perform_update() -> void:
	if !update_pending:
		return
		
	# Update slot visuals
	for i in range(slot_nodes.size()):
		var should_be_occupied = i < current_queue.size()
		var is_occupied = slot_nodes[i].modulate.a > 0.5
		
		if should_be_occupied != is_occupied:
			slot_nodes[i].modulate = OCCUPIED_COLOR if should_be_occupied else EMPTY_COLOR
	
	# Update counter
	queue_count.text = "%d/%d" % [current_queue.size(), MAX_QUEUE_SIZE]
	
	update_pending = false

func update_display() -> void:
	_request_update()

func clear_queue() -> void:
	current_queue.clear()
	_request_update()

func get_queue_size() -> int:
	return current_queue.size()

func is_full() -> bool:
	return current_queue.size() >= MAX_QUEUE_SIZE
