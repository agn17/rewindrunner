extends CanvasLayer

@onready var stats_container = $Control/CenterContainer/VBoxContainer/Stats
#@onready var animation_player = $AnimationPlayer

var level_number = 1
var completion_time = 0.0
var rewind_count = 0
var grade = "A"

func _ready():
	# Hide initially
	$Control.modulate.a = 0
	visible = false
	
	# Connect to LevelManager
	var level_manager = get_node("/root/Level_Manager")
	if level_manager:
		level_manager.level_completed.connect(_on_level_completed)

func show_screen(level_num: int, time: float, rewinds: int):
	level_number = level_num
	completion_time = time
	rewind_count = rewinds
	grade = calculate_grade(time, rewinds)
	
	# Update labels
	$Control/CenterContainer/VBoxContainer/Title.text = "LEVEL %d COMPLETE!" % level_num
	$Control/CenterContainer/VBoxContainer/Stats/LevelLabel.text = "Level: %d" % level_num
	$Control/CenterContainer/VBoxContainer/Stats/TimeLabel.text = "Time: %.1fs" % time
	#$Control/CenterContainer/VBoxContainer/Stats/RewindsLabel.text = "Rewinds: %d" % rewinds
	#$Control/CenterContainer/VBoxContainer/Stats/GradeLabel.text = "Grade: %s" % grade
	#
	# Show and animate
	visible = true
#	animation_player.play("slide_in")
	
	# Play victory sound
	#AudioManager.play_sfx(preload("res://assets/sounds/victory.wav"))

func _on_level_completed(level_num: int):
	# Get stats from player
	var player = get_tree().get_first_node_in_group("player")
	var time = 0.0
	var rewinds = 0
	
	if player and player.has_method("get_stats"):
		var stats = player.call("get_stats")
		time = stats.get("time", 0.0)
		rewinds = stats.get("rewinds", 0)
	
	show_screen(level_num, time, rewinds)

func calculate_grade(time: float, rewinds: int) -> String:
	# Simple grading system
	var score = 1000.0 / (time + rewinds * 10)
	
	if score > 800:
		return "S"
	elif score > 600:
		return "A"
	elif score > 400:
		return "B"
	elif score > 200:
		return "C"
	else:
		return "D"

func _on_retry_button_pressed():
	#AudioManager.play_sfx(preload("res://assets/sounds/click.wav"))
#	animation_player.play("fade_out")
#	await animation_player.animation_finished
	
	var level_manager = get_node("/root/Level_Manager")
	if level_manager:
		level_manager.restart_level()
	visible = false

func _on_next_button_pressed():
	#AudioManager.play_sfx(preload("res://assets/sounds/click.wav"))
#	animation_player.play("fade_out")
#	await animation_player.animation_finished
	
	var level_manager = get_node("/root/Level_Manager")
	if level_manager:
		level_manager.next_level()
	visible = false

func _on_menu_button_pressed():
	#AudioManager.play_sfx(preload("res://assets/sounds/click.wav"))
#	animation_player.play("fade_out")
#	await animation_player.animation_finished
	
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	visible = false

func _input(event):
	if visible and event.is_action_pressed("ui_accept"):
		_on_next_button_pressed()
	
	if visible and event.is_action_pressed("ui_cancel"):
		_on_menu_button_pressed()

# Add to Player.gd to track stats:
func get_stats() -> Dictionary:
	return {
		#"time": (Time.get_ticks_msec() - level_start_time) / 1000.0,
		"rewinds": rewind_count
	}
