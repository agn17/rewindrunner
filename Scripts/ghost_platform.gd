extends StaticBody2D

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

var lifetime = 3.5
var time_alive = 0.0

func _ready():
	# Animate appearance
	scale = Vector2(0.8, 0.8)
	modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	tween.parallel().tween_property(sprite, "modulate:a", 0.7, 0.3)
	
	# Start lifetime timer
	$Timer.wait_time = lifetime
	$Timer.start()

func _process(delta):
	time_alive += delta
	
	# Pulse effect when about to disappear
	if time_alive > lifetime * 0.7:
		var pulse = sin(time_alive * 10.0) * 0.2 + 0.8
		sprite.modulate.a = 0.7 * pulse

func _on_timer_timeout():
	# Fade out before removing
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
