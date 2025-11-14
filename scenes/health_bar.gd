extends ProgressBar

signal health_depleted

@export var damage_lag := 0.25       # delay before the red bar starts dropping (seconds)
@export var drop_speed := 160.0      # how fast the red bar drops towards current HP 
@export var auto_hide_on_zero := false

@onready var timer: Timer = $Timer
@onready var damageBar: ProgressBar = $DamageBar

var health := 0 : set = set_health

var _dropping := false   # whether the damageBar is currently animating down

func _ready() -> void:
	if timer:
		timer.one_shot = true
		timer.wait_time = damage_lag
		var cb := Callable(self, "_on_timer_timeout")
		if not timer.timeout.is_connected(cb):
			timer.timeout.connect(cb)

	health = clamp(health, 0, int(max_value))
	value = health
	if is_instance_valid(damageBar):
		damageBar.max_value = max_value
		damageBar.value = health

func _process(delta: float) -> void:
	# Smoothly drop the damage bar towards the current HP once the lag has elapsed
	if _dropping and is_instance_valid(damageBar):
		if damageBar.value > health:
			damageBar.value = max(health, damageBar.value - drop_speed * delta)
		else:
			_dropping = false


func initHealth(_health: int) -> void:
	max_value = max(1, _health)
	health = _health
	value = health
	if is_instance_valid(damageBar):
		damageBar.max_value = max_value
		damageBar.value = health

func updateHealth(current_hp: int) -> void:
	set_health(current_hp)

# --- Setter ---

func set_health(newHealth: int) -> void:
	var previousHealth := health
	health = clamp(newHealth, 0, int(max_value))
	value = health

	# Handle zero HP visuals and signal
	if health <= 0:
		_dropping = false
		if is_instance_valid(damageBar):
			damageBar.value = 0
		if auto_hide_on_zero:
			visible = false
		emit_signal("health_depleted")
	else:
		visible = true

	# Start/stop damage bar behavior
	if not is_instance_valid(damageBar):
		return

	if health < previousHealth:
		# Took damage: wait a bit, then start dropping the red bar
		_dropping = false
		if timer:
			timer.stop()
			timer.start()   # after damage_lag, _on_timer_timeout sets _dropping = true
	else:
		# Healed or unchanged: snap red bar up to current health
		_dropping = false
		damageBar.value = health

# --- Timer callback ---

func _on_timer_timeout() -> void:
	# Begin the smooth drop of the damage bar towards health
	_dropping = true
