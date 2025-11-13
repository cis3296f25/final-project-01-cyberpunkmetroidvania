extends Node2D

@export var nextRoom: String
@export var playerPosition: Vector2
@export var jumpOnEnter: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
	
	

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("player entered")
		RoomChangeGlobal.activate = true
		RoomChangeGlobal.camDone = false
		RoomChangeGlobal.playerDone = false
		RoomChangeGlobal.playerPosition = playerPosition
		RoomChangeGlobal.jumpOnEnter = jumpOnEnter
		RoomChangeGlobal.has_double_jump = body.has_double_jump
		RoomChangeGlobal.has_wall_jump = body.has_wall_jump
		get_tree().call_deferred("change_scene_to_file", nextRoom)
