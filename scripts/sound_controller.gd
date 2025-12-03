extends Node2D

func _ready():
	if not $music.playing:
		$music.play()
		
func play_jump():
	$jump.play()
func play_coin():
	$coin.play()
func play_powerup():
	$power_up.play()
func play_hurt():
	$hurt.play()
func play_death():
	$death.play()
func play_dash():
	$dash.play()
func play_enemy_death():
	$enemy_death.play()
func play_hit_marker():
	$hit_marker.play()
func play_punch():
	$punch.play()
func play_heavy_punch():
	$heavy_punch.play()
func play_shoot():
	$shoot.play()
func play_heavy_shoot():
	$heavy_shoot.play()

func play_music():
	if not $music.playing:
		$music.play()
func stop_music():
	$music.stop()
func play_boss_music():
	if not $boss_music.playing:
		$boss_music.play()
func stop_boss_music():
	$boss_music.stop()
