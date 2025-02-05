extends XRController3D

@onready var ray_cast_left: RayCast3D = $LeftPhysicsHand/RayCastLeft

func _process(delta: float) -> void:
	if ray_cast_left.is_colliding():
		print("controller left LEFT YEAH")
		var target = ray_cast_left.get_collider()
		if(target):
			target.free()
