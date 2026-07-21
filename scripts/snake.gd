extends Node2D

var cell_size = 32
var body_color = Color(0.20, 0.70, 0.28)
var head_color = Color(0.55, 0.95, 0.30)

var body = []
var current_direction = Vector2i.RIGHT
var next_direction = Vector2i.RIGHT
var turn_ready = true

func reset():
	body = [
		Vector2i(12, 8),
		Vector2i(11, 8),
		Vector2i(10, 8)
	]
	current_direction = Vector2i.RIGHT
	next_direction = Vector2i.RIGHT
	turn_ready = true
	queue_redraw()
	
func _ready():
	reset()
	print(body.size())
