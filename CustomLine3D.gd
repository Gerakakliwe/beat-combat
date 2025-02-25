class_name CustomLine3D
extends MeshInstance3D

var start: Vector3 = Vector3.ZERO
var end: Vector3 = Vector3.ZERO
var line_color: Color = Color.RED
var radius: float = 0.03
var cylinder_mesh: CylinderMesh
var material: StandardMaterial3D

func _ready():
	cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = 1
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.top_radius = radius
	material = StandardMaterial3D.new()
	material.albedo_color = line_color
	self.mesh = cylinder_mesh
	self.material = material

func update_line() -> void:
	if start == end:
		self.visible = false
		return
	self.visible = true
	var direction = end - start
	var h = direction.length()
	if h == 0:
		return
	var y = direction / h
	var x = Vector3(1,0,0)
	if x.dot(y) > 0.999 or x.dot(y) < -0.999:
		x = Vector3(0,1,0)
	if x.dot(y) > 0.999 or x.dot(y) < -0.999:
		x = Vector3(0,0,1)
	var z = y.cross(x).normalized()
	x = z.cross(y).normalized()
	self.position = (start + end) / 2
	self.basis = Basis(x, y, z)
	self.scale = Vector3(1, h, 1)
	material.albedo_color = line_color

func _process(delta: float) -> void:
	update_line()
