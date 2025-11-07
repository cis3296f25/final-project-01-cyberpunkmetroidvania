extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#if RoomChangeGlobal.activate:
		#global_position = RoomChangeGlobal.playerPosition
		#limit_left = RoomChangeGlobal.limit_left
		#limit_top = RoomChangeGlobal.limit_top
		#limit_right = RoomChangeGlobal.limit_right
		#limit_bottom = RoomChangeGlobal.limit_bottom
		#RoomChangeGlobal.camDone = true
		#
	#if RoomChangeGlobal.playerDone:
		#RoomChangeGlobal.activate = false
		
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not limit_smoothed:
		limit_smoothed = true
	if not position_smoothing_enabled:
		position_smoothing_enabled = true
