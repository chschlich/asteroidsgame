extends Area2D

class_name AsteroidInstance

signal exploded(pos: Vector2, size: int, points: int)

var movement_vector: Vector2 = Vector2(0, -1)

enum AsteroidSize { LARGE, MEDIUM, SMALL }
@export var size: AsteroidSize

var speed: float = 100.0

var can_merge = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var cshape: CollisionShape2D = $CollisionShape2D
@onready var asteroid_scene: PackedScene = preload("res://asteroid.tscn")
@onready var laser_scene: PackedScene = preload("res://laser.tscn")
@onready var explosion_scene = preload("res://explosioneffect.tscn")

var points: int:
	get:
		match size:
			AsteroidSize.LARGE:
				return 100
			AsteroidSize.MEDIUM:
				return 50
			AsteroidSize.SMALL:
				return 25
			_:
				return 0

func _ready():
	
	
	rotation = randf_range(0, 2 * PI)

	match size:
		AsteroidSize.LARGE:
			speed = randf_range(50, 100)
			sprite.texture = preload("res://big asteroid.png")
			sprite.scale = Vector2(.20, .20)
			cshape.scale = Vector2(1.05, 1.05)
		AsteroidSize.MEDIUM:
			speed = randf_range(100, 150)
			sprite.texture = preload("res://lessasteroid.png")
			sprite.scale = Vector2(.1, .1)
			cshape.scale = Vector2(.55, .55)
		AsteroidSize.SMALL:
			speed = randf_range(100, 200)
			sprite.texture = preload("res://smallerasteroid.png")
			sprite.scale = Vector2(.05, .05)
			cshape.scale = Vector2(.275, .275)

	collision_layer = 2 
	collision_mask = 1 | 2  

	connect("area_entered", Callable(self, "_on_area_entered"))
	connect("body_entered", Callable(self, "body_entered")) 

func _physics_process(delta):
	
	global_position += movement_vector.rotated(rotation) * speed * delta
	
	if self.size == AsteroidSize.LARGE:
		global_rotation = rotate_toward(global_rotation, global_position.angle_to_point(Playerinfo.player.position) + PI/2, PI/5 * delta)

	var radius = cshape.shape.radius
	var screen_size = get_viewport_rect().size
	if (global_position.y + radius) < 0:
		global_position.y = (screen_size.y + radius)
	elif (global_position.y - radius) > screen_size.y:
		global_position.y = -radius
	if (global_position.x + radius) < 0:
		global_position.x = (screen_size.x + radius)
	elif (global_position.x - radius) > screen_size.x:
		global_position.x = -radius

func _on_area_entered(area):
	if area is Laser:
		$Explode.play()
		area.queue_free()  
		explode()  
	elif area is AsteroidInstance:
		if size == area.size and area.size != AsteroidSize.LARGE and not area.is_queued_for_deletion() and can_merge == true:
			merge(area)
		else:
			bounce_off(area)

func body_entered(body):
	if body is Player:
		body.die()
		explode()

func explode():
	if size == AsteroidInstance.AsteroidSize.SMALL:
		var e = explosion_scene.instantiate() as GPUParticles2D
		e.global_position = global_position
		e.emitting = true
		e.scale = Vector2(50, 50)
		get_tree().get_current_scene().add_child(e)
	emit_signal("exploded", global_position, size, points)
	split_asteroid()
	call_deferred("queue_free")
	

func bounce_off(other_asteroid):
	movement_vector = -movement_vector

func merge(other_asteroid):
	var new_size
	if size == AsteroidSize.MEDIUM:
		new_size = AsteroidSize.LARGE
	else:
		new_size = AsteroidSize.MEDIUM

	var new_asteroid = asteroid_scene.instantiate()
	new_asteroid.size = new_size
	new_asteroid.global_position = (global_position + other_asteroid.global_position) / 2
	new_asteroid.connect("exploded", Callable(self, "_on_asteroid_exploded"))

	get_parent().call_deferred("add_child", new_asteroid)

	queue_free()
	other_asteroid.queue_free()

func split_asteroid():
	if size == AsteroidSize.LARGE:
		spawn_smaller_asteroid(AsteroidSize.MEDIUM)
		spawn_smaller_asteroid(AsteroidSize.MEDIUM)
	elif size == AsteroidSize.MEDIUM:
		spawn_smaller_asteroid(AsteroidSize.SMALL)
		spawn_smaller_asteroid(AsteroidSize.SMALL)

func spawn_smaller_asteroid(new_size: AsteroidSize):
	var new_asteroid = asteroid_scene.instantiate()
	new_asteroid.size = new_size
	new_asteroid.global_position = global_position
	new_asteroid.movement_vector = movement_vector.rotated(randf_range(-PI / 4, PI / 4))
	new_asteroid.speed = randf_range(100, 200)
	new_asteroid.connect("exploded", Callable(self, "_on_asteroid_exploded"))
	get_parent().call_deferred("add_child", new_asteroid)


func _on_explode_timer_timeout():
	can_merge = true
