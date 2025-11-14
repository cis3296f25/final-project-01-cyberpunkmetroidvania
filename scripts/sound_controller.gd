extends Node2D

func _ready():
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

func play_music():
	$music.play()

func stop_music():
	$music.stop()
