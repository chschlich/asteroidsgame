class_name Laser extends Area2D

@export var speed := 500.0

var movement_vector := Vector2(0, -1)

@onready var collision_shape = $CollisionShape2D

func _ready():
	collision_shape.disabled = false

func _physics_process(delta):
	global_position += movement_vector.rotated(rotation) * speed * delta

func _on_area_entered(area):
	if area is AsteroidInstance: 
		area.explode()  
		queue_free() 

func explode():
	queue_free()
