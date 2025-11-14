extends CharacterBody2D

# -- Variables --
@export var max_hp: int = 2
@export var contact_damage: int = 1
@export var invuln_time: float = 0.20
@export var contact_tick: float = 0.40

# -- Nodes --
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $"Hitbox/CollisionShape2D"
@onready var hurtbox: Area2D = $Hurtbox
@onready var hurtbox_shape: CollisionShape2D = $"Hurtbox/CollisionShape2D"
@onready var invuln_timer: Timer = $InvulnTimer
@onready var dmg_tick: Timer = $DamageTick


# -- State --
var hp := 0
var invuln := false
var _overlapping_player_hurtboxes: Dictionary = {}

func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp

	if invuln_timer == null:
		invuln_timer = Timer.new()
		invuln_timer.name = "InvulnTimer"
		add_child(invuln_timer)
	invuln_timer.one_shot = true
	var cb_inv := Callable(self, "_on_invuln_timeout")
	if not invuln_timer.timeout.is_connected(cb_inv):
		invuln_timer.timeout.connect(cb_inv)

	if dmg_tick == null:
		dmg_tick = Timer.new()
		dmg_tick.name = "DamageTick"
		add_child(dmg_tick)
	dmg_tick.one_shot = false
	dmg_tick.wait_time = contact_tick
	var cb_tick := Callable(self, "_on_damage_tick")
	if not dmg_tick.timeout.is_connected(cb_tick):
		dmg_tick.timeout.connect(cb_tick)

	hitbox.monitoring  = true
	hitbox.monitorable = true

	hurtbox.monitoring  = true
	hurtbox.monitorable = true

	# Connect Hitbox signals once
	var cb_enter := Callable(self, "_on_hitbox_area_entered")
	if not hitbox.area_entered.is_connected(cb_enter):
		hitbox.area_entered.connect(cb_enter)
	var cb_exit := Callable(self, "_on_hitbox_area_exited")
	if not hitbox.area_exited.is_connected(cb_exit):
		hitbox.area_exited.connect(cb_exit)

func _physics_process(_dt: float) -> void:
	move_and_slide()

# -- Get hit by player --
func take_damage(amount: float, _hit_dir: Vector2, _source_pos: Vector2) -> void:
	if invuln:
		return
	invuln = true
	invuln_timer.start(invuln_time)

	hp -= int(ceil(amount))
	if sprite:
		sprite.modulate = Color(1, 0.6, 0.6)
	if hp <= 0:
		_die()
	
func _die() -> void:
	# stop damage ticks and i-frames
	if is_instance_valid(dmg_tick):
		dmg_tick.stop()
	if is_instance_valid(invuln_timer):
		invuln_timer.stop()

	# disable hitboxes
	if is_instance_valid(hitbox):
		hitbox.monitoring = false
		hitbox.monitorable = false
	if is_instance_valid(hurtbox):
		hurtbox.monitoring = false
		hurtbox.monitorable = false
	if is_instance_valid(body_shape):
		body_shape.disabled = true
	queue_free()

func _on_invuln_timeout() -> void:
	invuln = false
	if sprite:
		sprite.modulate = Color(1, 1, 1)

# -- Deal contact damage to player --
func _on_hitbox_area_entered(area: Area2D) -> void:
	_overlapping_player_hurtboxes[area] = true
	print("ENEMY hitbox entered by:", area.name, " parent:", area.get_parent().name)
	if dmg_tick.is_stopped():
		dmg_tick.start()

func _on_hitbox_area_exited(area: Area2D) -> void:
	if area in _overlapping_player_hurtboxes:
		_overlapping_player_hurtboxes.erase(area)
	if _overlapping_player_hurtboxes.size() == 0 and not dmg_tick.is_stopped():
		dmg_tick.stop()

func _on_damage_tick() -> void:
	# print("DamageTick: overlapping =", _overlapping_player_hurtboxes.size()) for debugging
	for area in _overlapping_player_hurtboxes.keys():
		if not is_instance_valid(area):
			continue
		var player: Node = area.get_parent()
		if player and player.has_method("take_damage"):
			var dir: Vector2 = (player.global_position - global_position).normalized()
			if dir == Vector2.ZERO:
				dir = Vector2.RIGHT
			var src_pos: Vector2 = global_position
			if hitbox != null:
				src_pos = hitbox.global_position
			#print("Enemy deals", contact_damage, "to", player.name)
			Callable(player, "take_damage").call(contact_damage, dir, src_pos)
