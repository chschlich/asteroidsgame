extends Control

@onready var score = $Score:
	set(value):
		score.text = "SCORE: " + str(value)

var lifebar_scene = preload("res://lifebar.tscn")

@onready var lives = $Lives

func init_lives(amount):
	for ul in lives.get_children():
		ul.queue_free()
	for i in amount:
		var ul = lifebar_scene.instantiate()
		lives.add_child(ul)
