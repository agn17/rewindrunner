extends Node2D
class_name LevelBase

# Level properties
@export var level_name = "Level"
@export var level_number = 1
@export var time_limit = 0.0  # 0 = no limit
@export var hint_text = ""

# References
@onready var player_start = $PlayerStart
@onready var goal_area = $GoalArea
@onready var hint_label = $UI/Hint

var player_instance = null
var is_completed = false
var start_time = 0.0

func _ready():
	print("Loading ", level_name)
	
	# Set level name in UI
	if has_node("UI/LevelLabel"):
		$UI/Level.text = level_name
	
	# Show hint if available
	if hint_text != "" and hint_label:
		hint_label.text = hint_text
		hint_label.visible = true
	
	# Start timer
	start_time = Time.get_ticks_msec()
	
	# Spawn player
	spawn_player()
	
	# Setup goal
	setup_goal()

func spawn_player():
	var player_scene = preload("res://scenes/Player.tscn")
	player_instance = player_scene.instantiate()
	
	if player_start:
		player_instance.global_position = player_start.global_position
	else:
		player_instance.global_position = Vector2(100, 300)
	
	add_child(player_instance)
	
	# Setup camera bounds
	setup_camera_bounds()

func setup_camera_bounds():
	if has_node("CameraBounds/TopLeft") and has_node("CameraBounds/BottomRight"):
		var camera = player_instance.get_node("Camera2D")
		var top_left = $CameraBounds/TopLeft
		var bottom_right = $CameraBounds/BottomRight
		
		camera.limit_left = top_left.global_position.x
		camera.limit_top = top_left.global_position.y
		camera.limit_right = bottom_right.global_position.x
		camera.limit_bottom = bottom_right.global_position.y

func setup_goal():
	if goal_area:
		# Connect goal signal
		if not goal_area.body_entered.is_connected(_on_goal_entered):
			goal_area.body_entered.connect(_on_goal_entered)
		
		# Make sure goal has collision
		if not goal_area.has_node("CollisionShape2D"):
			var collision = CollisionShape2D.new()
			collision.shape = CircleShape2D.new()
			collision.shape.radius = 32
			goal_area.add_child(collision)
		
		# Make sure goal has sprite
		if not goal_area.has_node("Sprite2D"):
			var sprite = Sprite2D.new()
			sprite.texture = load("res://icon.svg")
			sprite.scale = Vector2(0.5, 0.5)
			sprite.modulate = Color.GREEN
			goal_area.add_child(sprite)

func _on_goal_entered(body):
	if body.name == "Player" and not is_completed:
		is_completed = true
		complete_level()

func complete_level():
	var completion_time = (Time.get_ticks_msec() - start_time) / 1000.0
	print("Level ", level_number, " completed in ", completion_time, " seconds!")
	
	# Visual feedback
	if goal_area and goal_area.has_node("Sprite2D"):
		var sprite = goal_area.get_node("Sprite2D")
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.GOLD, 0.3)
		tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.3)
		tween.tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.3)
	
	# Load next level after delay
	await get_tree().create_timer(1.5).timeout
	
	# Use LevelManager to load next level
	var level_manager = get_node("/root/LevelManager")
	if level_manager:
		level_manager.next_level()
	else:
		# Fallback: reload scene
		get_tree().reload_current_scene()

func _process(delta):
	# Update timer display if time limit exists
	if time_limit > 0 and has_node("UI/TimeLabel"):
		var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
		var time_left = max(0, time_limit - elapsed)
		$UI/TimeLabel.text = "Time: %.1f" % time_left
		
		if time_left <= 0:
			time_out()

func time_out():
	print("Time's up!")
	restart_level()

func restart_level():
	get_tree().reload_current_scene()

# Helper function to create platforms
func create_platform(position: Vector2, width: int = 64, height: int = 32, color: Color = Color.GRAY):
	var platform = StaticBody2D.new()
	platform.position = position
	
	var sprite = Sprite2D.new()
	sprite.texture = create_color_texture(color, width, height)
	platform.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(width, height)
	collision.shape = shape
	platform.add_child(collision)
	
	add_child(platform)
	return platform

func create_color_texture(color: Color, width: int, height: int) -> Texture2D:
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)
