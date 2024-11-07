extends PanelContainer

var tea_data: GameTypes.TeaItem

func setup(data):
	tea_data = data
	update_display()

func update_display():
	# Update name
	$MarginContainer/VBoxContainer/Header/NameLabel.text = tea_data.name
	
	# Update costs
	$MarginContainer/VBoxContainer/Costs/CostLabel.text = "Cost: £%.2f" % tea_data.cost
	$MarginContainer/VBoxContainer/Costs/PriceLabel.text = "Price: £%.2f" % tea_data.price
	
	# Update quality stars
	var stars = $MarginContainer/VBoxContainer/QualityContainer/Stars
	for child in stars.get_children():
		child.queue_free()
	
	for i in range(5):
		var star = TextureRect.new()
		star.custom_minimum_size = Vector2(16, 16)
		# Changed from EXPAND_KEEP_ASPECT to the correct enum
		star.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		# You'll need to add star textures to your project
		star.texture = load("res://assets/star_%s.png" % ("filled" if i < tea_data.quality else "empty"))
		stars.add_child(star)
	
	# Update satisfaction
	$MarginContainer/VBoxContainer/SatisfactionLabel.text = "Customer Satisfaction: %d%%" % tea_data.satisfaction
	
	# Show/hide unlock info
	var unlock_info = $MarginContainer/VBoxContainer/UnlockInfo
	unlock_info.visible = !tea_data.unlocked
	if !tea_data.unlocked:
		unlock_info.text = "Unlocks on Day 3" if tea_data.name == "Earl Grey" else "Unlocks at Reputation 3"
	
	# Update visual state
	modulate = Color(1, 1, 1, 1.0 if tea_data.unlocked else 0.5)
