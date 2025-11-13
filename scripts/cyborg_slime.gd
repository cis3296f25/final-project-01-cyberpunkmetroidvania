extends CharacterBody2D

# if hes invincible why can i see him
# i made a steak mark
@export var max_hp := 1.5
@export var inv_time := 0.2 # invincibility frames
@export var knockback_speed := 80.0
@export var knockup_speed := 50.0

var hp := 0
var invul := false # can set enemy to be invulnerable
var knockback_vec := Vector2.ZERO # knockback vector for enemy
var knockback_t := 0.0

@onready var hurtbox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("enemy")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
