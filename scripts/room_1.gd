extends Node2D

@onready var door1 := $Door


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SoundController.stop_boss_music()
	SoundController.play_music()

	pass # Replace with function body.


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
		


func _on_area_2d_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
