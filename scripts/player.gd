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
const DASH_DISTANCE := 150.0
const DASH_DURATION := 0.15
const DASH_COOLDOWN := 0.5

# --- PHYSICS ---
const PLAYER_MASS := 1.0  

# --- ATTACK ---
var attacking := false
var HEAVY_DAMAGE = 1.75
var LIGHT_DAMAGE = 1.00
var hit_this_swing: Dictionary = {}
const HITBOX_OFFSET := 8.0

# --- INTERNAL STATE ---
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var jump_count = 0
const MAX_JUMPS = 2
var facing := Vector2.RIGHT

var is_wall_sliding := false
var is_dashing := false
var can_dash := true

var max_health = 10
var health = max_health

# --- LANDING SHAKE TRACKING ---
var landing_velocity: float = 0.0
const LANDING_VELOCITY_THRESHOLD: float = 600.0  # minimum velocity to trigger shake

# --- ABILITIES ---
var has_wall_jump := false
var has_double_jump := false

# --- DAMAGE / I-FRAMES ---
var invuln := false
@export var invuln_time := 0.40

# --- NODE REFS ---
@onready var healthbar = $HealthBar
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $HurtBox/CollisionShape2D
@onready var invuln_timer: Timer = $InvulnTimer

# Player HurtBox (Area2D)
@onready var player_hurtbox: Area2D = $HurtBox

# Player ATTACK hitboxes (Areas)
@onready var lp_hitbox: Area2D = $LPHitbox
@onready var lp_hitbox_shape: CollisionShape2D = $LPHitbox/LightPunchHitbox
@onready var hp_hitbox: Area2D = $HPHitbox
@onready var hp_hitbox_shape: CollisionShape2D = $HPHitbox/HeavyPunchHitbox

@onready var dashCooldown: Timer = $dashCooldown
@onready var dashDuration: Timer = $dashDuration

# --- UPGRADE ---
func apply_permanent_upgrade(health_increase: int, damage_increase: int) -> void:
	
	max_health += health_increase
	health = max_health
	LIGHT_DAMAGE+=damage_increase
	HEAVY_DAMAGE+=damage_increase

# --- READY ---
func _ready() -> void:
	add_to_group("player")

	_hitbox_off_all()
	_position_hitboxes_ahead()

	# Connect attack hitboxes (guarded)
	var cb_lp := Callable(self, "_on_light_area_entered")
	if not lp_hitbox.area_entered.is_connected(cb_lp):
		lp_hitbox.area_entered.connect(cb_lp)
	var cb_hp := Callable(self, "_on_heavy_area_entered")
	if not hp_hitbox.area_entered.is_connected(cb_hp):
		hp_hitbox.area_entered.connect(cb_hp)

	# Player HurtBox
	var hb_cb := Callable(self, "_on_hurt_box_body_entered")
	if not player_hurtbox.body_entered.is_connected(hb_cb):
		player_hurtbox.body_entered.connect(hb_cb)

	# Invulnability timer
	if invuln_timer == null:
		invuln_timer = Timer.new()
		invuln_timer.name = "InvulnTimer"
		add_child(invuln_timer)
	invuln_timer.one_shot = true
	var cb := Callable(self, "_on_invuln_timeout")
	if not invuln_timer.timeout.is_connected(cb):
		invuln_timer.timeout.connect(cb)

	healthbar.initHealth(health)

	# Attack animation loop control
	if animated_sprite_2d.sprite_frames:
		animated_sprite_2d.sprite_frames.set_animation_loop("light_punch", false)
		animated_sprite_2d.sprite_frames.set_animation_loop("heavy_punch", false)
	animated_sprite_2d.animation_finished.connect(_on_animation_finished)

	# Room/ability stuff
	if RoomChangeGlobal.activate:
		global_position = RoomChangeGlobal.playerPosition
		if RoomChangeGlobal.jumpOnEnter:
			velocity.y = JUMP_VELOCITY
		RoomChangeGlobal.playerDone = true
	if RoomChangeGlobal.camDone:
		RoomChangeGlobal.activate = false

	has_double_jump = RoomChangeGlobal.has_double_jump
	has_wall_jump = RoomChangeGlobal.has_wall_jump

