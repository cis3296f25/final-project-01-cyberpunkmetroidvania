extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SoundController.stop_boss_music()
	SoundController.play_congrats()
	SoundController.play_ending_music()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	get_tree().quit()
