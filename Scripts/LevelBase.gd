extends Node2D

# Export variables for level customization
@export var level_name: String = "Unnamed Level"
@export var level_number: int = 1
@export var time_limit: float = 0.0  # 0 = no limit
@export var hint_text: String = ""

# Level state
var is_completed: bool = false
var start_time: float = 0.0
var current_time: float = 0.0
var player_ref: CharacterBody2D = null

@onready var ui = $UI/Control
@onready var hint_label = $UI/Control/Hints
@onready var timer_label = $UI/Control/TimerDisplay
@onready var level_name_label = $UI/Control/LevelName

func _ready():
	# Setup level
	name = "LevelRoot"
	
	# Update UI
	level_name_label.text = level_name
	hint_label.text = hint_text
	
	# Connect signals
	Level_Manager.level_changed.connect(_on_level_changed)
	
	# Start level timer
	start_time = Time.get_ticks_msec() / 1000.0
	
	# Find player
	_find_player()
	
	# Setup goal
	_setup_goal()

func _process(delta):
	# Update timer
	if not is_completed and time_limit > 0:
		current_time = Time.get_ticks_msec() / 1000.0 - start_time
		var time_left = max(0, time_limit - current_time)
		timer_label.text = "Time: %.1f" % time_left
		
		if time_left <= 0:
			_on_timeout()

func _find_player():
	# Wait a frame for player to spawn
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
		print("Player found: ", player_ref)

func _setup_goal():
	var goal = $World/Objects/GoalArea
	if goal:
		if goal.has_signal("body_entered"):
			goal.disconnect("body_entered", Callable(self, "_on_goal_entered"))
		goal.connect("body_entered", Callable(self, "_on_goal_entered"))

func _on_goal_entered(body: Node):
	if body.name == "Player" and not is_completed:
		is_completed = true
		print("Level ", level_number, " completed!")
		
		# Show completion effect
		_show_completion_effect()
		
		# Complete level through manager
		Level_Manager.complete_level()

func _show_completion_effect():
	# Flash screen, play sound, etc.
	var goal = $World/Objects/GoalArea
	if goal:
		var tween = create_tween()
		tween.tween_property(goal.get_node("Sprite2D"), "modulate", Color.GOLD, 0.3)
		tween.tween_property(goal.get_node("Sprite2D"), "modulate", Color.WHITE, 0.3)
		tween.set_loops(3)
	
	# Play sound
#	AudioManager.play_sfx(preload("res://assets/sounds/victory.wav"))

func _on_timeout():
	if not is_completed:
		print("Time's up!")
		Level_Manager.restart_level(false)

func _on_level_changed(old_level: int, new_level: int):
	# Cleanup if needed
	pass

# Helper function to get all objects of a type
func get_all_objects_in_group(group_name: String) -> Array:
	return get_tree().get_nodes_in_group(group_name)

# Function to show/hide hint
func show_hint(text: String = ""):
	if text != "":
		hint_label.text = text
	hint_label.visible = true

func hide_hint():
	hint_label.visible = false

# Function to pause/unpause level
func set_level_paused(paused: bool):
	get_tree().paused = paused
	$UI/PauseMenu.visible = paused
