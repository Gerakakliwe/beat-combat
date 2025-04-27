extends Node3D

@export var target_a: Node3D
@export var target_b: Node3D
@onready var beam_mesh = $MeshInstance3D # Reference to your child mesh

func _process(delta):
	if !is_instance_valid(target_a) or !is_instance_valid(target_b):
		visible = false
		return

	visible = true
	var a = target_a.global_transform.origin
	var b = target_b.global_transform.origin
	var direction = b - a
	var distance = direction.length()
	global_transform.origin = (a + b) * 0.5
	look_at(b, Vector3.UP)
	rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
	beam_mesh.scale = Vector3(1, distance * 0.5, 1)
