extends Area2D

@export var speed: float = 250.0
var direction: Vector2 = Vector2.RIGHT
var state: String = "starting"

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation.sprite_frames.set_animation_loop("hado end", false) #hado hit plays once
	animation.sprite_frames.set_animation_loop("hado start", false) #hado begin plays once
	body_entered.connect(_on_body_entered)
	animation.play("hado start")
	animation.animation_finished.connect(_on_animation_finished)
	
	
	_update_flip()

func _physics_process(delta: float) -> void:
	if state == "active" or state == "starting":
		position += direction * speed * delta
		
func _update_flip() -> void:
	if direction.x < 0.0:
		animation.flip_h = true
	else:
		animation.flip_h = false

func _on_body_entered(body: Node) -> void:
	state = "hit"
	speed = 0.0
	direction = Vector2.ZERO
	
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(3.0, direction, direction)
	
	
	animation.play("hado end")
	
func _on_animation_finished() -> void:
	if state == "starting":
		state = "active"
		animation.play("hado")
	if state == "hit":
		queue_free()
