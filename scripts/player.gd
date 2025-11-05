extends CharacterBody2D


const SPEED = 120.0
<<<<<<< Updated upstream
const ACCEL = 1200.0
const DECEL = 1600.0

=======
const ACCEL = 1100.0
const DECEL = 1600.0

const AIR_ACCEL = 1000.0 #normal air accel
const AIR_TURN_ACCEL = 2200.0
>>>>>>> Stashed changes

const JUMP_VELOCITY = -300.0
const GRAVITY_UP := 700.0 #when going up
const GRAVITY_DOWN := 1300.0 #when falling
const GRAVITY_CUTOFF := 5000.0 #extra when you release jump early

const COYOTE_TIME :=0.05 #seconds after leaving ledge that you can still jump
const JUMP_BUFFER :=0.12 #seconds vefore landing a jump can be buffered

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var jump_count = 0
const MAX_JUMPS = 2

func _physics_process(delta: float) -> void:
	#----GRAVITY AND JUMPS----
		#----COYOTE & BUFFER TIMERS----
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		jump_count = 0
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)
		
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)
		
	# store jump presses in a small buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER
	
		# ----APPLY GRAVITY----
	var gravity_to_use := GRAVITY_DOWN
	if velocity.y < 0.0:
		# going up: lighter gravity
		gravity_to_use = GRAVITY_UP
	
	#if player lets go of jump while still going up, apply stronger gravity
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		gravity_to_use = GRAVITY_CUTOFF
	
	#only actually pull down when not grounded
	if not is_on_floor():
		velocity.y += gravity_to_use * delta
	
	
		# ----HANDLE JUMP (USING COYOTE + BUFFER)-----
	var can_jump := false
	
	if jump_count == 0:
		# first jump: must be on floor or in coyote window
		can_jump = (is_on_floor() or coyote_timer > 0.0)
	else:
		# air jumps: just need to have jumps left
		can_jump = (jump_count < MAX_JUMPS)

	if can_jump and jump_buffer_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_count += 1
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
	
	# ----HORIZONTAL MOVEMENT----
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := direction * SPEED
	# flip sprite
	if direction > 0.0:
		animated_sprite_2d.flip_h = false
	elif direction < 0.0:
		animated_sprite_2d.flip_h = true
	
	# --- ACCEL / DECEL LOGIC ---
	var accel: float
	
	if is_on_floor():
<<<<<<< Updated upstream
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
		
=======
		# On the ground: normal accel/decel
		accel = ACCEL if direction != 0.0 else DECEL
	else:
		#in the air
		if direction == 0.0:
			#no input : just decelerate
			accel = DECEL
		else:
			# have input in air - check if reversing direction
			var vel_sign : int = sign(velocity.x)
			var dir_sign : int = sign(direction)
			
			if vel_sign != 0.0 and dir_sign != 0.0 and vel_sign != dir_sign:
				#reversing direction midair --> use huge accel
				accel = AIR_TURN_ACCEL
			else:
				#same direction midair --> softer accel
				accel = AIR_ACCEL
				
	# apply acceleration toward target sped
	velocity.x = move_toward(velocity.x, target_speed, accel * delta)
	
	# tiny velocities get snapped to 0 (prevents jitter in animation state)
	if abs(velocity.x) < 5.0:
		velocity.x = 0.0
	
		# ----ANIMATION LOGIC----
	# if abs(velocity.x) > 10 → walk, else → idle
	if abs(velocity.x) > 10.0:
		if animated_sprite_2d.animation != "new_walk":
			animated_sprite_2d.play("new_walk")
	else:
		if animated_sprite_2d.animation != "new_idle":
			animated_sprite_2d.play("new_idle")

>>>>>>> Stashed changes
	move_and_slide()
