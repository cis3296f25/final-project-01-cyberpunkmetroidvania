extends Node2D

func _ready() -> void:
	$Control/CenterContainer/VBoxContainer/Button.grab_focus()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		$Control/CenterContainer/VBoxContainer/Button.emit_signal("pressed")

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
