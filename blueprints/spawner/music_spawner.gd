extends Node

@export var left_target_color: Color = Color.RED
@export var right_target_color: Color = Color.BLUE
@export var knee_instance_color: Color = Color.PURPLE
@export var obstacle_color: Color = Color.ORANGE

@onready var event_index = 0
@onready var audio_player = $AudioStreamPlayer

signal knee_target_spawn(instance)
signal knee_hitzone_spawn(instance)

var scenes: Dictionary = {
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
	"knee_top_left_target": preload("res://blueprints/targets/knee_top_left_target.tscn"),
	"knee_top_left_hitzone": preload("res://blueprints/targets/knee_top_left_hit_zone.tscn"),
	"knee_top_right_target": preload("res://blueprints/targets/knee_top_right_target.tscn"),
	"knee_top_right_hitzone": preload("res://blueprints/targets/knee_top_right_hit_zone.tscn"),
	"knee_diagonal_left_target": preload("res://blueprints/targets/knee_diagonal_left_target.tscn"),
	"knee_diagonal_left_hitzone": preload("res://blueprints/targets/knee_diagonal_left_hit_zone.tscn"),
	"knee_diagonal_right_target": preload("res://blueprints/targets/knee_diagonal_right_target.tscn"),
	"knee_diagonal_right_hitzone": preload("res://blueprints/targets/knee_diagonal_right_hit_zone.tscn"),
	"top_wall": preload("res://blueprints/obstacles/top_wall.tscn"),
	"left_wall": preload("res://blueprints/obstacles/left_angle_wall.tscn"),
	"right_wall": preload("res://blueprints/obstacles/right_angle_wall.tscn"),
}

var spawn_events
var rel_path = "res://projects/kiss-me-saurus.zip"
var zip_path = ProjectSettings.globalize_path(rel_path)

func _ready():
	extract_all_from_zip(zip_path)
	spawn_events = load_json(Global.json_path)
	audio_player.stream = AudioStreamOggVorbis.load_from_file(Global.ogg_path)
	audio_player.play()

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
	setup_instance_material(instance)
	instance.apply_impulse(Vector3(0, 0, 2.5))
	if instance.is_in_group("knee_target"):
		emit_signal("knee_target_spawn", instance)
	if instance.is_in_group("knee_hit_zone"):
		emit_signal("knee_hitzone_spawn", instance)

func setup_instance_material(instance: Node) -> void:
	var mesh: MeshInstance3D = instance.get_node("MeshInstance3D")
	if mesh:
		var mat: Material = mesh.material_override if mesh.material_override else StandardMaterial3D.new()
		mat = mat.duplicate()
		if instance.is_in_group("knee_target") or instance.is_in_group("knee_hit_zone"):
			mat.albedo_color = knee_instance_color
		elif instance.is_in_group("left_target"):
			mat.albedo_color = left_target_color
		elif instance.is_in_group("right_target"):
			mat.albedo_color = right_target_color
		else:
			mat.albedo_color = obstacle_color
			mat.blend_mode = 1
		mesh.material_override = mat

func load_json(file_path: String) -> Array:
	if FileAccess.file_exists(file_path):
		var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
		var json_text: String = file.get_as_text()
		file.close()
		var json: JSON = JSON.new()

		if json.parse(json_text) == OK:
			var data = json.data
			if data is Dictionary:
				var events = data.get("events", [])
				events.sort_custom(func(a, b): return a["time"] < b["time"])
				return events
		return []
	else:
		return []

func extract_all_from_zip(zip_path):
	var reader = ZIPReader.new()
	reader.open(zip_path)

	var extract_dir = zip_path.get_base_dir()
	print(extract_dir)
	var root_dir = DirAccess.open(extract_dir)

	if root_dir == null:
		DirAccess.make_dir_recursive_absolute(extract_dir)
		root_dir = DirAccess.open(extract_dir)

	var files = reader.get_files()
	for file_path in files:
		if file_path.ends_with(".json"):
			Global.json_path = extract_dir.path_join(file_path)
		elif file_path.ends_with(".ogg"):
			Global.ogg_path = extract_dir.path_join(file_path)

		if file_path.ends_with("/"):
			root_dir.make_dir_recursive(file_path)
			continue

		root_dir.make_dir_recursive(root_dir.get_current_dir().path_join(file_path).get_base_dir())
		var file = FileAccess.open(root_dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
		var buffer = reader.read_file(file_path)
		file.store_buffer(buffer)
