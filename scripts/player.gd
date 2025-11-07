extends CharacterBody2D

const SPEED = 120.0
const ACCEL = 1100.0
const DECEL = 1600.0
const AIR_ACCEL = 1000.0
const AIR_TURN_ACCEL = 2200.0

const JUMP_VELOCITY = -300.0
const GRAVITY_UP := 700.0
const GRAVITY_DOWN := 1300.0
const GRAVITY_CUTOFF := 5000.0

const COYOTE_TIME := 0.05
const JUMP_BUFFER := 0.12

#constants for wall sliding
const WALL_SLIDE_SPEED = 50.0  #speed at which the player slides down the wall
const WALL_JUMP_VELOCITY = -300.0  #vertical velocity for wall jump
const WALL_JUMP_HORIZONTAL_BOOST = 200.0  #horizontal boost for wall jump

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

const HEAVY_DAMAGE = 1.75
const LIGHT_DAMAGE = 1.00
var is_wall_sliding = false

@onready var healthbar = $HealthBar
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var jump_count = 0
const MAX_JUMPS = 2

var attacking := false

func _ready() -> void:
	
	
	add_to_group("player")
	
	var health = 10
	healthbar.initHealth(health)

	# Ensure attack clips don't loop
	if animated_sprite_2d.sprite_frames:
		animated_sprite_2d.sprite_frames.set_animation_loop("light_punch", false)
		animated_sprite_2d.sprite_frames.set_animation_loop("heavy_punch", false)

	# Check for when any animation is finished, used for attacks
	animated_sprite_2d.animation_finished.connect(_on_animation_finished)

	if RoomChangeGlobal.activate:
		global_position = RoomChangeGlobal.playerPosition
		if RoomChangeGlobal.jumpOnEnter:
			velocity.y = JUMP_VELOCITY
		RoomChangeGlobal.activate = false

func start_light_attack_animation():
	attacking = true
	animated_sprite_2d.play("light_punch")
	animated_sprite_2d.frame = 0

func start_heavy_attack_animation():
	attacking = true
	animated_sprite_2d.play("heavy_punch")
	animated_sprite_2d.frame = 0

func _on_animation_finished() -> void:
	# Only unlock if the finished animation was one of the attacks
	if animated_sprite_2d.animation == "light_punch" or animated_sprite_2d.animation == "heavy_punch":
		attacking = false
		# optional: force idle at end of attack
		animated_sprite_2d.play("new_idle")

func _process(delta: float) -> void:
	# ---------------- GRAVITY / JUMPS ----------------
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		jump_count = 0
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

	if jump_buffer_timer > 0.0:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER

	var gravity_to_use := (GRAVITY_UP if velocity.y < 0.0 else GRAVITY_DOWN)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		gravity_to_use = GRAVITY_CUTOFF
	if not is_on_floor():
		velocity.y += gravity_to_use * delta
	
	
		# ----WALL SLIDING----
	is_wall_sliding = false
	if is_on_wall() and not is_on_floor():
		is_wall_sliding = true
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)  # Limit downward speed
		if animated_sprite_2d.animation != "wall_slide":
			animated_sprite_2d.play("wall_slide")

		# ----HANDLE JUMP (INCLUDING WALL JUMP)-----
	var can_jump := false
	if jump_count == 0:
		can_jump = (is_on_floor() or coyote_timer > 0.0)
	else:
		can_jump = (jump_count < MAX_JUMPS)

	if can_jump and jump_buffer_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_count += 1
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
	elif is_wall_sliding and Input.is_action_just_pressed("jump"):
		# Wall jump logic
		velocity.y = WALL_JUMP_VELOCITY
		velocity.x = WALL_JUMP_HORIZONTAL_BOOST * -sign(Input.get_axis("move_left", "move_right"))  # Jump in the direction of input
		animated_sprite_2d.flip_h = velocity.x < 0  # Flip sprite based on jump direction
		is_wall_sliding = false

	# ----HORIZONTAL MOVEMENT----
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := direction * SPEED

	# flip sprite
	if direction > 0.0:
		animated_sprite_2d.flip_h = false
	elif direction < 0.0:
		animated_sprite_2d.flip_h = true

	var accel: float
	if is_on_floor():
		accel = (ACCEL if direction != 0.0 else DECEL)
	else:
		if direction == 0.0:
			accel = DECEL
		else:
			var vel_sign: int = sign(velocity.x)
			var dir_sign: int = sign(direction)
			accel = (AIR_TURN_ACCEL if vel_sign != 0 and dir_sign != 0 and vel_sign != dir_sign else AIR_ACCEL)

	velocity.x = move_toward(velocity.x, target_speed, accel * delta)
	if abs(velocity.x) < 5.0:
		velocity.x = 0.0

	# ---------------- ATTACK STATE ----------------
	# Prevent attacks from being queued while wall sliding
	if not is_wall_sliding:
		# Only start an attack if we're not already attacking.
		if not attacking and Input.is_action_just_pressed("attack"):
			if Input.is_key_pressed(KEY_SHIFT):
				start_heavy_attack_animation()
			else:
				start_light_attack_animation()

	# ---------------- ANIMATION STATE ----------------
	# Ensure attacking state takes precedence over wall sliding
	if attacking:
		# While attacking, don't overwrite the attack animation with wall_slide
		if animated_sprite_2d.animation not in ["light_punch", "heavy_punch"]:
			if Input.is_key_pressed(KEY_SHIFT):
				start_heavy_attack_animation()
			else:
				start_light_attack_animation()
	else:
		# Handle wall sliding animations
		if is_wall_sliding:
			if animated_sprite_2d.animation != "wall_slide":
				animated_sprite_2d.play("wall_slide")
		else:
			# Ensure wall_slide animation is stopped when not sliding
			if animated_sprite_2d.animation == "wall_slide":
				animated_sprite_2d.stop()

	# Ensure walking animation plays correctly when not attacking or wall sliding
	if not attacking and not is_wall_sliding:
		if abs(velocity.x) > 10.0:
			if animated_sprite_2d.animation != "new_walk":
				animated_sprite_2d.play("new_walk")
		else:
			if animated_sprite_2d.animation != "new_idle":
				animated_sprite_2d.play("new_idle")

	move_and_slide()
	
