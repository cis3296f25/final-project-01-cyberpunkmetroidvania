extends Node2D

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	# Controller A button OR Enter/Return key
	if Input.is_action_just_pressed("ui_accept"):
		_on_button_pressed()

func _on_button_pressed() -> void:
	FadeTransition.transition()
	FadeTransition.animationPlayer.play("fadeToNormal")
	get_tree().change_scene_to_file("res://scenes/rooms/room_1.tscn")
