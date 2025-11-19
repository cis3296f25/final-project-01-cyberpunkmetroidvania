extends Camera2D

# Screen shake variables
var shake_strength: float = 0.0
var shake_decay: float = 5.0
var shake_amount: float = 0.0

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
	
	# Apply screen shake
	if shake_strength > 0:
		shake_strength = max(shake_strength - shake_decay * delta, 0)
		offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	else:
		offset = Vector2.ZERO

# Call this function to trigger screen shake
func apply_shake(strength: float = 10.0, decay: float = 5.0) -> void:
	shake_strength = strength
	shake_decay = decay
