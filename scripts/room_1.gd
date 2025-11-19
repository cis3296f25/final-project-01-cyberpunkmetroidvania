extends Node2D

@onready var door1 := $Door
@onready var pause_layer: CanvasLayer = $PauseLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pause_layer.visible = false

# --- ESC MENU ---
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			_resume_game() # esc while paused -> resume
		else:
			_pause_game() # esc while playing -> pause

func _pause_game() -> void:
	get_tree().paused = true
	pause_layer.visible = true

func _resume_game() -> void:
	get_tree().paused = false
	pause_layer.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


#func _on_door_area_entered(area: Area2D) -> void:
	#print("Door entered")
	#if area == door1:
		#get_tree().change_scene_to_file("res://scenes/room_2.tscn")
#
#
#func _on_door_body_entered(body: Node2D) -> void:
	#
	#if body.is_in_group("player"):
		#print("Door entered")
		##get_tree().change_scene_to_file("res://scenes/room_2.tscn")
#
#
#func _on_door_2_body_entered(body: Node2D) -> void:
	#if body.is_in_group("player"):
		#print("Door 2 entered")
		#get_tree().call_deferred("change_scene_to_file", "res://scenes/room_2.tscn")
		


func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	pause_layer.visible = false

func _on_quit_button_pressed() -> void:
	get_tree().quit()
