extends CanvasLayer

@onready var rewind_label = $container/RewindStatus
@onready var cooldown_bar = $container/Cooldown

var cooldown_timer = 0.0
var rewind_cooldown = 2.0
var can_rewind = true

func _ready():
	# Try to find player and connect
	call_deferred("_setup_player_connection")

func _setup_player_connection():
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	#if player:
		# We'll update via polling instead

func _process(delta):
	# Find player
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Check if player can rewind (simplified)
	if player.has_method("is_rewinding"):
		var rewinding = player.call("is_rewinding")
		
		if rewinding:
			rewind_label.text = "REWINDING..."
			rewind_label.modulate = Color.CYAN
			cooldown_bar.value = 0
			can_rewind = false
			cooldown_timer = 0.0
		else:
			# Handle cooldown
			if not can_rewind:
				cooldown_timer += delta
				cooldown_bar.value = (cooldown_timer / rewind_cooldown) * 100
				
				if cooldown_timer >= rewind_cooldown:
					can_rewind = true
					rewind_label.text = "REWIND READY"
					rewind_label.modulate = Color.WHITE