# --- PHYSICS ---
func _physics_process(delta: float) -> void:
	check_spike_collision()

	# track landing velocity for kinetic energy shake
	if not is_on_floor() and not is_wall_sliding:
		landing_velocity = abs(velocity.y)
	else:
		# just landed - check if should shake based on impact velocity
		if is_on_floor() and landing_velocity >= LANDING_VELOCITY_THRESHOLD:
			# calculate shake strength based on kinetic energy (KE = 0.5 * m * v^2)
			# since mass is constant, we can simplify to just v^2 for comparison
			var kinetic_energy = 0.5 * PLAYER_MASS * landing_velocity * landing_velocity
			var threshold_energy = 0.5 * PLAYER_MASS * LANDING_VELOCITY_THRESHOLD * LANDING_VELOCITY_THRESHOLD
			var kinetic_factor = kinetic_energy / threshold_energy
			var shake_strength = clamp(kinetic_factor * 3.0, 2.0, 8.0)  # scale between 2-8
			trigger_camera_shake(shake_strength, 8.0)
		if is_on_floor():
			landing_velocity = 0.0

	# Gravity / coyote / buffer
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

	# Wall slide
	is_wall_sliding = false
	if is_on_wall() and not is_on_floor() and has_wall_jump:
		is_wall_sliding = true
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
		if animated_sprite_2d.animation != "wall_slide":
			animated_sprite_2d.play("wall_slide")

	# Jumping
	var can_jump := false
	if jump_count == 0:
		can_jump = (is_on_floor() or coyote_timer > 0.0)
	elif has_double_jump:
		can_jump = (jump_count < MAX_JUMPS)
	else:
		can_jump = (jump_count < 1)

	if can_jump and jump_buffer_timer > 0.0:
		SoundController.play_jump()
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

	# Horizontal
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := direction * SPEED

	if direction > 0.0:
		animated_sprite_2d.flip_h = false
		facing = Vector2.RIGHT
		_position_hitboxes_ahead()
	elif direction < 0.0:
		animated_sprite_2d.flip_h = true
		facing = Vector2.LEFT
		_position_hitboxes_ahead()

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

	if is_dashing:
		target_speed *= 4
		accel *= 8

	velocity.x = move_toward(velocity.x, target_speed, accel * delta)

	# Dash input
	if Input.is_action_just_pressed("roll") and can_dash:
		perform_dash()

	if abs(velocity.x) < 5.0:
		velocity.x = 0.0
	if is_dashing:
		velocity.y = 0

	move_and_slide()

# --- ATTACK INPUT / STATE ---
func _process(_dt: float) -> void:
	if not is_wall_sliding and is_on_floor() and not attacking and Input.is_action_just_pressed("attack"):
		if Input.is_key_pressed(KEY_SHIFT):
			start_heavy_attack_animation()
		else:
			start_light_attack_animation()

	# Animation fallbacks
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
		if not is_dashing:
			if abs(velocity.x) > 10.0:
				if animated_sprite_2d.animation != "new_walk":
					animated_sprite_2d.play("new_walk")
			else:
				if animated_sprite_2d.animation != "new_idle":
					animated_sprite_2d.play("new_idle")
		else:
			if animated_sprite_2d.animation != "dash":
				animated_sprite_2d.play("dash")
	elif not is_on_floor() and not is_wall_sliding:
		if not is_dashing:
			if velocity.y > 0:
				if animated_sprite_2d.animation != "fall":
					animated_sprite_2d.play("fall")
			else:
				if animated_sprite_2d.animation != "jump":
					animated_sprite_2d.play("jump")
		else:
			pass

# -- ATTACK FUNCTIONS --
func start_light_attack_animation():
	attacking = true
	hit_this_swing.clear()
	_position_hitboxes_ahead()
	lp_hitbox.monitoring = true
	lp_hitbox.monitorable = true
	hp_hitbox.monitoring = false
	hp_hitbox.monitorable = false
	animated_sprite_2d.play("light_punch")
	animated_sprite_2d.frame = 0

func start_heavy_attack_animation():
	attacking = true
	hit_this_swing.clear()
	_position_hitboxes_ahead()
	hp_hitbox.monitoring = true
	hp_hitbox.monitorable = true
	lp_hitbox.monitoring = false
	lp_hitbox.monitorable = false
	animated_sprite_2d.play("heavy_punch")
	animated_sprite_2d.frame = 0

func _on_animation_finished() -> void:
	if animated_sprite_2d.animation in ["light_punch", "heavy_punch"]:
		attacking = false
		_hitbox_off_all()
		animated_sprite_2d.play("new_idle")

