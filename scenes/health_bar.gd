extends ProgressBar

@onready var timer = $Timer
@onready var damageBar = $DamageBar
#@onready var killZone = $killzone
#var isDead = killZone._on_body_entered()
#stuff still to work on!

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




var health = 0 : set = set_health

func set_health(newHealth):
	var previousHealth = health
	health = min(max_value, newHealth)
	value = health
	
	if health <= 0:
		queue_free()
		
	if health < previousHealth : 
		timer.start()
	else:
		damageBar.value = health
		
		
	

func initHealth(_health):
	max_value = _health
	health = _health
	value = health
	damageBar.max_value = health
	damageBar.value = health
	

func _on_timer_timeout() -> void:
	damageBar.value = health
