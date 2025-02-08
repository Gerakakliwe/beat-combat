extends Node3D

@onready var hit_counter: Label3D = $HitCounter
@onready var velocity_display: Label3D = $VelocityDisplay

var xr_interface: XRInterface
var points: int = 0

func _ready() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true

func _on_player_target_hit() -> void:
	points += 1
	hit_counter.text = str("Combo: ", points)

func _on_player_player_hit() -> void:
	points = 0
	hit_counter.text = str("Combo: ", points)

func _on_player_hit_velocity(linear_velocity: Variant) -> void:
	velocity_display.text = str("Hit velocity: ", snapped(linear_velocity, 0.1))
