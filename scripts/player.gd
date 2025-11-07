extends CharacterBody2D

# --- MOVEMENT CONSTANTS ---
const SPEED = 120.0
const ACCEL = 1100.0
const DECEL = 1600.0
const AIR_ACCEL = 1000.0
const AIR_TURN_ACCEL = 2200.0

# --- GRAVITY / JUMP ---
const JUMP_VELOCITY = -300.0
const GRAVITY_UP := 700.0
const GRAVITY_DOWN := 1300.0
const GRAVITY_CUTOFF := 5000.0

const COYOTE_TIME := 0.05
const JUMP_BUFFER := 0.12

# --- WALL SLIDE ---
const WALL_SLIDE_SPEED = 50.0
const WALL_JUMP_VELOCITY = -300.0
const WALL_JUMP_HORIZONTAL_BOOST = 200.0

# --- DASH (ROLL) SETTINGS ---
const DASH_DISTANCE := 150.0       # how far to move instantly
const DASH_DURATION := 0.15        # how long invincibility lasts
const DASH_COOLDOWN := 0.5         # cooldown before next dash

# --- INTERNAL STATE VARIABLES ---
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var jump_count = 0
const MAX_JUMPS = 2

var attacking := false
var is_wall_sliding := false
var is_dashing := false
var can_dash := true

const HEAVY_DAMAGE = 1.75
const LIGHT_DAMAGE = 1.00

# --- NODE REFERENCES ---
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# --- READY FUNCTION ---
func _ready() -> void:
	add_to_group("player")

	if animated_sprite_2d.sprite_frames:
		animated_sprite_2d.sprite_frames.set_animation_loop("light_punch", false)
		animated_sprite_2d.sprite_frames.set_animation_loop("heavy_punch", false)

	animated_sprite_2d.animation_finished.connect(_on_animation_finished)

	if RoomChangeGlobal.activate:
		global_position = RoomChangeGlobal.playerPosition
		if RoomChangeGlobal.jumpOnEnter:
			velocity.y = JUMP_VELOCITY
		RoomChangeGlobal.activate = false

# --- ATTACK FUNCTIONS ---
func start_light_attack_animation():
	attacking = true
	animated_sprite_2d.play("light_punch")
	animated_sprite_2d.frame = 0

func start_heavy_attack_animation():
	attacking = true
	animated_sprite_2d.play("heavy_punch")
	animated_sprite_2d.frame = 0

func _on_animation_finished() -> void:
	if animated_sprite_2d.animation in ["light_punch", "heavy_punch"]:
		attacking = false
		animated_sprite_2d.play("new_idle")

# --- MAIN PROCESS LOOP ---
func _process(delta: float) -> void:
	# Skip movement updates if currently dashing
	if is_dashing:
		return

	# --- GRAVITY / COYOTE / BUFFER JUMP ---
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

	# --- WALL SLIDING ---
	is_wall_sliding = false
	if is_on_wall() and not is_on_floor():
		is_wall_sliding = true
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
		if animated_sprite_2d.animation != "wall_slide":
			animated_sprite_2d.play("wall_slide")

	# --- JUMPING (NORMAL + WALL JUMP) ---
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
		velocity.y = WALL_JUMP_VELOCITY
		velocity.x = WALL_JUMP_HORIZONTAL_BOOST * -sign(Input.get_axis("move_left", "move_right"))
		animated_sprite_2d.flip_h = velocity.x < 0
		is_wall_sliding = false

	# --- HORIZONTAL MOVEMENT ---
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := direction * SPEED

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

	# --- DASH INPUT ---
	if Input.is_action_just_pressed("roll") and can_dash:
		perform_dash()

	# --- ATTACK INPUT ---
	if not is_wall_sliding:
		if not attacking and Input.is_action_just_pressed("attack"):
			if Input.is_key_pressed(KEY_SHIFT):
				start_heavy_attack_animation()
			else:
				start_light_attack_animation()

	# --- ANIMATION STATE ---
	if attacking:
		if animated_sprite_2d.animation not in ["light_punch", "heavy_punch"]:
			if Input.is_key_pressed(KEY_SHIFT):
				start_heavy_attack_animation()
			else:
				start_light_attack_animation()
	else:
		if is_wall_sliding:
			if animated_sprite_2d.animation != "wall_slide":
				animated_sprite_2d.play("wall_slide")
		else:
			if animated_sprite_2d.animation == "wall_slide":
				animated_sprite_2d.stop()

	if not attacking and not is_wall_sliding and not is_dashing:
		if abs(velocity.x) > 10.0:
			if animated_sprite_2d.animation != "new_walk":
				animated_sprite_2d.play("new_walk")
		else:
			if animated_sprite_2d.animation != "new_idle":
				animated_sprite_2d.play("new_idle")

	move_and_slide()

# --- DASH FUNCTION ---
func perform_dash() -> void:
	is_dashing = true
	can_dash = false
	collision_shape.disabled = true  # Disable hitbox (invincible)

	var dash_dir := -1 if animated_sprite_2d.flip_h else 1
	global_position.x += dash_dir * DASH_DISTANCE  # Instantly move forward

	if "roll" in animated_sprite_2d.sprite_frames.get_animation_names():
		animated_sprite_2d.play("roll")

	await get_tree().create_timer(DASH_DURATION).timeout

	collision_shape.disabled = false
	is_dashing = false

	await get_tree().create_timer(DASH_COOLDOWN).timeout
	can_dash = true
