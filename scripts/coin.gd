extends Area2D

@export var ItemGet := "none"

func _on_body_entered(body: Node2D) -> void:
	print("+1 coin.")
	if body.is_in_group("player"):
		if SoundController:
			SoundController.play_coin()
		match ItemGet:
			"DoubleJump":
				SoundController.play_powerup()
				body.has_double_jump = true
			"WallJump":
				SoundController.play_powerup()
				body.has_wall_jump = true
		queue_free()
