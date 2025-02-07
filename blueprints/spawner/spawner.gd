extends Node3D

@export var rigid_box_scene: PackedScene
@export var spawn_place: Vector3
@export var spawn_delay: float

func _ready():
	await get_tree().create_timer(spawn_delay).timeout
	$SpawnTimer.start()

func _on_spawn_timer_timeout() -> void:
	var rigid_box_instance = rigid_box_scene.instantiate()
	get_tree().root.add_child(rigid_box_instance)
	rigid_box_instance.global_transform.origin = global_transform.origin + spawn_place
	rigid_box_instance.apply_impulse(Vector3(0, 0, 10))
