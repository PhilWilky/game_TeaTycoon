# stock_management.gd
extends PanelContainer

signal stock_purchased(tea_name: String, amount: int, total_cost: float)

@onready var tea_list = $MarginContainer/VBoxContainer/TeaList
@onready var restock_button = $MarginContainer/VBoxContainer/RestockButton
@onready var low_stock_warning = $MarginContainer/VBoxContainer/LowStockWarning
@onready var total_cost_label = $MarginContainer/VBoxContainer/TotalCost/Amount

var inventory_system: InventorySystem
var tea_manager = TeaManager  # Direct reference
var tea_rows = {}

func _ready() -> void:
	print("Stock Management: Ready")
	Events.day_started.connect(_on_day_started)
	Events.day_ended.connect(_on_day_ended)
	Events.tea_unlocked.connect(_on_tea_unlocked)
	
	restock_button.pressed.connect(_on_restock_pressed)
	restock_button.disabled = false  # Enable for testing

	# Initial tea row creation
	call_deferred("_create_tea_rows")

func setup(inventory: InventorySystem) -> void:
	print("Stock Management: Setup with inventory system")
	inventory_system = inventory
	_create_tea_rows()  # Create again in case setup happens after _ready
	_update_stock_display()
	
	inventory_system.stock_changed.connect(_on_stock_changed)
	inventory_system.stock_depleted.connect(_on_stock_depleted)
	inventory_system.restock_needed.connect(_on_restock_needed)

func _create_tea_rows() -> void:
	print("Creating tea rows for:", tea_manager.unlocked_teas)
	# Clear existing rows except header
	for child in tea_list.get_children():
		if child.name != "HeaderRow":
			child.queue_free()
	
	tea_rows.clear()
	
	# Create rows for each unlocked tea
	for tea_name in tea_manager.unlocked_teas:
		print("Creating row for:", tea_name)
		var row = HBoxContainer.new()
		row.name = tea_name.replace(" ", "")
		
		# Tea name
		var name_label = Label.new()
		name_label.text = tea_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		
		# Cost
		var cost_label = Label.new()
		cost_label.text = "£%.2f" % tea_manager.TEA_DATA[tea_name].cost
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(cost_label)
		
		# Stock
		var stock_label = Label.new()
		stock_label.name = "StockLabel"
		stock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stock_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(stock_label)
		
		# Buy amount spinner
		var spinner = SpinBox.new()
		spinner.name = "RestockAmount"
		spinner.min_value = 0
		spinner.max_value = 50
		spinner.step = 1
		spinner.value = 0
		spinner.rounded = true
		spinner.custom_minimum_size = Vector2(100, 0)  # Set minimum width
		spinner.value_changed.connect(_on_restock_value_changed)
		row.add_child(spinner)
		
		tea_list.add_child(row)
		tea_rows[tea_name] = row
		
	_update_stock_display()

func _update_stock_display() -> void:
	if not inventory_system:
		print("No inventory system available")
		return
		
	var total = 0.0
	
	for tea_name in tea_rows:
		var row = tea_rows[tea_name]
		var stock_level = inventory_system.get_stock(tea_name)
		var max_capacity = inventory_system.get_max_capacity(tea_name)
		
		# Update stock display
		var stock_label = row.get_node("StockLabel")
		stock_label.text = "%d/%d" % [stock_level, max_capacity]
		
		# Calculate running total from spinbox values
		var spinner = row.get_node("RestockAmount")
		var tea_cost = tea_manager.TEA_DATA[tea_name].cost
		total += spinner.value * tea_cost
	
	# Update total cost display
	total_cost_label.text = "£%.2f" % total

func _on_restock_value_changed(_value: float) -> void:
	_update_stock_display()

func _on_restock_pressed() -> void:
	var total_cost = 0.0
	var purchases = {}
	
	# Calculate total cost and collect purchases
	for tea_name in tea_rows:
		var row = tea_rows[tea_name]
		var amount = row.get_node("RestockAmount").value
		if amount > 0:
			var tea_cost = tea_manager.TEA_DATA[tea_name].cost
			var space_available = inventory_system.get_max_capacity(tea_name) - inventory_system.get_stock(tea_name)
			var actual_restock = min(amount, space_available)
			total_cost += actual_restock * tea_cost
			purchases[tea_name] = {
				"requested": amount,
				"actual": actual_restock
			}
	
	# Check if we can afford it
	if total_cost > GameState.money:
		Events.emit_signal("show_notification", "Cannot Afford", "Not enough money for restock!", "error")
		return
	
	var partial_restock = false
	var restock_message = ""
	
	# Process all purchases
	for tea_name in purchases:
		var requested = purchases[tea_name].requested
		var actual = purchases[tea_name].actual
		
		inventory_system.restock_tea(tea_name, requested)
		
		if actual < requested:
			partial_restock = true
			restock_message += "%s: %d/%d units, " % [tea_name, actual, requested]
		
		# Reset spinner
		tea_rows[tea_name].get_node("RestockAmount").value = 0
	
	# Deduct total cost
	GameState.spend_money(total_cost)
	
	# Show appropriate notification
	if partial_restock:
		restock_message = restock_message.trim_suffix(", ")
		Events.emit_signal("show_notification", "Partial Restock", 
			"Some items couldn't be fully restocked due to capacity.\n" + restock_message, 
			"warning")
	else:
		Events.emit_signal("show_notification", "Restock Complete", 
			"Successfully restocked inventory for £%.2f" % total_cost, 
			"success")
	
	_update_stock_display()

func _on_tea_unlocked(tea_name: String) -> void:
	_create_tea_rows()  # Recreate all rows to include the new tea
	_update_stock_display()

func _on_stock_changed(tea_name: String, _amount: int) -> void:
	_update_stock_display()

func _on_stock_depleted(tea_name: String) -> void:
	if tea_name in tea_rows:
		var stock_label = tea_rows[tea_name].get_node("StockLabel")
		stock_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
		
	low_stock_warning.visible = true
	low_stock_warning.text = "%s is out of stock!" % tea_name

func _on_restock_needed(tea_name: String) -> void:
	low_stock_warning.visible = true
	low_stock_warning.text = "Low stock warning: %s" % tea_name

func _on_day_started(_day: int) -> void:
	restock_button.disabled = true  # Disable restocking during day operation

func _on_day_ended(_day: int, _stats: Dictionary) -> void:
	restock_button.disabled = false  # Enable restocking during morning prep
