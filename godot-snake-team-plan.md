# Godot 4 Snake Game — Team Plan With Implementation Snippets

## Summary

The team will implement the game in three coding checkpoints:

1. Person A creates the shared project foundation.
2. Persons B and C build the gameplay objects and interface in parallel.
3. Person A integrates everything through the game controller.

The snippets below are the intended final contents of each script. Team members should still implement and commit them incrementally so each part can be tested before moving forward.

## 1. Shared Project Configuration

**Owner: Person A**  
**Branch: `setup/project-foundation`**

Create:

```text
res://
├── scenes/
│   ├── Main.tscn
│   ├── Snake.tscn
│   ├── Apple.tscn
│   └── HUD.tscn
└── scripts/
    ├── game_config.gd
    ├── game_controller.gd
    ├── snake.gd
    ├── apple.gd
    ├── hud.gd
    └── input_controller.gd
```

Configure the project:

- Godot 4.x
- Compatibility renderer
- Viewport: `960 × 640`
- Stretch mode: `canvas_items`
- Stretch aspect: `keep`
- Mobile orientation: landscape

Add input actions:

| Action | Keys |
|---|---|
| `move_up` | Up Arrow and W |
| `move_down` | Down Arrow and S |
| `move_left` | Left Arrow and A |
| `move_right` | Right Arrow and D |

### `game_config.gd`

Person A creates this first so everyone uses the same values:

```gdscript
class_name GameConfig
extends RefCounted

const CELL_SIZE := 32
const GRID_COLUMNS := 24
const GRID_ROWS := 16
const TOTAL_CELLS := GRID_COLUMNS * GRID_ROWS

const BOARD_ORIGIN := Vector2(96.0, 96.0)
const BOARD_PIXEL_SIZE := Vector2(
	GRID_COLUMNS * CELL_SIZE,
	GRID_ROWS * CELL_SIZE
)

const MOVE_INTERVAL := 0.15
const STARTING_LENGTH := 3
const POINTS_PER_APPLE := 1

const SWIPE_MINIMUM_DISTANCE := 40.0
```

Commit:

```text
Create shared game configuration
```

## 2. Build the Snake

**Owner: Person B**  
**Branch: `feature/snake-apple`**

Create `Snake.tscn`:

```text
Snake (Node2D)
```

Attach `snake.gd`.

### Checkpoint B1 — Snake data and reset

Start with the state and reset behavior:

```gdscript
extends Node2D

const BODY_COLOR := Color(0.20, 0.70, 0.28)
const HEAD_COLOR := Color(0.55, 0.95, 0.30)

var body: Array[Vector2i] = []
var current_direction := Vector2i.RIGHT
var queued_direction := Vector2i.RIGHT
var turn_queued := false

func reset() -> void:
	body.clear()
	body.append(Vector2i(12, 8))
	body.append(Vector2i(11, 8))
	body.append(Vector2i(10, 8))

	current_direction = Vector2i.RIGHT
	queued_direction = Vector2i.RIGHT
	turn_queued = false
	queue_redraw()
```

Temporarily call `reset()` from `_ready()` and verify that `body.size()` is three.

Commit:

```text
Add snake state and reset behavior
```

### Checkpoint B2 — Direction and movement

Add:

```gdscript
func request_direction(new_direction: Vector2i) -> bool:
	var valid_directions := [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]

	if new_direction not in valid_directions:
		return false

	if turn_queued:
		return false

	if new_direction == -current_direction:
		return false

	if new_direction == current_direction:
		return false

	queued_direction = new_direction
	turn_queued = true
	return true


func get_next_head_position() -> Vector2i:
	return body[0] + queued_direction


func advance(growing: bool) -> void:
	var new_head := get_next_head_position()
	body.push_front(new_head)

	if not growing:
		body.pop_back()

	current_direction = queued_direction
	turn_queued = false
	queue_redraw()
```

The `turn_queued` flag prevents the player from entering two turns between movement ticks and accidentally reversing into the snake’s neck.

Commit:

```text
Add snake movement and turn validation
```

### Checkpoint B3 — Collision helpers and drawing

Add:

```gdscript
func would_collide(cell: Vector2i, growing: bool) -> bool:
	var cells_to_check := body.size()

	if not growing:
		cells_to_check -= 1

	for index in range(max(cells_to_check, 0)):
		if body[index] == cell:
			return true

	return false


func occupies_cell(cell: Vector2i) -> bool:
	return cell in body


func get_length() -> int:
	return body.size()


func _draw() -> void:
	for index in range(body.size()):
		var cell := body[index]
		var pixel_position := Vector2(cell) * GameConfig.CELL_SIZE
		var segment_rectangle := Rect2(
			pixel_position + Vector2(2.0, 2.0),
			Vector2(
				GameConfig.CELL_SIZE - 4.0,
				GameConfig.CELL_SIZE - 4.0
			)
		)

		var color := BODY_COLOR

		if index == 0:
			color = HEAD_COLOR

		draw_rect(segment_rectangle, color)
```

