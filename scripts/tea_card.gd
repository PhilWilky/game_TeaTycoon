extends PanelContainer

var tea_data: Dictionary

func setup(data: Dictionary) -> void:
	tea_data = data
	update_display()

func update_display() -> void:
	# Update name
	$MarginContainer/VBoxContainer/Header/NameLabel.text = tea_data.name
	
	# Update costs
	$MarginContainer/VBoxContainer/Costs/CostLabel.text = "Cost: £%.2f" % tea_data.cost
	$MarginContainer/VBoxContainer/Costs/PriceLabel.text = "Price: £%.2f" % tea_data.price
	
	# Update quality stars using Label nodes instead of TextureRect
	var stars = $MarginContainer/VBoxContainer/QualityContainer/Stars
	for child in stars.get_children():
		child.queue_free()
	
	for i in range(5):
		var star = Label.new()
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star.custom_minimum_size = Vector2(16, 16)
		# Use Unicode star characters
		if i < tea_data.quality:
			star.text = "★"  # Filled star
			star.add_theme_color_override("font_color", Color(1, 0.8, 0, 1))  # Gold color
		else:
			star.text = "☆"  # Empty star
			star.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))  # Gray color
		stars.add_child(star)
	
	# Update satisfaction
	$MarginContainer/VBoxContainer/SatisfactionLabel.text = "Customer Satisfaction: %d%%" % tea_data.satisfaction
	
	# Show/hide unlock info
	var unlock_info = $MarginContainer/VBoxContainer/UnlockInfo
	unlock_info.visible = !tea_data.unlocked
	if !tea_data.unlocked:
		if tea_data.has("unlock_condition"):
			unlock_info.text = tea_data.unlock_condition
	
	# Update visual state
	modulate = Color(1, 1, 1, 1.0 if tea_data.unlocked else 0.5)
	
	# Clean up any existing stock labels by their name
	var existing_labels = []
	for child in $MarginContainer/VBoxContainer.get_children():
		if child.name.begins_with("StockLabel"):
			existing_labels.append(child)
	
	for label in existing_labels:
		label.queue_free()
	
	# Add new stock display
	if tea_data.has("current_stock"):
		var stock_label = Label.new()
		stock_label.name = "StockLabel_" + str(tea_data.current_stock)  # Unique name
		stock_label.text = "Stock: %d" % tea_data.current_stock
		stock_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
		$MarginContainer/VBoxContainer.add_child(stock_label)
