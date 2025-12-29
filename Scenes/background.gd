# Add this script to Background TextureRect:
extends TextureRect

func _ready():
	# Create gradient background
	var gradient = Gradient.new()
	gradient.colors = [Color("#0a0a2a"), Color("#1a1a4a"), Color("#0a0a2a")]
	gradient.offsets = [0.0, 0.5, 1.0]
	
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 1280
	gradient_texture.height = 720
	
	texture = gradient_texture
