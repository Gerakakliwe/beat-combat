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

signal target_hit(points_awarded)
signal hit_velocity(velocity_vector)
signal obstacle_hit
signal wrong_target_hit

class SmoothedVelocity:
	var previous_position: Vector3
	var history: Array[Vector3] = []
	var smoothing_frames: int

	func _init(initial_position: Vector3, smoothing_frames: int) -> void:
		previous_position = initial_position
		self.smoothing_frames = smoothing_frames

	func update(current_position: Vector3, delta: float) -> Vector3:
		var inst_velocity = (current_position - previous_position) / delta
		previous_position = current_position
		history.append(inst_velocity)
		if history.size() > smoothing_frames:
			history.remove_at(0)
		var sum: Vector3 = Vector3.ZERO
		for v in history:
			sum += v
		return sum / history.size()

const SMOOTHING_FRAMES = 4

var left_velocity_tracker: SmoothedVelocity
var right_velocity_tracker: SmoothedVelocity
var left_velocity_mean: Vector3
var right_velocity_mean: Vector3

var pending_knee_target: Node3D = null    # When one controller first collides with a knee target.
var active_knee_target: Node3D = null     # Once both controllers have touched the same knee target.
var knee_strike_in_progress: bool = false
var active_knee_hit_zone: Array[Node3D] = []
var HIP_LEVEL_Y: float = 1.3

func _ready() -> void:
	left_velocity_tracker = SmoothedVelocity.new(controller_left.global_transform.origin, SMOOTHING_FRAMES)
	right_velocity_tracker = SmoothedVelocity.new(controller_right.global_transform.origin, SMOOTHING_FRAMES)

func _physics_process(delta: float) -> void:
	left_velocity_mean = left_velocity_tracker.update(controller_left.global_transform.origin, delta)
	right_velocity_mean = right_velocity_tracker.update(controller_right.global_transform.origin, delta)

	check_head_rays()

	if knee_strike_in_progress and active_knee_target:
		var mid_point: Vector3 = (controller_left.global_transform.origin + controller_right.global_transform.origin) / 2
		active_knee_target.global_transform.origin = mid_point

		if mid_point.y < HIP_LEVEL_Y:
			var avg_downward_velocity = ((left_velocity_mean.y + right_velocity_mean.y) / 2)
			var points_awarded = get_points_for_axis(abs(avg_downward_velocity), 3.0)
			emit_signal("target_hit", points_awarded)

			controller_left.trigger_haptic_pulse("haptic", 0.0, 0.8, 0.1, 0.0)
			controller_right.trigger_haptic_pulse("haptic", 0.0, 0.8, 0.1, 0.0)

			active_knee_target.queue_free()
			if !active_knee_hit_zone.is_empty():
				active_knee_hit_zone[0].queue_free()
				active_knee_hit_zone.remove_at(0)
			reset_knee_strike_state()

func check_head_rays() -> void:
	for ray in head_rays:
		if ray.is_colliding():
			controller_left.trigger_haptic_pulse("haptic", 0.0, 0.8, 0.1, 0.0)
			controller_right.trigger_haptic_pulse("haptic", 0.0, 0.8, 0.1, 0.0)
			emit_signal("obstacle_hit")

func _on_left_hit_area_body_entered(body: Node3D) -> void:
	_on_hit_area_body_entered(body, "left")

func _on_right_hit_area_body_entered(body: Node3D) -> void:
	_on_hit_area_body_entered(body, "right")

func _on_hit_area_body_entered(body: Node3D, hand: String) -> void:
	if body.is_in_group("knee_target"):
		handle_knee_target_collision(body)
		return

	play_hit_sound(body.global_position, 0.5)

	var velocity_mean: Vector3
	var controller: XRController3D
	if hand == "left":
		velocity_mean = left_velocity_mean
		controller = controller_left
	else:
		velocity_mean = right_velocity_mean
		controller = controller_right

	var points_awarded: int = 0
	if body.is_in_group(hand + "_target"):
		if body.is_in_group("z_target"):
			points_awarded = get_points_for_axis(abs(velocity_mean.z), 3.0)
		elif body.is_in_group("x_target"):
			points_awarded = get_points_for_axis(abs(velocity_mean.x), 4.0)
		elif body.is_in_group("y_target"):
			points_awarded = get_points_for_axis(abs(velocity_mean.y), 4.0)
		else:
			points_awarded = 0

		body.queue_free()
		controller.trigger_haptic_pulse("haptic", 0.0, 0.5, 0.1, 0.0)
		emit_signal("hit_velocity", velocity_mean)
		if points_awarded > 0:
			emit_signal("target_hit", points_awarded)
		else:
			emit_signal("wrong_target_hit")
	else:
		emit_signal("wrong_target_hit")


func play_hit_sound(position: Vector3, volume: float = 1.0) -> void:
	var audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = preload("res://sounds/punch.ogg")
	audio_player.transform.origin = position
	audio_player.autoplay = false
	audio_player.volume_db = linear_to_db(clamp(volume, 0.0, 1.0))
	audio_player.unit_size = 1.0
	get_tree().current_scene.add_child(audio_player)
	audio_player.play()

	var timer = Timer.new()
	timer.wait_time = audio_player.stream.get_length()
	timer.one_shot = true
	timer.connect("timeout", Callable(audio_player, "queue_free"))
	audio_player.add_child(timer)
	timer.start()

func handle_knee_target_collision(body: Node3D) -> void:
	if pending_knee_target == null:
		pending_knee_target = body
	else:
		# If the pending knee target is the same as this body and the knee strike isn’t already active,
		# then both controllers have touched it—start the knee strike.
		if pending_knee_target == body and not knee_strike_in_progress:
			controller_left.trigger_haptic_pulse("haptic", 0.0, 0.8, 0.1, 0.0)
			controller_right.trigger_haptic_pulse("haptic", 0.0, 0.8, 0.1, 0.0)
			active_knee_target = body
			knee_strike_in_progress = true
			body.get_parent().remove_child(body)
			add_child(body)

func reset_knee_strike_state() -> void:
	pending_knee_target = null
	active_knee_target = null
	knee_strike_in_progress = false

func cancel_knee_strike() -> void:
	if active_knee_target:
		active_knee_target.queue_free()
	if !active_knee_hit_zone.is_empty():
		active_knee_hit_zone[0].queue_free()
		active_knee_hit_zone.remove_at(0)
	reset_knee_strike_state()

func get_points_for_axis(velocity_component: float, base: float) -> int:
	if velocity_component >= base:
		return 1000
	elif velocity_component >= 0.9 * base:
		return 500
	elif velocity_component >= 0.8 * base:
		return 100
	else:
		return 0

func _on_music_spawner_knee_hitzone_spawn(instance: Variant) -> void:
	active_knee_hit_zone.append(instance)
