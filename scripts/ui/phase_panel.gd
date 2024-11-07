# res://scripts/ui/phase_panel.gd
extends PanelContainer

@onready var day_number = $MarginContainer/HBoxContainer/DayInfo/DayNumber
@onready var phase_name = $MarginContainer/HBoxContainer/PhaseInfo/PhaseName
@onready var time_left = $MarginContainer/HBoxContainer/TimeInfo/TimeLeft
@onready var progress_bar = $MarginContainer/HBoxContainer/TimeInfo/ProgressBar

var current_phase = "Morning Preparation"
var phase_time = 180.0  # 3 minutes per phase
var time_elapsed = 0.0

func _ready():
	update_display()

func set_day(number: int):
	day_number.text = str(number)

func set_phase(phase: String):
	current_phase = phase
	phase_name.text = phase
	time_elapsed = 0.0
	progress_bar.value = 0

func _process(delta):
	if current_phase != "Evening Review":  # Don't count time during review
		time_elapsed = min(time_elapsed + delta, phase_time)
		var time_remaining = phase_time - time_elapsed
		time_left.text = "%d:%02d" % [time_remaining / 60, int(time_remaining) % 60]
		progress_bar.value = (time_elapsed / phase_time) * 100

func update_display():
	phase_name.text = current_phase
	progress_bar.value = (time_elapsed / phase_time) * 100
