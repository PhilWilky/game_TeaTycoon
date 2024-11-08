class_name GameHUD
extends Control

# Node references
@onready var report_tab = $ContentContainer/VBoxContainer/MainContent/TabContainer/Reports
@onready var revenue_amount = $ContentContainer/VBoxContainer/MainContent/TabContainer/Reports/ScrollContainer/StatsContainer/KeyMetrics/RevenueCard/VBox/Amount
@onready var customers_amount = $ContentContainer/VBoxContainer/MainContent/TabContainer/Reports/ScrollContainer/StatsContainer/KeyMetrics/CustomerCard/VBox/Amount
@onready var satisfaction_amount = $ContentContainer/VBoxContainer/MainContent/TabContainer/Reports/ScrollContainer/StatsContainer/KeyMetrics/SatisfactionCard/VBox/Amount
@onready var sales_list = $ContentContainer/VBoxContainer/MainContent/TabContainer/Reports/ScrollContainer/StatsContainer/TeaSales/VBox/SalesList
@onready var stats_container = $ContentContainer/VBoxContainer/MainContent/TabContainer/Reports/ScrollContainer/StatsContainer
@onready var key_metrics = $ContentContainer/VBoxContainer/MainContent/TabContainer/Reports/ScrollContainer/StatsContainer/KeyMetrics
@onready var tab_container = $ContentContainer/VBoxContainer/MainContent/TabContainer

func _ready() -> void:
	print("GameHUD: _ready called")
	
	# Debug node references
	print("GameHUD: Checking node references:")
	if revenue_amount: print("Revenue Amount node found")
	if customers_amount: print("Customers Amount node found")
	if satisfaction_amount: print("Satisfaction Amount node found")
	if sales_list: print("Sales List node found")
	if stats_container: print("Stats Container node found")
	if key_metrics: print("Key Metrics node found")
	
	# Connect to TeaShop's signals
	var tea_shop = get_parent()
	if tea_shop:
		print("GameHUD: Found parent: ", tea_shop.name)
		if tea_shop.has_signal("day_ended"):
			tea_shop.day_ended.connect(_on_day_ended)
			print("GameHUD: Connected to TeaShop day_ended signal")
	Events.day_ended.connect(_on_day_ended)
	print("GameHUD: Connected to Events.day_ended signal")
	
	# Initialize layout
	_setup_layout()
	_clear_report()

func _setup_layout() -> void:
	# Make sure the Reports tab is present
	if tab_container:
		var tabs = tab_container.get_children()
		print("GameHUD: Found ", tabs.size(), " tabs")
		for i in range(tabs.size()):
			print("Tab ", i, ": ", tabs[i].name)
	
	# Setup ScrollContainer
	var scroll = $ContentContainer/VBoxContainer/MainContent/TabContainer/Reports/ScrollContainer
	if scroll:
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Setup containers
	if stats_container:
		stats_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats_container.add_theme_constant_override("separation", 16)
	
	# Setup Key Metrics grid
	if key_metrics:
		key_metrics.columns = 3
		key_metrics.add_theme_constant_override("h_separation", 16)
		key_metrics.add_theme_constant_override("v_separation", 16)
		key_metrics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Setup metric cards
		for card in key_metrics.get_children():
			if card is PanelContainer:
				card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var vbox = card.get_node("VBox")
				if vbox:
					vbox.add_theme_constant_override("separation", 8)
					for child in vbox.get_children():
						if child is Label:
							child.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _clear_report() -> void:
	print("GameHUD: Clearing report")
	if revenue_amount:
		revenue_amount.text = "£0.00"
	if customers_amount:
		customers_amount.text = "0"
	if satisfaction_amount:
		satisfaction_amount.text = "0%"
	if sales_list:
		for child in sales_list.get_children():
			child.queue_free()

func _on_day_ended(_day: int, stats: Dictionary) -> void:
	print("GameHUD: _on_day_ended called with stats: ", stats)
	
	# Make Reports tab visible
	if tab_container:
		var reports_index = tab_container.get_tab_idx_from_control(report_tab)
		if reports_index >= 0:
			tab_container.current_tab = reports_index
			print("GameHUD: Switched to Reports tab")
	
	# Update stats
	_update_stats(stats)

func _update_stats(stats: Dictionary) -> void:
	print("GameHUD: Updating stats displays")
	
	if revenue_amount:
		revenue_amount.text = "£%.2f" % stats.revenue
		print("Updated revenue: ", revenue_amount.text)
	
	if customers_amount:
		customers_amount.text = str(stats.customers_served)
		print("Updated customers: ", customers_amount.text)
	
	if satisfaction_amount:
		var satisfaction_text = "%.1f%%" % stats.satisfaction
		satisfaction_amount.text = satisfaction_text
		print("Updated satisfaction: ", satisfaction_amount.text)
	
	if sales_list:
		# Clear existing entries
		for child in sales_list.get_children():
			child.queue_free()
		
		# Add new entries
		for tea_name in stats.tea_sold:
			var hbox = HBoxContainer.new()
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var name_label = Label.new()
			name_label.text = tea_name
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var amount_label = Label.new()
			amount_label.text = str(stats.tea_sold[tea_name])
			amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			
			hbox.add_child(name_label)
			hbox.add_child(amount_label)
			sales_list.add_child(hbox)
			print("Added sales entry: ", tea_name, " - ", stats.tea_sold[tea_name])
		
		# Add profit row
		var profit_hbox = HBoxContainer.new()
		profit_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var profit_label = Label.new()
		profit_label.text = "Total Profit"
		profit_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var profit_amount = Label.new()
		profit_amount.text = "£%.2f" % stats.profit
		profit_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		
		profit_hbox.add_child(profit_label)
		profit_hbox.add_child(profit_amount)
		sales_list.add_child(profit_hbox)
		print("Added profit row: £", stats.profit)

func _create_metric_card(title: String, value: String, color: Color) -> void:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	
	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var value_label = Label.new()
	value_label.text = value
	value_label.add_theme_color_override("font_color", color)
	value_label.add_theme_font_size_override("font_size", 24)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	vbox.add_child(title_label)
	vbox.add_child(value_label)
	card.add_child(vbox)
	
	key_metrics.add_child(card)

func _create_sales_panel(sales_data: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	
	var title = Label.new()
	title.text = "Tea Sales"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	for tea_name in sales_data:
		var hbox = HBoxContainer.new()
		
		var name_label = Label.new()
		name_label.text = tea_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var amount_label = Label.new()
		amount_label.text = str(sales_data[tea_name])
		amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		
		hbox.add_child(name_label)
		hbox.add_child(amount_label)
		vbox.add_child(hbox)
	
	panel.add_child(vbox)
	return panel

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Clean up any remaining connections
		var tea_shop = get_parent()
		if tea_shop and tea_shop.has_signal("day_ended"):
			if tea_shop.is_connected("day_ended", _on_day_ended):
				tea_shop.disconnect("day_ended", _on_day_ended)
