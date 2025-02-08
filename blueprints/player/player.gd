extends XROrigin3D

@onready var ray_lt_1: RayCast3D = $Controller_Left/LeftPhysicsHand/RayLT1
@onready var ray_lt_2: RayCast3D = $Controller_Left/LeftPhysicsHand/RayLT2
@onready var ray_lt_3: RayCast3D = $Controller_Left/LeftPhysicsHand/RayLT3
@onready var ray_lm_1: RayCast3D = $Controller_Left/LeftPhysicsHand/RayLM1
@onready var ray_lm_2: RayCast3D = $Controller_Left/LeftPhysicsHand/RayLM2
@onready var ray_lm_3: RayCast3D = $Controller_Left/LeftPhysicsHand/RayLM3
@onready var ray_lb_1: RayCast3D = $Controller_Left/LeftPhysicsHand/RayLB1
@onready var ray_lb_2: RayCast3D = $Controller_Left/LeftPhysicsHand/RayLB2
@onready var ray_lb_3: RayCast3D = $Controller_Left/LeftPhysicsHand/RayLB3
@onready var left_rays: Array[RayCast3D] = [ray_lm_1, ray_lm_2, ray_lm_3, ray_lt_1, ray_lt_2, ray_lt_3, ray_lb_1, ray_lb_2, ray_lb_3]

@onready var ray_rt_1: RayCast3D = $Controller_Right/RightPhysicsHand/RayRT1
@onready var ray_rt_2: RayCast3D = $Controller_Right/RightPhysicsHand/RayRT2
@onready var ray_rt_3: RayCast3D = $Controller_Right/RightPhysicsHand/RayRT3
@onready var ray_rm_1: RayCast3D = $Controller_Right/RightPhysicsHand/RayRM1
@onready var ray_rm_2: RayCast3D = $Controller_Right/RightPhysicsHand/RayRM2
@onready var ray_rm_3: RayCast3D = $Controller_Right/RightPhysicsHand/RayRM3
@onready var ray_rb_1: RayCast3D = $Controller_Right/RightPhysicsHand/RayRB1
@onready var ray_rb_2: RayCast3D = $Controller_Right/RightPhysicsHand/RayRB2
@onready var ray_rb_3: RayCast3D = $Controller_Right/RightPhysicsHand/RayRB3
@onready var right_rays: Array[RayCast3D] = [ray_rm_1, ray_rm_2, ray_rm_3, ray_rt_1, ray_rt_2, ray_rt_3, ray_rb_1, ray_rb_2, ray_rb_3]

@onready var ray_mf: RayCast3D = $XRCamera3D/RayMF
@onready var ray_ml: RayCast3D = $XRCamera3D/RayML
@onready var ray_mr: RayCast3D = $XRCamera3D/RayMR
@onready var ray_tl: RayCast3D = $XRCamera3D/RayTL
@onready var ray_tt: RayCast3D = $XRCamera3D/RayTT
@onready var ray_tr: RayCast3D = $XRCamera3D/RayTR
@onready var head_rays: Array[RayCast3D] = [ray_mf, ray_ml, ray_mr, ray_tl, ray_tt, ray_tr]

signal target_hit
signal player_hit

func _process(delta: float) -> void:
	for left_ray in left_rays:
		if left_ray.is_colliding():
			print("controller left collision")
			var target = left_ray.get_collider()
			if(target):
				target.free()
				emit_signal("target_hit")
			
	for right_ray in right_rays:
		if right_ray.is_colliding():
			print("controller left collision")
			var target = right_ray.get_collider()
			if(target):
				target.free()
				emit_signal("target_hit")
	
	for head_ray in head_rays:
		if head_ray.is_colliding():
			emit_signal("player_hit")