Remove the temporary `_ready()` reset after the main controller is ready to own initialization.

Final `snake.gd` contains all B1–B3 snippets in the same order.

### Snake acceptance tests

- `reset()` produces three segments.
- `advance(false)` moves without changing length.
- `advance(true)` adds one segment.
- Opposite-direction requests return false.
- Only one new turn is accepted between ticks.
- Moving into a tail that is about to leave is allowed.
- The head uses a different color from the body.

## 3. Build the Apple

**Owner: Person B**  
**Same feature branch**

Create `Apple.tscn`:

```text
Apple (Node2D)
```

Attach `apple.gd` with this final content:

```gdscript
extends Node2D

const APPLE_COLOR := Color(0.90, 0.15, 0.15)

var grid_position := Vector2i.ZERO

func place_at(cell: Vector2i) -> void:
	grid_position = cell
	queue_redraw()


func get_grid_position() -> Vector2i:
	return grid_position


func _draw() -> void:
	var pixel_position := Vector2(grid_position) * GameConfig.CELL_SIZE
	var apple_rectangle := Rect2(
		pixel_position + Vector2(4.0, 4.0),
		Vector2(
			GameConfig.CELL_SIZE - 8.0,
			GameConfig.CELL_SIZE - 8.0
		)
	)

	draw_rect(apple_rectangle, APPLE_COLOR)
```

Commit:

```text
Add drawable apple object
```

### Apple acceptance tests

- Calling `place_at(Vector2i(5, 6))` moves the apple to that cell.
- Repositioning does not create another apple.
- The apple aligns with the snake grid.
- The apple does not select its own random position.

## 4. Build the HUD

**Owner: Person C**  
**Branch: `feature/hud-input`**

Create this exact `HUD.tscn` tree:

```text
HUD (CanvasLayer)
└── Interface (Control)
    ├── ScoreLabel (Label)
    └── CenterPanel (VBoxContainer)
        ├── TitleLabel (Label)
        ├── MessageLabel (Label)
        ├── StartButton (Button)
        └── RestartButton (Button)
```

Set Interface to Full Rect. Center CenterPanel in the viewport. Give both buttons a custom minimum size of `180 × 56`.

Attach `hud.gd` to HUD.

### Checkpoint C1 — Signals and node references

```gdscript
extends CanvasLayer

signal start_requested
signal restart_requested

@onready var score_label: Label = $Interface/ScoreLabel
@onready var center_panel: VBoxContainer = $Interface/CenterPanel
@onready var title_label: Label = $Interface/CenterPanel/TitleLabel
@onready var message_label: Label = $Interface/CenterPanel/MessageLabel
@onready var start_button: Button = $Interface/CenterPanel/StartButton
@onready var restart_button: Button = $Interface/CenterPanel/RestartButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	show_ready()


func _on_start_pressed() -> void:
	start_requested.emit()


func _on_restart_pressed() -> void:
	restart_requested.emit()
```

Commit:

```text
Add HUD controls and button signals
```

### Checkpoint C2 — HUD states

Add:

```gdscript
func set_score(value: int) -> void:
	score_label.text = "Score: %d" % value


func show_ready() -> void:
	set_score(0)
	title_label.text = "Snake"
	message_label.text = ""
	center_panel.show()
	start_button.show()
	restart_button.hide()
	start_button.grab_focus()


func show_playing() -> void:
	center_panel.hide()
	start_button.hide()
	restart_button.hide()


func show_game_over(message: String, final_score: int) -> void:
	title_label.text = message
	message_label.text = "Final Score: %d" % final_score
	center_panel.show()
	start_button.hide()
	restart_button.show()
	restart_button.grab_focus()
```

Final `hud.gd` contains the C1 and C2 snippets.

Commit:

```text
Add ready playing and game-over HUD states
```

### HUD acceptance tests

- Ready state shows title, score zero, and Start.
- Playing state hides the center panel.
- Game-over state shows the final score and Restart.
- Button presses emit signals without searching for Main.
- Start and Restart can receive keyboard focus.

## 5. Build Keyboard and Swipe Input

**Owner: Person C**  
**Same feature branch**

Person C creates `input_controller.gd`. Person A will attach it to the InputController node during integration.

### Checkpoint C3 — Keyboard input

Begin with:

