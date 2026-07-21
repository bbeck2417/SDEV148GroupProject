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

func request_direction(new_direction):
	if not turn_ready:
		return
		
	if new_direction == -current_direction:
		return
		
	if new_direction == current_direction:
		return
		
	next_direction = new_direction
	turn_ready = false
	
func get_next_head_position():
	return body[0] + next_direction
	
func advance(growing):
	var new_head = get_next_head_position()
	body.push_front(new_head)
	
	if not growing:
		body.pop_back()
	
	current_direction = next_direction
	turn_ready = true
	queue_redraw()
	
func would_collide(cell, growing):
	var cells_to_check = body.size()
	
	if not growing:
		cells_to_check -= 1
		
	for index in range(cells_to_check):
		if body[index] == cell:
			return true
	
	return false
	
func occupies_cell(cell):
	return cell in body
	
func draw():
	for index in range(body.size()):
		var cell = body[index]
		var pixel_position = Vector2(cell) * cell_size
		var segment_rectangle = Rect2(pixel_position + Vector2(2, 2), Vector2(cell_size - 4, cell_size - 4))
		
		if index == 0:
			draw_rect(segment_rectangle, head_color)
		else:
			draw_rect(segment_rectangle, body_color)
