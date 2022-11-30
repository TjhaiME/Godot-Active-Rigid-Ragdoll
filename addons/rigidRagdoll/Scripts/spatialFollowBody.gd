extends Spatial

#follow the hips without rotating



var followNode = null
var floor_close = false
var floor_normal = Vector3(0,1,0)

func _physics_process(delta):
#	if floor_close == false:
#		global_transform.origin = followNode.global_transform.origin
#	else:
	var xForm = Transform(followNode.global_transform.basis, followNode.global_transform.origin)
	global_transform = align_with_normal(xForm, floor_normal)

func align_with_normal(xForm, newNormal):
	xForm.basis.y = newNormal
	xForm.basis.x = xForm.basis.z.cross(newNormal)
	xForm.basis = xForm.basis.orthonormalized()
#	rotate_y(default_rotation_radians.y)
#	rotate_z(default_rotation_radians.z)
#	rotate_x(default_rotation_radians.x)
	return xForm
