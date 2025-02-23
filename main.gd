extends Node3D

@onready var hit_counter: Label3D = $HitCounter
@onready var velocity_display: Label3D = $VelocityDisplay
@onready var miss_zone: Area3D = $MissZone
@onready var player: XROrigin3D = $Player

var xr_interface: XRInterface
var points: int = 0
var combo: int = 0

func _ready() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true

func _on_player_target_hit(points_awarded: int) -> void:
	points += points_awarded
	combo +=1
	update_results()

func _on_player_obstacle_hit() -> void:
	combo = 0
	update_results()

func _on_player_wrong_target_hit() -> void:
	combo = 0
	update_results()

func _on_player_hit_velocity(velocity_vector: Variant) -> void:
	velocity_display.text = str("X: " + str(snapped(velocity_vector.x, 0.1)) + "\n" +
								"Y: " + str(snapped(velocity_vector.y, 0.1)) + "\n" +
								"Z: " + str(snapped(velocity_vector.z, 0.1)))


func _on_miss_zone_body_entered(body: Node3D) -> void:
	if body.is_in_group("knee_hit_zone"):
		if player and player.has_method("cancel_knee_strike"):
			player.cancel_knee_strike()
			combo = 0
			update_results()
	if body.is_in_group("left_target") or body.is_in_group("right_target"):
		combo = 0
		update_results()
	body.free()

func update_results():
	hit_counter.text = "Combo: " + str(combo) + "\nPoints: " + str(points)
