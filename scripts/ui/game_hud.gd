# game_hud.gd
extends Control

var inventory_system: InventorySystem
var customer_demand: CustomerDemand

@onready var customer_queue_display = $TopBar/HBoxContainer/QueueDisplay
@onready var phase_label = $TopBar/HBoxContainer/PhaseLabel
@onready var timer_progress = $TopBar/HBoxContainer/TimerProgress

func _ready():
	# Initialize systems
	inventory_system = InventorySystem.new()
	customer_demand = CustomerDemand.new()
	
	# Connect systems
	customer_demand.setup(inventory_system)
	
	# Connect signals
	customer_demand.connect("customer_missed", _on_customer_missed)
	inventory_system.connect("stock_changed", _on_stock_changed)
	
	# Initial setup
	_update_inventory_display()

func _on_customer_missed(reason: int) -> void:
	var reason_text = ""
	match reason:
		CustomerDemand.MissReason.NO_TEA_TYPE:
			reason_text = "Wrong tea type!"
		CustomerDemand.MissReason.OUT_OF_STOCK:
			reason_text = "Out of stock!"
		CustomerDemand.MissReason.NO_STAFF:
			reason_text = "No staff available!"
		CustomerDemand.MissReason.TOO_BUSY:
			reason_text = "Queue full!"
	
	# Show floating text
	var float_text = Label.new()
	float_text.text = reason_text
	float_text.modulate = Color.RED
	add_child(float_text)
	
	# Animate and remove
	var tween = create_tween()
	tween.tween_property(float_text, "position:y", float_text.position.y - 50, 1.0)
	tween.tween_property(float_text, "modulate:a", 0.0, 0.5)
	tween.tween_callback(float_text.queue_free)
	
	# Update missed customers label
	var missed_label = get_node_or_null("SidePanel/VBoxContainer/StatsPanel/MissedCustomersLabel")
	if missed_label:
		missed_label.text = "Missed: " + str(customer_demand.daily_stats.total_potential - customer_demand.daily_stats.served)

func _on_stock_changed(tea_name: String, amount: int) -> void:
	var stock_label = get_node_or_null("SidePanel/VBoxContainer/InventoryPanel/TeaList/" + tea_name.replace(" ", "") + "/Amount")
	if stock_label:
		stock_label.text = str(amount)
		if amount <= 5:
			stock_label.modulate = Color.RED
		elif amount <= 10:
			stock_label.modulate = Color.YELLOW
		else:
			stock_label.modulate = Color.WHITE

func _update_inventory_display() -> void:
	for tea_name in inventory_system.inventory.keys():
		_on_stock_changed(tea_name, inventory_system.get_stock(tea_name))
