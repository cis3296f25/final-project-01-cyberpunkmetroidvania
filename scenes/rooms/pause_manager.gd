extends CanvasLayer

@onready var resume_button: Button = $CenterContainer/Panel/VBoxContainer/ResumeButton
@onready var quit_button: Button = $CenterContainer/Panel/VBoxContainer/QuitButton

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	#connect buttons
	resume_button.pressed.connect(_resume_game)
	quit_button.pressed.connect(_quit_game)

func _pause_game() -> void:
	get_tree().paused = true
	visible = true

func _resume_game() -> void:
	get_tree().paused = false
	visible = false

func _quit_game() -> void:
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			_resume_game()
		else:
			_pause_game()

#func _on_ResumeButton_pressed() -> void:
	#_resume_game()
#
#func _on_QuitButton_pressed() -> void:
	#get_tree().quit()
