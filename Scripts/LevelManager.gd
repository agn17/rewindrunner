extends Node

class_name LevelManager

# Signals for UI communication
signal level_changed(level_number)
signal level_completed(level_number)
signal level_restarted

# Level tracking
var current_level = 1
var max_level = 5
var checkpoint_position: Vector2 = Vector2.ZERO
var level_start_time = 0.0

# Player reference
var player_instance = null
var player_scene = preload("res://scenes/Player.tscn")

# Level paths - UPDATE THESE TO MATCH YOUR LEVEL FILES
var level_paths = {
	1: "res://scenes/Tutorial.tscn",  # Tutorial
	2: "res://scenes/Level2.tscn",  # Ghost Platforms  
	3: "res://scenes/Level3.tscn",  # Momentum,  # Paradox
	5: "res://scenes/levels/Level.tscn"   # Obstacle Course
}

func _ready():
	print("LevelManager ready")
	
	# If we start in a level scene directly, detect current level
	detect_current_level()

func detect_current_level():
	# Try to figure out what level we're in based on scene name
	var current_scene = get_tree().current_scene.name
	print("Current scene: ", current_scene)
	
	if "Tutorial" in current_scene or "Tutorial" in current_scene:
		current_level = 1
	elif "Level_2" in current_scene or "Ghost" in current_scene:
		current_level = 2
	elif "Level_3" in current_scene or "Momentum" in current_scene:
		current_level = 3
	elif "Level" in current_scene or "Obstacle" in current_scene or "Final" in current_scene:
		current_level = 4
	
	print("Detected level: ", current_level)
	
	# If we're in a level, spawn player
	if current_level >= 1 and current_level <= max_level:
		call_deferred("spawn_player_in_current_level")

func load_level(level_number: int):
	if level_number < 1 or level_number > max_level:
		print("Invalid level number: ", level_number)
		return
	
	current_level = level_number
	checkpoint_position = Vector2.ZERO
	
	print("Loading level ", level_number)
	
	var level_path = level_paths[level_number]
	if ResourceLoader.exists(level_path):
		get_tree().change_scene_to_file(level_path)
		emit_signal("level_changed", level_number)
	else:
		print("ERROR: Level file not found: ", level_path)
		# Try to find any level file
		_find_any_level_file(level_number)

func _find_any_level_file(level_number: int):
	# Try different naming patterns
	var possible_paths = [
		"res://scenes/Level%d.tscn" % level_number,
		"res://scenes/level%d.tscn" % level_number,
		"res://scence/Level%d.tscn" % level_number,
		"res://Level%d.tscn" % level_number
	]
	
	for path in possible_paths:
		if ResourceLoader.exists(path):
			print("Found level at: ", path)
			get_tree().change_scene_to_file(path)
			emit_signal("level_changed", level_number)
			return
	
	print("ERROR: Could not find any level file!")
	# Create a simple fallback level
	_create_fallback_level()

func _create_fallback_level():
	var level = Node2D.new()
	level.name = "FallbackLevel"
	
	# Add ground
	var ground = StaticBody2D.new()
	ground.position = Vector2(400, 550)
	
	var sprite = Sprite2D.new()
	# Create simple texture
	var image = Image.create(800, 100, false, Image.FORMAT_RGBA8)
	image.fill(Color.DARK_GRAY)
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	ground.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(800, 100)
	collision.shape = shape
	ground.add_child(collision)
	
	level.add_child(ground)
	
	# Add goal
	var goal = Area2D.new()
	goal.position = Vector2(700, 450)
	
	var goal_sprite = Sprite2D.new()
	goal_sprite.texture = load("res://Assets/yom-kippur-horn.png")
	#goal_sprite.modulate = Color.GREEN
	goal_sprite.scale = Vector2(0.016, 0.014)
	goal.add_child(goal_sprite)
	
	var goal_collision = CollisionShape2D.new()
	var goal_shape = CircleShape2D.new()
	goal_shape.radius = 32
	goal_collision.shape = goal_shape
	goal.add_child(goal_collision)
	
	# Add goal script
	var goal_script = load("res://scripts/Goal.gd")
	if goal_script:
		goal.set_script(goal_script)
	
	level.add_child(goal)
	
	get_tree().root.add_child(level)
	print("Created fallback level")

func next_level():
	var next = current_level + 1
	if next > max_level:
		print("Game complete! All levels finished.")
		game_complete()
	else:
		load_level(next)

func restart_level(use_checkpoint: bool = false):
	if use_checkpoint and checkpoint_position != Vector2.ZERO:
		# Reset player to checkpoint
		if player_instance and is_instance_valid(player_instance):
			player_instance.global_position = checkpoint_position
			player_instance.velocity = Vector2.ZERO
			emit_signal("level_restarted")
	else:
		# Full restart
		load_level(current_level)

func set_checkpoint(position: Vector2):
	checkpoint_position = position
	print("Checkpoint set at: ", position)

func complete_current_level():
	var completion_time = (Time.get_ticks_msec() - level_start_time) / 1000.0
	print("Level ", current_level, " completed in ", completion_time, " seconds!")
	
	emit_signal("level_completed", current_level)
	
	# Wait a moment, then load next level
	await get_tree().create_timer(1.5).timeout
	next_level()

func game_complete():
	print("🎉 GAME COMPLETE! All 5 levels finished!")
	
	# Load credits/end screen
	var credits_path = "res://scenes/credits.tscn"
	if ResourceLoader.exists(credits_path):
		get_tree().change_scene_to_file(credits_path)
	else:
		print("Credits screen not found, returning to main menu")
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

