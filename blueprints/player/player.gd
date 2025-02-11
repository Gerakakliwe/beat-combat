extends XROrigin3D

@onready var ray_mf: RayCast3D = $XRCamera3D/RayMF
@onready var ray_ml: RayCast3D = $XRCamera3D/RayML
@onready var ray_mr: RayCast3D = $XRCamera3D/RayMR
@onready var ray_tl: RayCast3D = $XRCamera3D/RayTL
@onready var ray_tt: RayCast3D = $XRCamera3D/RayTT
@onready var ray_tr: RayCast3D = $XRCamera3D/RayTR
@onready var head_rays: Array[RayCast3D] = [ray_mf, ray_ml, ray_mr, ray_tl, ray_tt, ray_tr]

@onready var controller_left: XRController3D = $Controller_Left
@onready var controller_right: XRController3D = $Controller_Right

signal target_hit
signal hit_velocity(linear_velocity)
signal player_hit

var left_previous_position: Vector3
var left_current_velocity: float = 0.0
var right_previous_position: Vector3
var right_current_velocity: float = 0.0

func _ready() -> void:
	left_previous_position = global_transform.origin
	right_previous_position = global_transform.origin

func _physics_process(delta: float) -> void:
	var left_current_position = controller_left.global_transform.origin
	left_current_velocity = (left_current_position - left_previous_position).length() / delta
	left_previous_position = left_current_position

	var right_current_position = controller_right.global_transform.origin
	right_current_velocity = (right_current_position - right_previous_position).length() / delta
	right_previous_position = right_current_position

	for head_ray in head_rays:
		if head_ray.is_colliding():
			emit_signal("player_hit")

func _on_left_hit_area_body_entered(body: Node3D) -> void:
	body.free()
	controller_left.trigger_haptic_pulse("haptic", 0.0, 0.5, 0.1, 0.0)
	emit_signal("hit_velocity", left_current_velocity)
	emit_signal("target_hit")

func _on_right_hit_area_body_entered(body: Node3D) -> void:
	body.free()
	controller_right.trigger_haptic_pulse("haptic", 0.0, 0.5, 0.1, 0.0)
	emit_signal("hit_velocity", right_current_velocity)
	emit_signal("target_hit")
