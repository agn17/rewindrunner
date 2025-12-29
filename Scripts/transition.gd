extends CanvasLayer

@onready var animation_player = $AnimationPlayer
@onready var color_rect = $ColorRect

func _ready():
	color_rect.visible = false

func fade_out(duration: float = 0.5):
	color_rect.visible = true
	animation_player.speed_scale = 1.0 / duration
	animation_player.play("fade_out")
	await animation_player.animation_finished

func fade_in(duration: float = 0.5):
	animation_player.speed_scale = 1.0 / duration
	animation_player.play("fade_in")
	await animation_player.animation_finished
	color_rect.visible = false
