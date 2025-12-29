extends CharacterBody2D

# Player movement variables
@export var speed = 300.0
@export var jump_velocity = -400.0
@export var roll_velocity = 500.0
@export var rewind_duration = 3.0
@export var ghost_scene: PackedScene
var ghost_timer = 0.0
var ghost_interval = 0.1
# Get gravity from project settings
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var ghost_platform_scene: PackedScene
var platform_positions = []  # Track where we've placed platforms
var platform_interval = 0.5  # Seconds between platform spawns during rewind
var platform_timer = 0.0
# Rewind system
var rewinding = false
var rewind_time = 0.0
var position_history = []
var velocity_history = []
var animation_history = []
var max_history_frames = 180
var rewind_speed = 2.0

# Rolling variables
var is_rolling = false
var roll_direction = 0
var roll_duration = 0.3
var roll_timer = 0.0
var can_roll = true
var roll_cooldown = 0.5

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	add_to_group("player")
	_store_history()

func _physics_process(delta):
	if rewinding:
		ghost_timer += get_physics_process_delta_time()
	if ghost_timer >= ghost_interval:
		_spawn_ghost()
		ghost_timer = 0.0
	
	# Spawn ghost platforms while rewinding
	if rewinding:
		platform_timer += get_physics_process_delta_time()
	if platform_timer >= platform_interval:
		_try_spawn_platform()
		platform_timer = 0.0
		##
	if rewinding:
		_process_rewind(delta)
	elif is_rolling:
		_process_roll(delta)
	else:
		_store_history()
		_check_input()
		_apply_movement(delta)
		move_and_slide()
		_update_animation()

func _check_input():
	if Input.is_action_just_pressed("roll") and can_roll and is_on_floor():
		start_roll()

func _apply_movement(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_rolling:
		velocity.y = jump_velocity
	
	# Get input direction
	var direction = Input.get_axis("move_left", "move_right")
	
	if is_rolling:
		# During roll, maintain roll direction
		velocity.x = roll_direction * roll_velocity
	else:
		# Normal movement
		if direction:
			velocity.x = direction * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)

func _store_history():
	position_history.append(global_position)
	velocity_history.append(velocity)
	animation_history.append({
		"animation": animated_sprite.animation,
		"frame": animated_sprite.frame,
		"flip_h": animated_sprite.flip_h,
		"rolling": is_rolling
	})
	
	if position_history.size() > max_history_frames:
		position_history.pop_front()
		velocity_history.pop_front()
		animation_history.pop_front()

# ROLLING FUNCTIONS - FIXED ANIMATION NAME
func start_roll():
	if not can_roll or is_rolling:
		return
	
	print("Roll starting - playing 'rolling' animation")
	is_rolling = true
	can_roll = false
	roll_timer = 0.0
	
	var direction = Input.get_axis("move_left", "move_right")
	if direction != 0:
		roll_direction = direction
	else:
		roll_direction = 1 if not animated_sprite.flip_h else -1
	
	# Play the CORRECT animation name
	animated_sprite.play("rolling")
	
	# Set roll cooldown
	await get_tree().create_timer(roll_cooldown).timeout
	can_roll = true

func _process_roll(delta):
	roll_timer += delta
	
	# Update movement during roll
	velocity.x = roll_direction * roll_velocity
	velocity.y = 0  # No gravity during roll
	
	move_and_slide()
	
	# End roll after duration
	if roll_timer >= roll_duration:
		end_roll()

func end_roll():
	is_rolling = false
	velocity.x = 0
	
	# Resume normal animation
	_update_animation()
	print("Roll ended")

# REWIND FUNCTIONS (unchanged)
func start_rewind():
	$RewindParticles.emitting = true
	if position_history.size() < 10 or rewinding or is_rolling:
		return
	
	rewinding = true
	rewind_time = 0.0
	animated_sprite.modulate = Color(0.6, 0.8, 1.0, 0.7)
	animated_sprite.speed_scale = -1.0

func _process_rewind(delta):
	rewind_time += delta * rewind_speed
	
	var target_time = rewind_duration * rewind_time / rewind_duration
	var history_index = int(target_time * 60)
	history_index = min(history_index, position_history.size() - 1)
	
	if history_index >= 0:
		var target_index = position_history.size() - 1 - history_index
		global_position = position_history[target_index]
		velocity = velocity_history[target_index]
		
		var anim_state = animation_history[target_index]
		animated_sprite.animation = anim_state["animation"]
		animated_sprite.frame = anim_state["frame"]
		animated_sprite.flip_h = anim_state["flip_h"]
		is_rolling = anim_state["rolling"]
	
	if rewind_time >= rewind_duration or position_history.size() - history_index <= 1:
		stop_rewind()

func stop_rewind():
	$RewindParticles.emitting = false

	clear_platforms()  # NEW: Clear platform tracking
	rewinding = false
	rewinding = false
	animated_sprite.modulate = Color.WHITE
	animated_sprite.speed_scale = 1.0
	
	position_history.clear()
	velocity_history.clear()
	animation_history.clear()
	
	_store_history()

# ANIMATION FUNCTION - FIXED to check is_rolling
func _update_animation():
	if rewinding or is_rolling:
		return  # Don't update during rewind or roll
	
	if not is_on_floor():
		animated_sprite.play("jump")
	elif abs(velocity.x) > 10:
		animated_sprite.play("run")
		animated_sprite.flip_h = velocity.x < 0
	else:
		animated_sprite.play("idle")

func _input(event):
	if event.is_action_pressed("rewind"):
		start_rewind()

func _spawn_ghost():
	if not ghost_scene:
		return
	
	var ghost = ghost_scene.instantiate()
	ghost.global_position = global_position
	
	# If using Sprite2D instead of AnimatedSprite2D
	if ghost.has_method("set_texture"):
		# Get current frame from player's animation
		ghost.call("set_texture", animated_sprite.sprite_frames.get_frame_texture(
			animated_sprite.animation, 
			animated_sprite.frame
		))
	
	# Flip ghost if player is flipped
	if ghost.has_node("Sprite2D"):
		ghost.get_node("Sprite2D").flip_h = animated_sprite.flip_h
	
	# Add to current scene
	get_parent().add_child(ghost)
func _try_spawn_platform():
	print("=== SPAWNING SIMPLE PLATFORM ===")
	
	# Use a simple colored rectangle
	var platform = StaticBody2D.new()
	var sprite = Sprite2D.new()
	var collision = CollisionShape2D.new()
	
	# Configure
	sprite.texture = load("res://Assets/sprites/platform.png")
	sprite.modulate = Color(1, 0, 0, 1)  # Bright red
	
	collision.shape = RectangleShape2D.new()
	collision.shape.size = Vector2(33, 9)
	collision.one_way_collision=true
	# Add to platform
	platform.add_child(sprite)
	platform.add_child(collision)
	sprite.owner = platform
	collision.owner = platform
	
	# Position below player
	platform.global_position = global_position + Vector2(0, 50)
	platform.z_index = 100
	
	# Add to scene
	get_parent().add_child(platform)
	
	print("✅ Simple platform added at: ", platform.global_position)
	
	# Auto-remove
	await get_tree().create_timer(3.0).timeout
	platform.queue_free()

func clear_platforms():
	platform_positions.clear()
