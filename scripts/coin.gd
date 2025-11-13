extends Area2D

@export var ItemGet := "none"


func _on_body_entered(body: Node2D) -> void:
	print("+1 coin.")
	if(body.is_in_group("player")):
		match(ItemGet):
			"DoubleJump":
				body.has_double_jump = true
			"WallJump":
				body.has_wall_jump = true
			
	queue_free()
