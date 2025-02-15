extends Node

@export var left_target_color: Color = Color.RED
@export var right_target_color: Color = Color.BLUE

var scenes = {
	"straight_left": preload("res://blueprints/targets/straight_left_target.tscn"),
	"straight_right": preload("res://blueprints/targets/straight_right_target.tscn"),
	"hook_left": preload("res://blueprints/targets/hook_left_target.tscn"),
	"hook_right": preload("res://blueprints/targets/hook_right_target.tscn"),
	"uppercut_left": preload("res://blueprints/targets/uppercut_left_target.tscn"),
	"uppercut_right": preload("res://blueprints/targets/uppercut_right_target.tscn"),
}

var spawn_events = [
	{"time": 0.91, "scene": "straight_left"},
	{"time": 1.36, "scene": "straight_right"},
	{"time": 1.81, "scene": "uppercut_left"},
	{"time": 2.26, "scene": "hook_right"},
	{"time": 2.71, "scene": "straight_left"},
	{"time": 3.16, "scene": "straight_right"},
	{"time": 3.61, "scene": "hook_left"},
	{"time": 4.06, "scene": "uppercut_right"},
	{"time": 4.51, "scene": "straight_left"},
	{"time": 4.96, "scene": "straight_right"},
	{"time": 5.41, "scene": "uppercut_left"},
	{"time": 5.86, "scene": "hook_right"},
	{"time": 6.31, "scene": "straight_left"},
	{"time": 6.76, "scene": "straight_right"},
	{"time": 7.21, "scene": "hook_left"},
	{"time": 7.66, "scene": "uppercut_right"},
]

@onready var event_index = 0
@onready var audio_player = $AudioStreamPlayer

func _process(delta):
	if event_index < spawn_events.size():
		var current_time = audio_player.get_playback_position()
		while event_index < spawn_events.size() and current_time >= spawn_events[event_index]["time"]:
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
		if (instance.is_in_group("left_targets")):
			mat.albedo_color = left_target_color
		else:
			mat.albedo_color = right_target_color
		mesh.material_override = mat
	instance.apply_impulse(Vector3(0, 0, 2.5))