# Called when a level scene is loaded
func on_level_loaded(level_scene: Node2D):
	print("Level loaded: ", level_scene.name)
	level_start_time = Time.get_ticks_msec()
	
	# Find PlayerStart marker or spawn point
	spawn_player(level_scene)
	
	# Setup goal to call LevelManager when reached
	setup_goal(level_scene)

# NEW: Safe method to try spawning player
func _try_spawn_player_in_current_scene():
	var current_scene = get_tree().current_scene
	
	# Only spawn player if we're in a Node2D (level), not Control (UI)
	if current_scene is Node2D:
		print("Current scene is Node2D, attempting to spawn player...")
		spawn_player(current_scene)
	else:
		print("Current scene is not a Node2D (it's a ", current_scene.get_class(), "), not spawning player")

# Updated spawn_player method - ONLY CALLED FOR NODE2D SCENES
func spawn_player(level_scene: Node2D):
	print("Spawning player in level: ", level_scene.name)
	
	# Remove existing player if any
	if player_instance and is_instance_valid(player_instance):
		player_instance.queue_free()
		player_instance = null
	
	# Try to find PlayerStart marker
	var player_start = find_node_in_scene(level_scene, "PlayerStart")
	var spawn_position = Vector2(100, 300)  # Default
	
	if player_start:
		spawn_position = player_start.global_position
		print("Found PlayerStart at: ", spawn_position)
	else:
		print("No PlayerStart found, using default position")
	
	# Spawn player
	player_instance = player_scene.instantiate()
	player_instance.global_position = spawn_position
	player_instance.add_to_group("player")
	
	# Add player to level
	level_scene.add_child(player_instance)
	
	# Setup camera bounds if markers exist
	setup_camera_bounds(level_scene)
	
	# Start level timer
	level_start_time = Time.get_ticks_msec()
	
	print("Player spawned at: ", spawn_position)
	
	# Setup goal connection
	setup_goal(level_scene)


func find_node_in_scene(root: Node, node_name: String) -> Node:
	# Search recursively for a node
	if root.name == node_name:
		return root
	
	for child in root.get_children():
		var found = find_node_in_scene(child, node_name)
		if found:
			return found
	
	return null

func setup_camera_bounds(level_scene: Node2D):
	if not player_instance:
		return
	
	var camera = player_instance.get_node_or_null("Camera2D")
	if not camera:
		return
	
	# Look for camera bound markers
	var top_left = find_node_in_scene(level_scene, "TopLeft")
	var bottom_right = find_node_in_scene(level_scene, "BottomRight")
	
	if top_left and bottom_right:
		camera.limit_left = top_left.global_position.x
		camera.limit_top = top_left.global_position.y
		camera.limit_right = bottom_right.global_position.x
		camera.limit_bottom = bottom_right.global_position.y
		print("Camera bounds set")
	else:
		# Default bounds
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = 800
		camera.limit_bottom = 600

func setup_goal(level_scene: Node2D):
	# Find goal area
	var goal = find_node_in_scene(level_scene, "GoalArea")
	if not goal:
		# Try other common names
		goal = find_node_in_scene(level_scene, "Goal")
		if not goal:
			goal = find_node_in_scene(level_scene, "End")
	
	if goal:
		print("Found goal: ", goal.name)
		
		# Make sure goal has proper collision and script
		ensure_goal_has_script(goal)
	else:
		print("WARNING: No goal found in level!")

func ensure_goal_has_script(goal: Node):
	# Check if goal has collision
	if not goal.has_node("CollisionShape2D"):
		var collision = CollisionShape2D.new()
		collision.shape = CircleShape2D.new()
		collision.shape.radius = 32
		goal.add_child(collision)
	
	# Check if goal has sprite (for visual)
	if not goal.has_node("Sprite2D"):
		var sprite = Sprite2D.new()
		sprite.texture = load("res://Assets/yom-kippur-horn.png")
		#sprite.modulate = Color.GREEN
		sprite.scale = Vector2(0.016, 0.014)
		goal.add_child(sprite)
	
	# Add or update goal script
	var goal_script = load("res://scripts/Goal.gd")
	if goal_script:
		goal.set_script(goal_script)
		
		# Connect to LevelManager if script has the right method
		if goal.has_method("set_level_manager"):
			goal.call("set_level_manager", self)
	else:
		print("WARNING: Goal.gd script not found!")

# Helper method for goals to call
func level_complete():
	complete_current_level()

# Save/load system (simple)
func save_game():
	var save_data = {
		"current_level": current_level,
		"checkpoint_x": checkpoint_position.x,
		"checkpoint_y": checkpoint_position.y
	}
	
	var file = FileAccess.open("user://save.dat", FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("Game saved")

func load_game():
	if FileAccess.file_exists("user://save.dat"):
		var file = FileAccess.open("user://save.dat", FileAccess.READ)
		if file:
			var save_data = file.get_var()
			current_level = save_data.get("current_level", 1)
			checkpoint_position = Vector2(
				save_data.get("checkpoint_x", 0),
				save_data.get("checkpoint_y", 0)
			)
			file.close()
			print("Game loaded: Level ", current_level)
			
			# Load the saved level
			load_level(current_level)
			return true
	
	return false

# Debug commands
func _input(event):
	if event.is_action_pressed("debug_next_level"):
		next_level()
	
	if event.is_action_pressed("debug_restart"):
		restart_level(false)
	
	if event.is_action_pressed("debug_save"):
		save_game()
	
	if event.is_action_pressed("debug_load"):
		load_game()
