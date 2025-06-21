extends Node

@export var left_target_color: Color = Color.RED
@export var right_target_color: Color = Color.BLUE
@export var knee_instance_color: Color = Color.PURPLE
@export var obstacle_color: Color = Color.ORANGE

@onready var event_index = 0
@onready var audio_player = $AudioStreamPlayer

signal knee_target_spawn(instance)
signal knee_hitzone_spawn(instance)
signal start_video

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
var knee_pairs: Array = []
var knee_strikes: Array[Node3D] = []

var beam_scene = preload("res://blueprints/connector/beam.tscn")
var active_beams = []

var game_time := 0.0
var song_started := false

var base_height = 185

func _ready():
	_warmup_beam()
	extract_all_from_zip(Global.zip_path)
	spawn_events = load_json(Global.json_path)
	audio_player.stream = AudioStreamOggVorbis.load_from_file(Global.ogg_path)

func _warmup_beam():
	var dummy = beam_scene.instantiate()
	dummy.visible = false
	add_child(dummy)
	await get_tree().process_frame
	dummy.queue_free()

func _physics_process(delta: float) -> void:
	game_time += delta
	if not song_started and game_time >= 4 - 0.01:
		var overshoot = game_time - 4
		audio_player.play()
		song_started = true
		emit_signal("start_video")

	if event_index < spawn_events.size():
		var current_time = game_time
		while event_index < spawn_events.size() and current_time >= spawn_events[event_index]["time"]:
			spawn_event(spawn_events[event_index]["scene"])
			event_index += 1

func spawn_event(scene_key):
	var scene = scenes[scene_key]
	var instance = scene.instantiate()
	add_child(instance)
	setup_instance_material(instance)
	instance.apply_impulse(Vector3(0, 0, 2.5))

	var height_ratio = Global.player_height / base_height
	var current_transform = instance.global_transform
	current_transform.origin.y *= height_ratio
	instance.global_transform = current_transform

	if instance.is_in_group("knee_target"):
		knee_strikes.append(instance)
	if instance.is_in_group("knee_hit_zone"):
		emit_signal("knee_hitzone_spawn", instance)
		add_knee_pair(knee_strikes[-1], instance)
		print("pairs " + str(knee_pairs))

func add_knee_pair(target: Node3D, hitzone: Node3D) -> void:
	knee_pairs.append({ "target": target, "hitzone": hitzone })
	var beam = beam_scene.instantiate()
	beam.target_a = target
	beam.target_b = hitzone
	add_child(beam)
	active_beams.append(beam)

func remove_knee_pair(index: int) -> void:
	if index >= 0 and index < knee_pairs.size():
		knee_pairs.remove_at(index)

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
	var err = reader.open(zip_path)
	if err != OK:
		push_error("Failed to open ZIP file: " + zip_path)
		return

	print("ZIP file opened successfully.")

	var extract_dir = "user://unzipped_content"
	print("Extract directory:", extract_dir)

	DirAccess.make_dir_recursive_absolute(extract_dir)
	var root_dir = DirAccess.open(extract_dir)
	if root_dir == null:
		push_error("Failed to access extract directory after creation.")
		return

	var files = reader.get_files()
	print("Files found in ZIP:", files)

	for file_path in files:
		print("Processing file:", file_path)

		if file_path.ends_with("/"):
			print("Creating directory:", file_path)
			root_dir.make_dir_recursive(file_path)
			continue

		var full_path = extract_dir.path_join(file_path)
		var dir_path = full_path.get_base_dir()
		print("Ensuring directory exists for file:", dir_path)
		DirAccess.make_dir_recursive_absolute(dir_path)

		var file = FileAccess.open(full_path, FileAccess.WRITE)
		if file == null:
			push_error("Failed to open file for writing: " + full_path)
			continue

		print("Writing file:", full_path)
		var buffer = reader.read_file(file_path)
		file.store_buffer(buffer)

		if file_path.ends_with(".json"):
			Global.json_path = full_path
			print("Found JSON file. Global.json_path set to:", Global.json_path)
		elif file_path.ends_with(".ogg"):
			Global.ogg_path = full_path
			print("Found OGG file. Global.ogg_path set to:", Global.ogg_path)
		elif file_path.ends_with(".ogv"):
			Global.ogv_path = full_path
			print("Found OGV file. Global.ogv_path set to:", Global.ogv_path)
