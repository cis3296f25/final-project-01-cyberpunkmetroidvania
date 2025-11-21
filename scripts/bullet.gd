extends Area2D

@export var speed: float = 500.0
var direction: Vector2 = Vector2.RIGHT
var state: String = "active"

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation.play("bullet")
	animation.animation_finished.connect(_on_animation_finished)
	animation.sprite_frames.set_animation_loop("bullet end", false) #bullet hit plays once
	
	_update_flip()
	
	body_entered.connect(_on_body_entered)
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	if state == "active":
		position += direction * speed * delta
		
func _update_flip() -> void:
	if direction.x < 0.0:
		animation.flip_h = true
	else:
		animation.flip_h = false

func _on_body_entered(body: Node) -> void:
	if state != "active":
		return
	state = "hit"
	speed = 0.0
	direction = Vector2.ZERO
	
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(1.0, direction, direction)
	
	
	animation.play("bullet end")
	
func _on_animation_finished() -> void:
	if state == "hit":
		queue_free()
