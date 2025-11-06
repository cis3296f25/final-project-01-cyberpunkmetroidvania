extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func change_scene_with_data(paff: String):
	var new_scene_path = paff
	var new_scene_packed = load(new_scene_path)
	var new_scene_instance = new_scene_packed.instantiate()

	

	get_tree().root.add_child(new_scene_instance)
	get_tree().current_scene.queue_free() # Remove the old scene
