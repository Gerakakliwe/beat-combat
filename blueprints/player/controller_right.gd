extends XRController3D

@onready var ray_cast_right: RayCast3D = $RightPhysicsHand/RayCastRight

func _process(delta: float) -> void:
	if ray_cast_right.is_colliding():
		print("controller right RIGHT YEAH")
		var target = ray_cast_right.get_collider()
		if (target):
			target.free()