# --- DASH ---
func perform_dash() -> void:
	SoundController.play_dash()
	is_dashing = true
	can_dash = false
	collision_shape.disabled = true
	dashDuration.start()

func _on_dash_duration_timeout() -> void:
	collision_shape.disabled = false
	is_dashing = false
	dashCooldown.start()

func _on_dash_cooldown_timeout() -> void:
	can_dash = true

# --- SPIKES ---
func check_spike_collision() -> void:
	var spike_layer = get_tree().get_first_node_in_group("spikes")
	if spike_layer and spike_layer is TileMapLayer:
		var tile_pos = spike_layer.local_to_map(spike_layer.to_local(global_position))
		var tile_data = spike_layer.get_cell_tile_data(tile_pos)
		if tile_data != null:
			SoundController.play_death()
			print("Player is on a spike tile!")
			await get_tree().create_timer(0.15).timeout
			call_deferred("reload_scene")

# -- PLAYER HURTBOX --
func _on_hurt_box_body_entered(body: Node2D) -> void:
	if invuln:
		return
	if body.is_in_group("enemy"):
		var dir: Vector2 = (global_position - body.global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		var src_pos: Vector2 = body.global_position
		take_damage(1.0, dir, src_pos)
	print("damage taken")
	health -= 1

	if health <= 0:
		call_deferred("reload_scene")

# -- Hitbox turnoff --
func _hitbox_off_all() -> void:
	lp_hitbox.monitoring = false
	lp_hitbox.monitorable = false
	hp_hitbox.monitoring = false
	hp_hitbox.monitorable = false

func _position_hitboxes_ahead() -> void:
	var position := Vector2(HITBOX_OFFSET * facing.x, 0)
	hp_hitbox.position = position
	lp_hitbox.position = position

# -- Player hitbox overlaps enemy --
func _on_light_area_entered(area: Area2D) -> void:
	_register_hit(area, LIGHT_DAMAGE, lp_hitbox.global_position)

func _on_heavy_area_entered(area: Area2D) -> void:
	_register_hit(area, HEAVY_DAMAGE, hp_hitbox.global_position)

func _register_hit(area: Area2D, damage: float, src_pos: Vector2) -> void:
	if area in hit_this_swing:
		return
	hit_this_swing[area] = true

	var enemy := area.get_parent()
	if enemy and enemy.is_in_group("enemy") and enemy.has_method("take_damage"):
		enemy.take_damage(damage, facing, src_pos)

# --- PUBLIC: called by ENEMY when its Hitbox hits player HurtBox ---
func take_damage(amount: float, hit_dir: Vector2, source_pos: Vector2) -> void:
	if invuln:
		return
	_take_damage(amount, hit_dir, source_pos)

func _on_invuln_timeout() -> void:
	invuln = false
	animated_sprite_2d.modulate = Color(1,1,1)

func _take_damage(damage: float, hit_dir: Vector2, source_pos: Vector2) -> void:
	invuln = true
	invuln_timer.start(invuln_time)
	SoundController.play_hurt()

	health -= int(ceil(damage))
	if is_instance_valid(healthbar) and healthbar.has_method("updateHealth"):
		healthbar.updateHealth(health)

	# trigger screen shake when taking damage
	trigger_camera_shake(3.0, 8.0)  

	# visual knockback
	animated_sprite_2d.modulate = Color(1, 0.7, 0.7)

	# Build knockback vector
	var kb: Vector2 = hit_dir
	if kb == Vector2.ZERO:
		# Fallback: push away from the source horizontally
		var xsign: int = sign(global_position.x - source_pos.x)
		if xsign == 0:
			xsign = 1
		kb = Vector2(xsign, 0)
	else:
		kb = kb.normalized()

	# Apply knockback
	var H := 220.0
	var V := -80.0
	velocity = Vector2(kb.x * H, V)


# --- MISC ---
func _on_hurtbox_spike_body_entered(body: Node2D) -> void:
	if body.is_in_group("spikes"):
		SoundController.play_death()
		print("Player touched spikes")
		await get_tree().create_timer(0.15).timeout
		call_deferred("reload_scene") 
		
func reload_scene() -> void:
	get_tree().reload_current_scene()

# --- SCREEN SHAKE ---
func trigger_camera_shake(strength: float = 10.0, decay: float = 5.0) -> void: #default parameters for fallbacks
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("apply_shake"):
		camera.apply_shake(strength, decay)
