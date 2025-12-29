extends ColorRect

@onready var shader_material = material as ShaderMaterial
var rewind_intensity = 0.0

func _ready():
	# Make sure we have a material
	if not shader_material:
		print("WARNING: No shader material on RewindOverlay")
		material = ShaderMaterial.new()
		shader_material = material as ShaderMaterial
	
	# Set to fully visible initially (shader handles transparency)
	modulate.a = 1.0

func _process(delta):
	# Find player and check if rewinding
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("is_rewinding"):
		var is_rewinding = player.call("is_rewinding")
		
		# Update shader
		if shader_material:
			shader_material.set_shader_parameter("rewinding", is_rewinding)
			
			# If shader has intensity parameter, update it
			if is_rewinding:
				rewind_intensity = min(rewind_intensity + delta * 5.0, 1.0)
			else:
				rewind_intensity = max(rewind_intensity - delta * 5.0, 0.0)
			
			shader_material.set_shader_parameter("intensity", rewind_intensity)
