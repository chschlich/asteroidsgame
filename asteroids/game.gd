extends Node2D

@onready var lasers = $Lasers
@onready var player = $Player
@onready var asteroids = $Asteroids
@onready var hud = $UI/HUD
@onready var game_over_screen = $UI/GameOverScreen
@onready var player_spawn_pos = $PlayerSpawnPos
@onready var player_spawn_area = $PlayerSpawnPos/PlayerSpawnArea

var asteroid_scene = preload("res://asteroid.tscn")
var explosion_scene = preload("res://explosioneffect.tscn")
var score := 0
var lives = 3

func _ready():
	Playerinfo.player = player
	game_over_screen.hide()
	hud.init_lives(lives)
	player.connect("laser_shot", _on_player_laser_shot)
	player.connect("died", Callable(self, "_on_player_died"))
	for asteroid in asteroids.get_children():
		asteroid.connect("exploded", Callable(self, "_on_asteroid_exploded"))

func _process(delta):
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()

func _on_player_laser_shot(laser):
	lasers.add_child(laser)

func _on_asteroid_exploded(pos, size, points):
	score += points
	hud.score = score
	if size != AsteroidInstance.AsteroidSize.SMALL:
		var new_size = AsteroidInstance.AsteroidSize.MEDIUM if size == AsteroidInstance.AsteroidSize.LARGE else AsteroidInstance.AsteroidSize.SMALL
		spawn_asteroid(pos, new_size)

func spawn_asteroid(pos, size):
	var a = asteroid_scene.instantiate()
	a.global_position = pos
	a.size = size
	a.connect("exploded", _on_asteroid_exploded)
	asteroids.call_deferred("add_child", a)

func _spawn_random_asteroid():
	var screen_size = get_viewport_rect().size
	var pos = Vector2(randf_range(0, screen_size.x), 0)
	spawn_asteroid(pos, AsteroidInstance.AsteroidSize.LARGE)

func _on_player_died():
	lives -= 1
	hud.init_lives(lives)
	player.global_position = player_spawn_pos.global_position
	if lives <= 0:
		await get_tree().create_timer(2).timeout
		game_over_screen.show()
	else:
		await get_tree().create_timer(1).timeout
		while !player_spawn_area.is_empty:
			await get_tree().create_timer(0.1).timeout
		player.respawn(player_spawn_pos.global_position)

func _on_spawn_timer_timeout():
	_spawn_random_asteroid()
