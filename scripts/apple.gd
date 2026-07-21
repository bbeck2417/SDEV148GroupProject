# apple.gd
extends Node2D

var cell_size = 32
var apple_color = Color(0.90, 0.15, 0.18)
var grid_position = Vector2i.ZERO

func place_at(cell):
	grid_position = cell
	queue_redraw()
	
func _draw():
	var pixel_position = Vector2(grid_position) * cell_size
	var apple_rectangle = Rect2(pixel_position + Vector2(4, 4), Vector2(cell_size - 8, cell_size - 8))
	draw_rect(apple_rectangle, apple_color)
	
