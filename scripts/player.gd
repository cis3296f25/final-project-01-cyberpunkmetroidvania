extends CharacterBody2D

const SPEED = 160.0
const JUMP_VELOCITY = -300.0
const ROLL_SPEED = 100.0
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var jump_count = 0
const MAX_JUMPS = 1
var is_rolling = false
var roll_duration = 0.4 
var roll_timer = 0.0

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle roll input
	if not is_rolling and Input.is_action_just_pressed("roll"):
		start_roll()

	# Update rolling
	if is_rolling:
		update_roll(delta)
		move_and_slide()
		return

	# Handle jump
	if Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS:
		velocity.y = JUMP_VELOCITY
		jump_count += 1

	if is_on_floor():
		jump_count = 0

	# Movement
	var direction := Input.get_axis("move_left", "move_right")

	if direction > 0:# facing to the right
		animated_sprite_2d.flip_h = false 
	elif direction < 0:# facing to the left
		animated_sprite_2d.flip_h = true

	if direction:
		velocity.x = direction * SPEED
		animated_sprite_2d.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		animated_sprite_2d.play("idle")

	move_and_slide()


func start_roll():
	is_rolling = true
	roll_timer = roll_duration
	animated_sprite_2d.play("roll")

	# Move in the facing direction
	if animated_sprite_2d.flip_h:
		velocity.x = -ROLL_SPEED
	else:
		velocity.x = ROLL_SPEED


func update_roll(delta: float):
	roll_timer -= delta
	if roll_timer <= 0:
		is_rolling = false
		animated_sprite_2d.play("idle")
		velocity.x = 0
