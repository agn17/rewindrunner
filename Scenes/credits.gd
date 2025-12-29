extends Control

@onready var credits_container = $CreditsContainer
#@onready var animation_player = $AnimationPlayer

func _ready():
	# Load completion stats
	load_stats()
	
	# Start animation
	#animation_player.play("credits_scroll")
	
	# Play credits music
#	AudioManager.play_music(preload("res://assets/sounds/credits_music.ogg"))

func load_stats():
	var level_manager = get_node("/root/LevelManager")
	if not level_manager:
		return
	
	# Calculate totals
	var total_time = 0.0
	var total_rewinds = 0
	
	for level in range(1, 6):
		var time = level_manager.level_times.get(level, 0.0)
		total_time += time
		
		# Get rewind count (you'd need to track this)
		total_rewinds += 0  # TODO: Track rewinds per level
	
	# Update labels
	$CreditsContainer/Stats/TotalTime.text = "Total Time: %.1fs" % total_time
	$CreditsContainer/Stats/TotalRewinds.text = "Total Rewinds: %d" % total_rewinds
	
	# Calculate overall grade
	var avg_time = total_time / 5
	var grade = "A"
	if avg_time < 30: grade = "S"
	elif avg_time < 60: grade = "A"
	elif avg_time < 90: grade = "B"
	elif avg_time < 120: grade = "C"
	else: grade = "D"
	
	$CreditsContainer/Stats/OverallGrade.text = "Overall Grade: %s" % grade

func _on_play_again_pressed():
#	AudioManager.play_sfx(preload("res://assets/sounds/click.wav"))
	
	# Reset game
	var level_manager = get_node("/root/Level_Manager")
	if level_manager:
		level_manager.load_level(1)
	else:
		get_tree().change_scene_to_file("res://Scenes/Tutorial.tscn")

func _on_main_menu_pressed():
#	AudioManager.play_sfx(preload("res://assets/sounds/click.wav"))
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _input(event):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_on_main_menu_pressed()
