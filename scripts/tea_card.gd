extends PanelContainer

var tea_data: Dictionary
var stock_label: Label

func _ready():
	stock_label = Label.new()
	stock_label.name = "StockLabel"
	stock_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
	stock_label.custom_minimum_size = Vector2(0, 24)  # Fixed height to prevent layout shifts
	stock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	$MarginContainer/VBoxContainer.add_child(stock_label)

func setup(data: Dictionary) -> void:
	tea_data = data.duplicate()
	
	# Add current_stock to tea_data if it's not there
	if tea_data.get("unlocked", false) and not tea_data.has("current_stock"):
		tea_data["current_stock"] = 20  # Default starting stock
		
	update_display()

func update_display() -> void:
	if not tea_data:
		return
		
	# Basic info updates
	$MarginContainer/VBoxContainer/Header/NameLabel.text = tea_data.get("name", "")
	$MarginContainer/VBoxContainer/Costs/CostLabel.text = "Cost: £%.2f" % tea_data.get("cost", 0.0)
	$MarginContainer/VBoxContainer/Costs/PriceLabel.text = "Price: £%.2f" % tea_data.get("price", 0.0)
	
	# Update satisfaction
	$MarginContainer/VBoxContainer/SatisfactionLabel.text = "Customer Satisfaction: %d%%" % tea_data.get("satisfaction", 0)
	
	# Update unlock info
	var unlock_info = $MarginContainer/VBoxContainer/UnlockInfo
	if !tea_data.get("unlocked", false) and tea_data.has("unlock_condition"):
		unlock_info.text = tea_data["unlock_condition"]
	unlock_info.visible = !tea_data.get("unlocked", false)
	
	# Update stock display
	if tea_data.get("unlocked", false):
		stock_label.show()
		var current_stock = tea_data.get("current_stock", 0)
		stock_label.text = "Stock: %d" % current_stock
		
		# Color coding for stock levels
		var stock_color = Color(0.4, 0.4, 0.4, 1)  # Default gray
		if current_stock <= 5:
			stock_color = Color(0.8, 0.2, 0.2, 1)  # Red for low stock
		stock_label.add_theme_color_override("font_color", stock_color)
	else:
		stock_label.hide()
	
	# Update visual state
	modulate = Color(1, 1, 1, 1.0 if tea_data.get("unlocked", false) else 0.5)

func update_stock(amount: int) -> void:
	if tea_data:
		tea_data["current_stock"] = amount
		# Only show stock for unlocked teas
		if tea_data.get("unlocked", false):
			stock_label.show()
			stock_label.text = "Stock: %d" % amount
			var stock_color = Color(0.4, 0.4, 0.4, 1)
			if amount <= 5:
				stock_color = Color(0.8, 0.2, 0.2, 1)
			stock_label.add_theme_color_override("font_color", stock_color)
		else:
			stock_label.hide()
