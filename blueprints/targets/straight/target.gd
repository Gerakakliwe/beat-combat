extends RigidBody3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var ray_cast_3d: RayCast3D = $RayCast3D

func _on_body_entered(body: Node) -> void:
	print("_on_body_entered AAAAAAA")
