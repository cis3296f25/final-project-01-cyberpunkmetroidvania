extends CanvasLayer

signal transition_finished   # renamed to be idiomatic

@onready var colorRect = $ColorRect
@onready var animationPlayer = $AnimationPlayer

func _ready():
	colorRect.visible = false
	animationPlayer.animation_finished.connect(_on_animation_finished)

func transition():
	colorRect.visible = true
	animationPlayer.play("fadeToBlack")

func _on_animation_finished(anim):
	if anim == "fadeToBlack":
		transition_finished.emit()   # tells game to switch scenes
	elif anim == "fadeToNormal":
		colorRect.visible = false
	
