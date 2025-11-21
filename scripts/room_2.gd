extends Node2D

func _ready() -> void:
	SoundController.stop_boss_music()
	SoundController.play_music()
