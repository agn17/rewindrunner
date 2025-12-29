extends Node2D

@onready var sprite = $Sprite2D  # Changed from animated_sprite
var lifetime = 1.0

func _ready():
	if not sprite:
		print("ERROR: Sprite2D not found in Ghost!")
		queue_free()
		return
	
	# Set a default blue color
	sprite.modulate = Color(0.5, 0.7, 1.0, 0.6)
	
	# Fade out over time
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, lifetime)
	tween.tween_callback(queue_free)
	
	# Start timer
	$Timer.wait_time = lifetime
	$Timer.start()

# Remove set_animation function since Sprite2D doesn't have animations
# Or keep it if you want to set texture:
func set_texture(texture: Texture2D):
	if sprite:
		sprite.texture = texture

func _on_timer_timeout():
	queue_free()
