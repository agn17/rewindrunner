extends LevelBase

@onready var tutorial_signs = $TutorialSigns
@onready var platforms = $Platforms

func _ready():
	super._ready()  # Call parent _ready
	
	# Create tutorial platforms
	create_tutorial_platforms()
	
	# Create tutorial signs
	create_tutorial_signs()

func create_tutorial_platforms():
	# Ground
	var ground = create_platform(Vector2(400, 550), 800, 100, Color.DARK_GRAY)
	ground.name = "Ground"
	platforms.add_child(ground)
	
	# First small gap (can jump normally)
	create_platform(Vector2(200, 450), 200, 30, Color.GRAY)
	create_platform(Vector2(500, 450), 200, 30, Color.GRAY)
	
	# Second larger gap (need rewind)
	create_platform(Vector2(150, 350), 150, 30, Color.LIGHT_BLUE)
	create_platform(Vector2(450, 350), 150, 30, Color.LIGHT_BLUE)

func create_tutorial_signs():
	# Movement sign
	var move_sign = create_sign(Vector2(200, 300), "A/D or ARROWS to move")
	tutorial_signs.add_child(move_sign)
	
	# Jump sign
	var jump_sign = create_sign(Vector2(300, 250), "SPACE to jump")
	tutorial_signs.add_child(jump_sign)
	
	# Rewind sign (before gap)
	var rewind_sign = create_sign(Vector2(150, 200), "Hold SHIFT to rewind\ntime if you fall!")
	tutorial_signs.add_child(rewind_sign)

func create_sign(position: Vector2, text: String) -> Node2D:
	var sign_node = Node2D.new()
	sign_node.position = position
	
	# Sign background
	var sprite = Sprite2D.new()
	var texture = create_color_texture(Color(0.3, 0.3, 0.3, 0.8), 200, 60)
	sprite.texture = texture
	sign_node.add_child(sprite)
	
	# Text label
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 16)
	label.position = Vector2(-90, -25)
	label.size = Vector2(180, 50)
	sign_node.add_child(label)
	
	return sign_node
