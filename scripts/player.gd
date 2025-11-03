extends CharacterBody2D


const SPEED = 120.0
const ACCEL = 1200.0
const DECEL = 1600.0


const JUMP_VELOCITY = -300.0
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var jump_count = 0
const MAX_JUMPS = 1

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS:
		velocity.y = JUMP_VELOCITY
		jump_count += 1
	
	if is_on_floor():
		jump_count = 0

	# ---- HORIZONTAL MOVEMENT WITH ACCEL ----
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := direction * SPEED
	
	# change the direction the player is facing
	if direction > 0: # facing to the right
		animated_sprite_2d.flip_h = false
	elif direction < 0: # facing to the left
		animated_sprite_2d.flip_h = true
		
		
	# pick acces vs decel
	var accel = ACCEL if direction != 0.0 else DECEL
		
	# approach target speed
	velocity.x = move_toward(velocity.x, target_speed, accel * delta)
		
	print("vx =", velocity.x)
		
	move_and_slide()
