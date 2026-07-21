#game_cotroller.gd
extends Node2D

var grid_columns = 24
var grid_rows = 16
var points_per_apple = 1

var game_running = false
var score = 0

@onready var snake = $Snake
@onready var apple = $Apple
@onready var move_timer = $MoveTimer
@onready var score_label = $HUD/Interface/ScoreLabel
@onready var center_panel = $HUD/Interface/CenterPanel
@onready var message_label = $HUD/Interface/CenterPanel/VBoxContainer/MessageLabel
@onready var start_button = $HUD/Interface/CenterPanel/VBoxContainer/StartButton
@onready var restart_button = $HUD/Interface/CenterPanel/VBoxContainer/RestartButton

func _ready():
	snake.reset()
	apple.visible = false
	show_start_screen()
	update_score_label()
	
func show_start_screen():
	game_running = false
	center_panel.visible = true
	message_label.text = "Use Arrow Keys or WASD"
	start_button.visible = true
	restart_button.visible = false
	
func update_score_label():
	score_label.text = "Score: " + str(score)


func _on_move_timer_timeout():
	if not game_running:
		return
	
	var next_head = snake.get_next_head_position()
	var growing = next_head == apple.grid_position
	
	if is_outside_board(next_head):
		finish_game("Game Over - You hit the wall")
		return
	
	if snake.would_collide(next_head, growing):
		finish_game("Game Over - You hit the snake")
		return
	
	snake.advance(growing)
	
	if growing:
		score += points_per_apple
		update_score_label()
		
		if not place_apple():
			finish_game("You Win!")
			
func is_outside_board(cell):
	if cell.x < 0:
		return true
	if cell.x >= grid_columns:
		return true
	if cell.y < 0:
		return true
	if cell.y >= grid_rows:
		return true
	return false
	

func place_apple():
	var available_cells = []

	for row in range(grid_rows):
		for column in range(grid_columns):
			var cell = Vector2i(column, row)

			if not snake.occupies_cell(cell):
				available_cells.append(cell)

	if available_cells.is_empty():
		apple.visible = false
		return false

	var chosen_cell = available_cells.pick_random()
	apple.place_at(chosen_cell)
	apple.visible = true
	return true

func _on_start_button_pressed():
	start_game()


func _on_restart_button_pressed():
	start_game()

func start_game():
	move_timer.stop()
	score = 0
	game_running = true
	snake.reset()
	update_score_label()
	center_panel.visible = false
	place_apple()
	move_timer.start()

func finish_game(message):
	game_running = false
	move_timer.stop()
	center_panel.visible = true
	message_label.text = message
	start_button.visible = false
	restart_button.visible = true

func _unhandled_input(event):
	if not game_running:
		return
		
	if event.is_action_pressed("move_up"):
		snake.request_direction(Vector2i.UP)
	if event.is_action_pressed("move_down"):
		snake.request_direction(Vector2i.DOWN)
	if event.is_action_pressed("move_left"):
		snake.request_direction(Vector2i.LEFT)
	if event.is_action_pressed("move_right"):
		snake.request_direction(Vector2i.RIGHT)
	