```gdscript
extends Node

signal direction_requested(direction: Vector2i)

var touch_start_position := Vector2.ZERO
var tracking_touch := false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return

	var keyboard_direction := _get_keyboard_direction(event)

	if keyboard_direction != Vector2i.ZERO:
		direction_requested.emit(keyboard_direction)
		get_viewport().set_input_as_handled()
		return

	_handle_touch_input(event)


func _get_keyboard_direction(event: InputEvent) -> Vector2i:
	if event.is_action_pressed("move_up"):
		return Vector2i.UP

	if event.is_action_pressed("move_down"):
		return Vector2i.DOWN

	if event.is_action_pressed("move_left"):
		return Vector2i.LEFT

	if event.is_action_pressed("move_right"):
		return Vector2i.RIGHT

	return Vector2i.ZERO
```

Commit:

```text
Add keyboard direction input
```

### Checkpoint C4 — Swipe input

Add:

```gdscript
func _handle_touch_input(event: InputEvent) -> void:
	if not event is InputEventScreenTouch:
		return

	if event.pressed:
		touch_start_position = event.position
		tracking_touch = true
		return

	if not tracking_touch:
		return

	tracking_touch = false
	var swipe := event.position - touch_start_position

	if swipe.length() < GameConfig.SWIPE_MINIMUM_DISTANCE:
		return

	var direction := Vector2i.ZERO

	if abs(swipe.x) > abs(swipe.y):
		direction = Vector2i.RIGHT if swipe.x > 0.0 else Vector2i.LEFT
	else:
		direction = Vector2i.DOWN if swipe.y > 0.0 else Vector2i.UP

	direction_requested.emit(direction)
	get_viewport().set_input_as_handled()
```

Final `input_controller.gd` contains C3 and C4.

Commit:

```text
Add mobile swipe direction input
```

### Input acceptance tests

- Arrow keys and WASD emit the correct directions.
- Held-key echo events are ignored.
- A movement shorter than 40 pixels is treated as a tap.
- A completed swipe emits exactly one direction.
- Button taps consumed by the HUD do not become swipes.

## 6. Assemble the Main Scene

**Owner: Person A**  
**Branch: `feature/game-controller`**

After the feature scenes are merged, create this final tree:

```text
Main (Node2D) [game_controller.gd]
├── Board (ColorRect)
├── Snake (instance of Snake.tscn)
├── Apple (instance of Apple.tscn)
├── MoveTimer (Timer)
├── InputController (Node) [input_controller.gd]
└── HUD (instance of HUD.tscn)
```

Configure:

```text
Board.position = (96, 96)
Board.size = (768, 512)
Board.color = dark gray
Snake.position = (96, 96)
Apple.position = (96, 96)
MoveTimer.wait_time = 0.15
MoveTimer.one_shot = false
MoveTimer.autostart = false
```

Attach `game_controller.gd` to Main.

## 7. Implement the Game Controller

**Owner: Person A**

### Checkpoint A1 — State, nodes, and signals

Start with:

```gdscript
extends Node2D

signal score_changed(new_score: int)
signal game_started
signal game_finished(message: String, final_score: int)

enum GameState {
	READY,
	PLAYING,
	GAME_OVER
}

@onready var snake: Node2D = $Snake
@onready var apple: Node2D = $Apple
@onready var move_timer: Timer = $MoveTimer
@onready var input_controller: Node = $InputController
@onready var hud: CanvasLayer = $HUD

var state := GameState.READY
var score := 0
var random := RandomNumberGenerator.new()

func _ready() -> void:
	random.randomize()

	hud.start_requested.connect(start_game)
	hud.restart_requested.connect(restart_game)
	input_controller.direction_requested.connect(_on_direction_requested)
	move_timer.timeout.connect(_on_move_timer_timeout)

	score_changed.connect(hud.set_score)
	game_started.connect(hud.show_playing)
	game_finished.connect(hud.show_game_over)

	move_timer.stop()
	hud.show_ready()
```

Commit:

```text
Add game states and signal connections
```

### Checkpoint A2 — Start and Restart

Add:

```gdscript
func start_game() -> void:
	if state == GameState.PLAYING:
		return

	move_timer.stop()
	score = 0
	snake.reset()
	state = GameState.PLAYING

	if not place_apple():
		finish_game("You Win!")
		return

	score_changed.emit(score)
	game_started.emit()

	move_timer.wait_time = GameConfig.MOVE_INTERVAL
	move_timer.start()


func restart_game() -> void:
	if state != GameState.GAME_OVER:
		return

	start_game()


func _on_direction_requested(direction: Vector2i) -> void:
	if state != GameState.PLAYING:
		return

	snake.request_direction(direction)
```

Commit:

```text
Add game start restart and direction handling
```

### Checkpoint A3 — Board and apple helpers

Add:

