extends PanelContainer

var tea_data: Dictionary
var update_pending = false

func setup(data: Dictionary) -> void:
	var changed = false
	
	# Only trigger update if data has actually changed
	if !tea_data.hash() == data.hash():
		tea_data = data.duplicate()
		changed = true
	
	if changed:
		_request_update()

func _request_update() -> void:
	if !update_pending:
		update_pending = true
		call_deferred("_perform_update")

func _perform_update() -> void:
	if !update_pending:
		return
		
	# Update name
	$MarginContainer/VBoxContainer/Header/NameLabel.text = tea_data.name
	
	# Update costs
	$MarginContainer/VBoxContainer/Costs/CostLabel.text = "Cost: £%.2f" % tea_data.cost
	$MarginContainer/VBoxContainer/Costs/PriceLabel.text = "Price: £%.2f" % tea_data.price
	
	# Update quality stars
	var stars = $MarginContainer/VBoxContainer/QualityContainer/Stars
	var existing_stars = stars.get_child_count()
	var needed_stars = 5
	
	# Only update stars if needed
	if existing_stars != needed_stars:
		for child in stars.get_children():
			child.queue_free()
			
		for i in range(5):
			var star = Label.new()
			star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			star.custom_minimum_size = Vector2(16, 16)
			if i < tea_data.quality:
				star.text = "★"
				star.add_theme_color_override("font_color", Color(1, 0.8, 0, 1))
			else:
				star.text = "☆"
				star.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
			stars.add_child(star)
	
	# Update satisfaction
	$MarginContainer/VBoxContainer/SatisfactionLabel.text = "Customer Satisfaction: %d%%" % tea_data.satisfaction
	
	# Update unlock info
	var unlock_info = $MarginContainer/VBoxContainer/UnlockInfo
	unlock_info.visible = !tea_data.unlocked
	if !tea_data.unlocked and tea_data.has("unlock_condition"):
		unlock_info.text = tea_data.unlock_condition
	
	# Update visual state
	modulate = Color(1, 1, 1, 1.0 if tea_data.unlocked else 0.5)
	
	# Update stock display
	var stock_label = null
	for child in $MarginContainer/VBoxContainer.get_children():
		if child.name.begins_with("StockLabel"):
			stock_label = child
			break
	
	if tea_data.has("current_stock"):
		if !stock_label:
			stock_label = Label.new()
			stock_label.name = "StockLabel"
			stock_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
			$MarginContainer/VBoxContainer.add_child(stock_label)
		stock_label.text = "Stock: %d" % tea_data.current_stock
	elif stock_label:
		stock_label.queue_free()
	
	update_pending = false

func update_display() -> void:
	_request_update()
