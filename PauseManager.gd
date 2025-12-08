extends CanvasLayer

@onready var resume_button: Button = $CenterContainer/Panel/VBoxContainer/ResumeButton
@onready var quit_button: Button = $CenterContainer/Panel/VBoxContainer/QuitButton

func _ready() -> void:
	# Start hidden
	visible = false

	# Make sure this node always processes, even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Connect button signals in code (no editor setup needed)
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			_resume_game()
		else:
			_pause_game()

func _pause_game() -> void:
	get_tree().paused = true
	visible = true

func _resume_game() -> void:
	get_tree().paused = false
	visible = false

func _on_resume_pressed() -> void:
	_resume_game()

func _on_quit_pressed() -> void:
	get_tree().quit()
