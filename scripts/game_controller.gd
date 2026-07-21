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


func _on_move_timer_timeout() -> void:
	pass # Replace with function body.


func _on_start_button_pressed() -> void:
	pass # Replace with function body.


func _on_restart_button_pressed() -> void:
	pass # Replace with function body.
