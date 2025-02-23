extends Node

@export var left_target_color: Color = Color.RED
@export var right_target_color: Color = Color.BLUE
@export var obstacle_color: Color = Color.ORANGE

@onready var event_index = 0
@onready var audio_player = $AudioStreamPlayer

var scenes = {
	"straight_left": preload("res://blueprints/targets/straight_left_target.tscn"),
	"straight_right": preload("res://blueprints/targets/straight_right_target.tscn"),
	"straight_low_left": preload("res://blueprints/targets/straight_low_left_target.tscn"),
	"straight_low_right": preload("res://blueprints/targets/straight_low_right_target.tscn"),
	"sky_punch_left": preload("res://blueprints/targets/sky_punch_left_target.tscn"),
	"sky_punch_right": preload("res://blueprints/targets/sky_punch_right_target.tscn"),
	"hook_left": preload("res://blueprints/targets/hook_left_target.tscn"),
	"hook_right": preload("res://blueprints/targets/hook_right_target.tscn"),
	"uppercut_left": preload("res://blueprints/targets/uppercut_left_target.tscn"),
	"uppercut_right": preload("res://blueprints/targets/uppercut_right_target.tscn"),
	"rope_slam_left": preload("res://blueprints/targets/rope_slam_left_target.tscn"),
	"rope_slam_right": preload("res://blueprints/targets/rope_slam_right_target.tscn"),
	"knee_top_left": preload("res://blueprints/targets/knee_top_left_target.tscn"),
	"top_wall": preload("res://blueprints/obstacles/top_wall.tscn"),
}

var spawn_events = load_spawn_events_from_json("res://music/yomitan-akane-enma-the-second/enma-the-second.json")

func _physics_process(delta: float) -> void:
	if event_index < spawn_events.size():
		var current_time = audio_player.get_playback_position() + AudioServer.get_time_since_last_mix()
		current_time -= AudioServer.get_output_latency()
		while event_index < spawn_events.size() and current_time >= spawn_events[event_index]["time"] - 4:
			spawn_event(spawn_events[event_index]["scene"])
			event_index += 1

func spawn_event(scene_key):
	var scene = scenes[scene_key]
	var instance = scene.instantiate()
	add_child(instance)
	var mesh = instance.get_node("MeshInstance3D")
	if mesh:
		var mat = mesh.material_override
		if not mat:
			mat = StandardMaterial3D.new()
		else:
			mat = mat.duplicate()
		if (instance.is_in_group("left_target")):
			mat.albedo_color = left_target_color
		elif (instance.is_in_group("right_target")):
			mat.albedo_color = right_target_color
		else:
			mat.albedo_color = obstacle_color
			mat.blend_mode = 1
		mesh.material_override = mat
	instance.apply_impulse(Vector3(0, 0, 2.5))

func load_spawn_events_from_json(file_path: String) -> Array:
	if not FileAccess.file_exists(file_path):
		push_error("File does not exist: " + file_path)
		return []

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(json_text)
	if err != OK:
		push_error("JSON Parse Error: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return []

	return json.data
