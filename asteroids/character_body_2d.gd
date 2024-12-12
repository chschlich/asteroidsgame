extends CharacterBody2D

class_name Player

signal laser_shot(laser)
signal died

@export var acceleration := 10.0
@export var max_speed := 300.0
@export var rotation_speed := 250.0
@export var invulnerability_duration := 2.0 
@export var blink_interval := 0.1  

@onready var muzzle = $Muzzle
@onready var sprite = $Sprite2D
@onready var cshape = $CollisionShape2D
@onready var invulnerability_timer = Timer.new()
@onready var test_animation = $AnimatedSprite2D

var laser_scene = preload("res://laser.tscn")
var shoot_cd = false
var rate_of_fire = 0.15
var lives := 3
var alive := true
var invulnerable := false 

func _ready():
	collision_layer = 1
	collision_mask = 2

func _process(delta):
	if !alive: return
	if Input.is_action_pressed("shoot") and not shoot_cd:
		shoot_cd = true
		shoot_laser()
		await get_tree().create_timer(rate_of_fire).timeout
		shoot_cd = false

func _physics_process(delta):
	if !alive: return
	
	var input_vector := Vector2(0, Input.get_axis("ui_up", "ui_down"))
	velocity += input_vector.rotated(rotation) * acceleration
	velocity = velocity.limit_length(max_speed)

	if alive:
		if Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down"):
			test_animation.play("fly")
		if !Input.is_action_pressed("ui_up") and !Input.is_action_pressed("ui_down"):
			test_animation.stop()

	if Input.is_action_pressed("ui_right"):
		rotate(deg_to_rad(rotation_speed * delta))
	if Input.is_action_pressed("ui_left"):
		rotate(deg_to_rad(-rotation_speed * delta))

	if input_vector.y == 0:
		velocity = velocity.move_toward(Vector2.ZERO, 3)

	move_and_slide()
	_handle_screen_wrap()

func _handle_screen_wrap():
	var screen_size = get_viewport_rect().size
	if global_position.y < 0:
		global_position.y = screen_size.y
	elif global_position.y > screen_size.y:
		global_position.y = 0
	if global_position.x < 0:
		global_position.x = screen_size.x
	elif global_position.x > screen_size.x:
		global_position.x = 0

func shoot_laser():
	$Laser.play()
	var l = laser_scene.instantiate()
	l.global_position = muzzle.global_position
	l.rotation = rotation
	emit_signal("laser_shot", l)

func die():
	if alive:
		test_animation.play("death")
		alive = false
		cshape.set_deferred("disabled", true)
		lives -= 1
		emit_signal("died")
		if lives > 0:
			await get_tree().create_timer(2.0).timeout
			respawn(global_position)
		else:
			game_over()

func respawn(pos):
	if not alive:
		alive = true
		global_position = pos
		velocity = Vector2.ZERO
		cshape.set_deferred("disabled", false)
		_start_invulnerability()

func game_over():
	print("Game Over")
	get_tree().paused = true

func _start_invulnerability():
	invulnerable = true
	cshape.set_deferred("disabled", true)
	await get_tree().create_timer(invulnerability_duration).timeout
	_end_invulnerability()

func _end_invulnerability():
	test_animation.stop()
	invulnerable = false
	cshape.set_deferred("disabled", false)
