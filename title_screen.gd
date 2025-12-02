extends Node2D

func _ready() -> void:
	SoundController.stop_boss_music()
	SoundController.play_music()

	# 🎮 Give controller focus to the Start button
	$Control/CenterContainer/VBoxContainer/Start.grab_focus()


func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/rooms/room_1.tscn")


func _on_options_pressed() -> void:
	# options coming later
	pass


func _on_quit_pressed() -> void:
	get_tree().quit()
