extends Area2D

func _on_body_entered(body):
	if body.name == "Player":
		print("LEVEL COMPLETE!")
		# Make it obvious
		$Sprite2D.modulate = Color.YELLOW
		
		# Simple win - we'll improve tomorrow
		get_tree().change_scene_to_file("res://Scenes/Credits.tscn")
