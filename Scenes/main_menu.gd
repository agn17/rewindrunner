extends Control

@onready var buttons = $MenuButtons
@onready var animation_player = $AnimationPlayer
@onready var title_container = $TitleContainer

var current_button_index = 0
var buttons_array = []

func _ready():
	# Get all buttons
	buttons_array = [
		$MenuButtons/StartButton,
		$MenuButtons/LevelSelectButton,
		$MenuButtons/OptionsButton,
		$MenuButtons/QuitButton
	]
	
	# Connect button signals
	for button in buttons_array:
		button.pressed.connect(_on_button_pressed.bind(button))
		button.mouse_entered.connect(_on_button_hover.bind(button))
	
	# Focus first button
	buttons_array[0].grab_focus()
	
	# Start animations
	#animation_player.play("title_enter")
	#await animation_player.animation_finished
	#animation_player.play("buttons_appear")
	#
	# Play menu music
	#AudioManager.play_music(preload("res://assets/sounds/menu_music.ogg"))

func _on_button_pressed(button: Button):
	# Button click sound
	#AudioManager.play_sfx(preload("res://assets/sounds/click.wav"))
	
	match button.name:
		"StartButton":
			start_game()
		"LevelSelectButton":
			level_select()
		"OptionsButton":
			options_menu()
		"QuitButton":
			quit_game()

func _on_button_hover(button: Button):
	# Hover sound
	#AudioManager.play_sfx(preload("res://assets/sounds/hover.wav"), -10.0)
	
	# Visual feedback
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func start_game():
	print("Starting game...")
	
	# Fade out animation
#	animation_player.play("fade_out")
#	await animation_player.animation_finished
	
	# Load first level
	var level_manager = get_node("/root/Level_Manager")
	if level_manager:
		level_manager.load_level(1)
	else:
		# Fallback
		get_tree().change_scene_to_file("res://Scenes/Tutorial.tscn")

func level_select():
	print("Opening level select...")
	animation_player.play("fade_out")
	await animation_player.animation_finished
	get_tree().change_scene_to_file("res://scenes/ui/LevelSelect.tscn")

func options_menu():
	print("Opening options...")
	animation_player.play("slide_out")
	await animation_player.animation_finished
	get_tree().change_scene_to_file("res://scenes/ui/Options.tscn")

func quit_game():
	print("Quitting game...")
	
	# Confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Are you sure you want to quit?"
	dialog.confirmed.connect(get_tree().quit)
	dialog.canceled.connect(dialog.queue_free)
	
	add_child(dialog)
	dialog.popup_centered()

func _input(event):
	# Keyboard navigation
	if event.is_action_pressed("ui_down"):
		current_button_index = (current_button_index + 1) % buttons_array.size()
		buttons_array[current_button_index].grab_focus()
		_on_button_hover(buttons_array[current_button_index])
	
	elif event.is_action_pressed("ui_up"):
		current_button_index = (current_button_index - 1) % buttons_array.size()
		buttons_array[current_button_index].grab_focus()
		_on_button_hover(buttons_array[current_button_index])
	
	elif event.is_action_pressed("ui_accept"):
		buttons_array[current_button_index].emit_signal("pressed")
