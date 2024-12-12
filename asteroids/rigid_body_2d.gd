class_name Asteroid extends RigidBody2D

signal exploded(pos, size, points)

enum AsteroidSize { LARGE, MEDIUM, SMALL }
@export var size := AsteroidSize.LARGE

@export var base_speed := 100.0

@onready var sprite = $Sprite2D
@onready var cshape = $CollisionShape2D

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
	apply_initial_velocity()

	match size:
		AsteroidSize.LARGE:
			sprite.texture = preload("res://big asteroid.png")
			sprite.scale = Vector2(0.20, 0.20)
		AsteroidSize.MEDIUM:
			sprite.texture = preload("res://lessasteroid.png")
			sprite.scale = Vector2(0.1, 0.1)
		AsteroidSize.SMALL:
			sprite.texture = preload("res://smallerasteroid.png")
			sprite.scale = Vector2(0.05, 0.05)

	connect("body_entered", Callable(self, "_on_body_entered"))

func apply_initial_velocity():
	var angle = randf() * 2 * PI
	var velocity_vector = Vector2(cos(angle), sin(angle)) * base_speed
	linear_velocity = velocity_vector

func _process(delta):
	# Wrap around the screen
	var radius = cshape.shape.radius
	var screen_size = get_viewport_rect().size
	if (global_position.y + radius) < 0:
		global_position.y = screen_size.y + radius
	elif (global_position.y - radius) > screen_size.y:
		global_position.y = -radius
	if (global_position.x + radius) < 0:
		global_position.x = screen_size.x + radius
	elif (global_position.x - radius) > screen_size.x:
		global_position.x = -radius

func explode():
	emit_signal("exploded", global_position, size, points)
	split_asteroid()
	queue_free()

func _on_body_entered(body):
	if body is Laser:
		body.explode()
		explode()

func split_asteroid():
	if size == AsteroidSize.LARGE:
		spawn_smaller_asteroid(AsteroidSize.MEDIUM)
		spawn_smaller_asteroid(AsteroidSize.MEDIUM)
	elif size == AsteroidSize.MEDIUM:
		spawn_smaller_asteroid(AsteroidSize.SMALL)
		spawn_smaller_asteroid(AsteroidSize.SMALL)

func spawn_smaller_asteroid(new_size: AsteroidSize):
	var new_asteroid = preload("res://asteroid.tscn").instantiate()
	new_asteroid.size = new_size
	new_asteroid.global_position = global_position
	new_asteroid.connect("exploded", Callable(self, "_on_asteroid_exploded"))
	get_parent().call_deferred("add_child", new_asteroid)

func _on_asteroid_exploded(pos, size, points):
	split_asteroid()
