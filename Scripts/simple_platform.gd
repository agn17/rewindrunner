extends StaticBody2D

@onready var sprite = $Sprite2D

var lifetime = 3.0

func _ready():
	# Ensure visible
	visible = true
	sprite.visible = true
	
	# Set a clear color
	sprite.modulate = Color(0.3, 0.5, 1.0, 0.8)  # Semi-transparent blue
	
	# Create a simple texture if none exists
	if sprite.texture == null:
		print("Creating placeholder texture for platform")
		# You can also use the Godot icon as placeholder
		sprite.texture = load("res://icon.svg")
		sprite.scale = Vector2(2, 2)
	
	# Simple fade in
	sprite.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.8, 0.3)
	
	# Auto-remove after lifetime
	$Timer.wait_time = lifetime
	$Timer.start()
	
	print("✅ Platform created at: ", global_position)

func _on_timer_timeout():
	# Simple fade out
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
	print("Platform faded out")
