extends Node3D

@export var target_scene: PackedScene
@export var spawn_place: Vector3
@export var spawn_delay: float

func _ready():
	await get_tree().create_timer(spawn_delay).timeout
	$SpawnTimer.start()

func _on_spawn_timer_timeout() -> void:
	var target_instance = target_scene.instantiate()
	get_tree().root.add_child(target_instance)
	target_instance.global_transform.origin = global_transform.origin + spawn_place
	target_instance.apply_impulse(Vector3(0, 0, 5))