```gdscript
func is_outside_board(cell: Vector2i) -> bool:
	return (
		cell.x < 0
		or cell.y < 0
		or cell.x >= GameConfig.GRID_COLUMNS
		or cell.y >= GameConfig.GRID_ROWS
	)


func choose_empty_cell() -> Variant:
	var available_cells: Array[Vector2i] = []

	for row in range(GameConfig.GRID_ROWS):
		for column in range(GameConfig.GRID_COLUMNS):
			var candidate := Vector2i(column, row)

			if not snake.occupies_cell(candidate):
				available_cells.append(candidate)

	if available_cells.is_empty():
		return null

	var random_index := random.randi_range(
		0,
		available_cells.size() - 1
	)

	return available_cells[random_index]


func place_apple() -> bool:
	var selected_cell: Variant = choose_empty_cell()

	if selected_cell == null:
		return false

	var apple_cell: Vector2i = selected_cell
	apple.place_at(apple_cell)
	return true
```

Commit:

```text
Add board bounds and safe apple placement
```

### Checkpoint A4 — Movement tick and collisions

Add:

```gdscript
func _on_move_timer_timeout() -> void:
	if state != GameState.PLAYING:
		return

	var next_head: Vector2i = snake.get_next_head_position()
	var will_eat_apple := next_head == apple.get_grid_position()

	if is_outside_board(next_head):
		finish_game("Game Over")
		return

	if snake.would_collide(next_head, will_eat_apple):
		finish_game("Game Over")
		return

	snake.advance(will_eat_apple)

	if not will_eat_apple:
		return

	score += GameConfig.POINTS_PER_APPLE
	score_changed.emit(score)

	if snake.get_length() >= GameConfig.TOTAL_CELLS:
		finish_game("You Win!")
		return

	if not place_apple():
		finish_game("You Win!")
```

Commit:

```text
Add movement scoring growth and collision loop
```

### Checkpoint A5 — Finish the game

Add:

```gdscript
func finish_game(message: String) -> void:
	if state == GameState.GAME_OVER:
		return

	move_timer.stop()
	state = GameState.GAME_OVER
	game_finished.emit(message, score)
```

Final `game_controller.gd` contains A1–A5 in that order.

Commit:

```text
Complete game-over and win states
```

## 8. Integration Order

Merge in this exact order:

1. `setup/project-foundation`
2. `feature/snake-apple`
3. `feature/hud-input`
4. `feature/game-controller`

Person A owns all edits to `Main.tscn` during integration.

After each merge:

1. Open the project in Godot.
2. Run `Main.tscn`.
3. Check the debugger.
4. Confirm node names still match the `$NodeName` references.
5. Fix integration problems in a separate commit.
6. Do not rename shared functions or signals without updating every caller.

Tag the first playable version:

```text
v0.1-playable
```

## 9. Required Test Scenarios

| Scenario | Expected result |
|---|---|
| Launch project | Start and score zero appear; timer is stopped |
| Press Start | HUD hides and snake moves right |
| Press Start repeatedly | Only one game and timer remain active |
| Press opposite direction | Request is rejected |
| Enter two turns before one tick | Only the first valid turn is accepted |
| Eat an apple | Score and length each increase by one |
| Apple respawns | New apple is inside the board and outside the snake |
| Hit a wall | Timer stops and Game Over appears |
| Hit the snake’s body | Timer stops and Game Over appears |
| Press Restart | Score resets and snake returns to three segments |
| Tap the board | No direction is emitted |
| Swipe four directions | Matching direction is requested |
| Tap Start or Restart | Button works without steering |
| Fill a reduced test board | `You Win!` appears |
| Play multiple games | No duplicate nodes, timers, or signal calls |
| Inspect debugger | No parser errors or runtime errors |

Each team member tests code owned by another member:

- Person A tests snake and apple behavior.
- Person B tests HUD and input.
- Person C tests the controller and complete game loop.

## 10. Export Checkpoint

**Owner: Person C**  
**Branch: `qa/platform-exports`**

1. Install matching Godot export templates.
2. Add Windows, macOS, Linux, Web, Android, and iOS presets.
3. Test desktop and web builds.
4. Test Android with a device or emulator.
5. Test iOS when macOS, Xcode, and signing access are available.
6. Verify landscape orientation and swipe input.
7. Record tested platforms in the README.
8. Keep store submission and signing outside the initial assignment.

Tag the passing version:

```text
v1.0-simple
```

## Definition of Done

- All six scripts contain the completed snippets above.
- The node tree and node names match the script references.
- Start, Restart, score, movement, growth, apple placement, collision, keyboard input, and swipe input work together.
- Every acceptance scenario passes.
- Another team member reviews each branch.
- No errors appear in the Godot debugger.
- Textures, sound, animation, difficulty, and persistent high scores remain deferred until the simple version is stable.

## Assumptions

- The group has three members using Godot 4.x and GDScript.
- The game uses simple drawn shapes for version 1.
- The score increases by one per apple.
- Movement speed remains constant.
- Mobile play uses landscape orientation and swipe controls.
- The snippets are implementation targets; team members should type, test, and commit them in the listed checkpoints rather than merging all code in one unreviewed change.
