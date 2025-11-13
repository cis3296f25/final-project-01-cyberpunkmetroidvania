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
# test

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

var health = 10

# --- ABILITY CHECKS ---
var has_wall_jump := false
var has_double_jump := false

# --- NODE REFERENCES ---
@onready var healthbar = $HealthBar
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $HurtBox/CollisionShape2D

@onready var dashCooldown: Timer = $dashCooldown
@onready var dashDuration: Timer = $dashDuration

# --- READY FUNCTION ---
func _ready() -> void:
	
	
	add_to_group("player")
	
	
	healthbar.initHealth(health)

	if animated_sprite_2d.sprite_frames:
		animated_sprite_2d.sprite_frames.set_animation_loop("light_punch", false)
		animated_sprite_2d.sprite_frames.set_animation_loop("heavy_punch", false)

	animated_sprite_2d.animation_finished.connect(_on_animation_finished)

	if RoomChangeGlobal.activate:
		global_position = RoomChangeGlobal.playerPosition
		if RoomChangeGlobal.jumpOnEnter:
			velocity.y = JUMP_VELOCITY
		RoomChangeGlobal.playerDone = true
	
	if RoomChangeGlobal.camDone:
		RoomChangeGlobal.activate = false
		
	has_double_jump = RoomChangeGlobal.has_double_jump
	has_wall_jump = RoomChangeGlobal.has_wall_jump

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
func _physics_process(delta: float) -> void:
	# Skip movement updates if currently dashing
	#if is_dashing:
		#return

	# --- CHECK FOR SPIKE COLLISION ---
	check_spike_collision()

	# --- GRAVITY / COYOTE / BUFFER JUMP ---
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		jump_count = 0
	else:
		if coyote_timer > 0.0:
			jump_count = 1
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
	if is_on_wall() and not is_on_floor() and has_wall_jump:
		is_wall_sliding = true
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
		if animated_sprite_2d.animation != "wall_slide":
			animated_sprite_2d.play("wall_slide")

	# --- JUMPING (NORMAL + WALL JUMP) ---
	var can_jump := false
	if jump_count == 0:
		can_jump = (is_on_floor() or coyote_timer > 0.0)
	elif has_double_jump:
		can_jump = (jump_count < MAX_JUMPS) #MAX_JUMPS
	else:
		can_jump = (jump_count < 1)

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
		jump_count = 1  
		jump_buffer_timer = 0.0  

	# --- HORIZONTAL MOVEMENT ---
	var direction := Input.get_axis("move_left", "move_right")
	
	#var dash_speed := SPEED
	#if is_dashing:
		#dash_speed += 100
	
	var target_speed := direction * SPEED

	if direction > 0.0:
		animated_sprite_2d.flip_h = false
	elif direction < 0.0:
		animated_sprite_2d.flip_h = true

	var accel: float
	if is_on_floor():
		accel = (ACCEL if direction != 0.0 else DECEL)
		#if(is_dashing):
			#accel *= 2
	else:
		if direction == 0.0:
			accel = DECEL
		else:
			var vel_sign: int = sign(velocity.x)
			var dir_sign: int = sign(direction)
			accel = (AIR_TURN_ACCEL if vel_sign != 0 and dir_sign != 0 and vel_sign != dir_sign else AIR_ACCEL)
			#if(is_dashing):
				#accel *= 2
	
	if(is_dashing):
		print("dashing - from _process")
		target_speed *= 4
		accel *= 8
	

	velocity.x = move_toward(velocity.x, target_speed, accel * delta)
	
	# --- DASH INPUT ---
	if Input.is_action_just_pressed("roll") and can_dash:
		print("dashing")
		perform_dash()
	
	
	if abs(velocity.x) < 5.0:
		velocity.x = 0.0
	
	if is_dashing:
		velocity.y = 0

	
	
	
func _process(_delta: float) -> void:
	if not is_wall_sliding and is_on_floor() and not attacking and Input.is_action_just_pressed("attack"):
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
	
	if is_on_floor() and not attacking and not is_wall_sliding:
		if(not is_dashing):
			if abs(velocity.x) > 10.0:
				if animated_sprite_2d.animation != "new_walk":
					animated_sprite_2d.play("new_walk")
			else:
				if animated_sprite_2d.animation != "new_idle":
					animated_sprite_2d.play("new_idle")
		elif is_dashing:
			if animated_sprite_2d.animation != "dash":
				animated_sprite_2d.play("dash")
	
	if not is_on_floor() and not is_wall_sliding:
		if not is_dashing:
			if velocity.y > 0:
				if animated_sprite_2d.animation != "fall":
					animated_sprite_2d.play("fall")
			else:
				if animated_sprite_2d.animation != "jump":
					animated_sprite_2d.play("jump")
		else:
			if animated_sprite_2d.animation != "dive":
				pass #animate a dive
				
	
	
	move_and_slide()

# --- DASH FUNCTION ---
func perform_dash() -> void:
	is_dashing = true
	can_dash = false
	collision_shape.disabled = true  # Disable hitbox (invincible)
	dashDuration.start()
	print("timer started")

func _on_dash_duration_timeout() -> void:
	collision_shape.disabled = false
	is_dashing = false
	dashCooldown.start() 
	

func _on_dash_cooldown_timeout() -> void:
	can_dash = true


# --- SPIKE COLLISION CHECK ---
func check_spike_collision() -> void:
	# Get the spike tilemap layer from the scene
	var spike_layer = get_tree().get_first_node_in_group("spikes")
	if spike_layer and spike_layer is TileMapLayer:
		# Convert player position to tile coordinates
		var tile_pos = spike_layer.local_to_map(spike_layer.to_local(global_position))
		# Check if there's a tile at the player's position
		var tile_data = spike_layer.get_cell_tile_data(tile_pos)
		if tile_data != null:
			print("Player is on a spike tile!")
			call_deferred("reload_scene")


func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		print("damage taken")
		health -= 1


func _on_hurtbox_spike_body_entered(body: Node2D) -> void:
	if body.is_in_group("spikes"):
		print("Player touched spikes")
		call_deferred("reload_scene") 
		
func reload_scene() -> void:
	get_tree().reload_current_scene()
