extends StaticBody2D

# Configuration
@export var disappear_time: float = 3.0  # Seconds before disappearing
@export var reset_time: float = 5.0     # Seconds before reappearing
@export var warning_time: float = 1.0   # Seconds of warning before disappearing

# References
@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var timer = $Timer
@onready var area = $Area2D

# State
var is_active: bool = true
var player_on_platform: bool = false
var original_color: Color
var is_disappearing: bool = false

func _ready():
	# Store original color
	original_color = sprite.modulate
	
	# Configure timer
	timer.wait_time = disappear_time
	timer.one_shot = true
	
	# Connect signals
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	timer.timeout.connect(_on_timer_timeout)
	
	# Make it orange to indicate temporary
	sprite.modulate = Color.ORANGE

func _on_body_entered(body):
	if body.name == "Player" and is_active:
		player_on_platform = true
		print("Player stepped on temp platform")
		
		# Start countdown if not already disappearing
		if not is_disappearing:
			start_disappear_countdown()

func _on_body_exited(body):
	if body.name == "Player":
		player_on_platform = false
		print("Player left temp platform")
		
		# If player leaves before timer ends, reset countdown
		if is_active and not is_disappearing:
			timer.stop()
			reset_visuals()

func start_disappear_countdown():
	is_disappearing = true
	
	# Start the timer
	timer.start()
	
	# Visual feedback: start pulsing when countdown begins
	start_warning_effect()

func _on_timer_timeout():
	if player_on_platform:
		print("Platform disappearing with player on it!")
		# Player might fall - could add screen shake or warning
		
	# Make platform disappear
	disappear()
	
	# Schedule reappearance
	await get_tree().create_timer(reset_time).timeout
	reappear()

func disappear():
	is_active = false
	is_disappearing = false
	
	# Disable collision
	collision.disabled = true
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): sprite.visible = false)
	
	print("Platform disappeared")

func reappear():
	is_active = true
	player_on_platform = false
	
	# Enable collision
	collision.disabled = false
	
	# Fade in
	sprite.visible = true
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", original_color, 0.5)
	
	print("Platform reappeared")

func start_warning_effect():
	# Pulse effect when about to disappear
	var time_left = timer.wait_time
	var warning_start = timer.wait_time - warning_time
	
	# Wait until warning time starts
	if warning_start > 0:
		await get_tree().create_timer(warning_start).timeout
	
	# Pulse during warning period
	var pulse_tween = create_tween()
	pulse_tween.set_loops()  # Loop forever until platform disappears
	
	pulse_tween.tween_property(sprite, "modulate", Color.RED, 0.3)
	pulse_tween.tween_property(sprite, "modulate", original_color, 0.3)

func reset_visuals():
	is_disappearing = false
	timer.stop()
	
	# Stop any ongoing tween
	var tweens = get_tree().get_processed_tweens()
	for t in tweens:
		if t.get_parent() == self:
			t.kill()
	
	# Reset color
	sprite.modulate = original_color

# Optional: Draw outline when selected in editor
func _draw():
	if Engine.is_editor_hint():
		draw_rect(Rect2(-32, -16, 64, 32), Color.ORANGE, false, 2.0)
