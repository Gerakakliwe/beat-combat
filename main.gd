extends Node3D

@onready var hit_counter: Label3D = $HitCounter

var xr_interface: XRInterface
var points: int = 0

func _ready() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
		

func _on_player_target_hit() -> void:
	points += 1
	hit_counter.text = str(points)
