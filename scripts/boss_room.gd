extends Node2D

func _ready():
	SoundController.stop_music()
	SoundController.play_boss_music()
