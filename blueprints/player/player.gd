extends XROrigin3D

# Helper class to smooth velocity over several frames.
class SmoothedVelocity:
	var previous_position: Vector3
	var history: Array[Vector3] = []
	var smoothing_frames: int

	func _init(initial_position: Vector3, smoothing_frames: int) -> void:
		previous_position = initial_position
		self.smoothing_frames = smoothing_frames

	func update(current_position: Vector3, delta: float) -> Vector3:
		# Calculate instantaneous velocity.
		var inst_velocity = (current_position - previous_position) / delta
		previous_position = current_position
		# Add it to history.
		history.append(inst_velocity)
		if history.size() > smoothing_frames:
			history.remove_at(0)
		# Average the history.
		var sum: Vector3 = Vector3.ZERO
		for v in history:
			sum += v
		return sum / history.size()


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
signal hit_velocity(velocity_vector)
signal obstacle_hit
signal wrong_target_hit

const SMOOTHING_FRAMES = 4

var left_velocity_tracker: SmoothedVelocity
var right_velocity_tracker: SmoothedVelocity
var left_velocity_mean: Vector3
var right_velocity_mean: Vector3

func _ready() -> void:
	# Initialize each tracker with the current global origin.
	left_velocity_tracker = SmoothedVelocity.new(controller_left.global_transform.origin, SMOOTHING_FRAMES)
	right_velocity_tracker = SmoothedVelocity.new(controller_right.global_transform.origin, SMOOTHING_FRAMES)

func _physics_process(delta: float) -> void:
	# Update the left and right velocity trackers.
	left_velocity_mean = left_velocity_tracker.update(controller_left.global_transform.origin, delta)
	right_velocity_mean = right_velocity_tracker.update(controller_right.global_transform.origin, delta)

	# Check for head collisions.
	for head_ray in head_rays:
		if head_ray.is_colliding():
			emit_signal("obstacle_hit")

func _on_left_hit_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("left_targets"):
		body.free()
		controller_left.trigger_haptic_pulse("haptic", 0.0, 0.5, 0.1, 0.0)
		emit_signal("hit_velocity", left_velocity_mean)
		emit_signal("target_hit")
	else:
		body.free()
		emit_signal("wrong_target_hit")

func _on_right_hit_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("right_targets"):
		body.free()
		controller_right.trigger_haptic_pulse("haptic", 0.0, 0.5, 0.1, 0.0)
		emit_signal("hit_velocity", right_velocity_mean)
		emit_signal("target_hit")
	else:
		body.free()
		emit_signal("wrong_target_hit")
