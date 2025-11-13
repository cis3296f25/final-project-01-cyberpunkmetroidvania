extends Node2D

@onready var WallCoin := $Coin
@onready var DoubleJumpCoin := $Coin2
@onready var player := $Player


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(player.has_wall_jump):
		WallCoin.queue_free()
	if(player.has_double_jump):
		DoubleJumpCoin.queue_free()
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
