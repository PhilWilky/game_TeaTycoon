extends PanelContainer

var staff_data: GameTypes.StaffMember

func setup(data):
	staff_data = data
	update_display()

func update_display():
	# Update name and type
	$MarginContainer/VBoxContainer/Header/NameLabel.text = staff_data.name
	$MarginContainer/VBoxContainer/Header/TypeLabel.text = staff_data.type
	
	# Update stats
	$MarginContainer/VBoxContainer/Stats/EfficiencyContainer/Value.text = "%d%%" % staff_data.efficiency
	$MarginContainer/VBoxContainer/Stats/SalaryContainer/Value.text = "£%.2f/hour" % staff_data.salary
	$MarginContainer/VBoxContainer/Stats/ShiftContainer/Value.text = staff_data.shift.capitalize()
	
	# Update colors based on staff type
	var type_color = Color.BLUE
	match staff_data.type:
		"Trainee":
			type_color = Color(0.2, 0.7, 0.2) # Green
		"Regular Staff":
			type_color = Color(0.2, 0.2, 0.8) # Blue
		"Expert":
			type_color = Color(0.8, 0.2, 0.8) # Purple
	
	$MarginContainer/VBoxContainer/Header/NameLabel.add_theme_color_override("font_color", type_color)
