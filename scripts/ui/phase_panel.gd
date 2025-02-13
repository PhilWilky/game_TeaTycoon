extends PanelContainer

@onready var day_number = $MarginContainer/HBoxContainer/DayInfo/DayNumber
@onready var phase_name = $MarginContainer/HBoxContainer/PhaseInfo/PhaseName
@onready var time_left = $MarginContainer/HBoxContainer/TimeInfo/TimeLeft
@onready var progress_bar = $MarginContainer/HBoxContainer/TimeInfo/ProgressBar

enum GamePhase {
	MORNING_PREP,
	DAY_OPERATION,
	EVENING_REVIEW
}

var current_phase = GamePhase.MORNING_PREP
var phase_time = 180.0  # 3 minutes per phase
var time_elapsed = 0.0

func _ready():
	Events.day_started.connect(_on_day_started)
	Events.day_ended.connect(_on_day_ended)
	update_display()

func _process(delta):
	if current_phase == GamePhase.DAY_OPERATION:
		time_elapsed = min(time_elapsed + delta, phase_time)
		var time_remaining = phase_time - time_elapsed
		time_left.text = "%d:%02d" % [time_remaining / 60, int(time_remaining) % 60]
		progress_bar.value = (time_elapsed / phase_time) * 100

func set_day(number: int):
	day_number.text = str(number)
	update_display()  # Make sure UI updates when day changes

func set_phase(new_phase: GamePhase):
	current_phase = new_phase
	
	match current_phase:
		GamePhase.MORNING_PREP:
			phase_name.text = "Morning Preparation"
			time_left.text = "--:--"
			progress_bar.value = 0
		GamePhase.DAY_OPERATION:
			phase_name.text = "Open For Business"
			time_elapsed = 0.0
			progress_bar.value = 0
		GamePhase.EVENING_REVIEW:
			phase_name.text = "Evening Review"
			time_left.text = "--:--"
			progress_bar.value = 100
	
	update_display()

func _on_day_started(day: int):
	set_day(day)
	set_phase(GamePhase.DAY_OPERATION)
	time_elapsed = 0.0

func _on_day_ended(_day: int, _stats: Dictionary):
	set_phase(GamePhase.EVENING_REVIEW)

# In phase_panel.gd
func update_display() -> void:
	var phase_text: String
	match current_phase:
		GamePhase.MORNING_PREP:
			phase_text = "Morning Preparation"
		GamePhase.DAY_OPERATION:
			phase_text = "Open For Business"
		GamePhase.EVENING_REVIEW:
			phase_text = "Evening Review"
		_:
			phase_text = "Unknown"
	
	# Simpler display format
	phase_name.text = "Day %s - %s" % [day_number.text, phase_text]
	
	# Update progress bar based on phase
	match current_phase:
		GamePhase.MORNING_PREP:
			time_left.text = "--:--"
			progress_bar.value = 0
		GamePhase.DAY_OPERATION:
			if time_elapsed < phase_time:
				var time_remaining = phase_time - time_elapsed
				time_left.text = "%d:%02d" % [time_remaining / 60, int(time_remaining) % 60]
				progress_bar.value = (time_elapsed / phase_time) * 100
		GamePhase.EVENING_REVIEW:
			time_left.text = "--:--"
			progress_bar.value = 100
