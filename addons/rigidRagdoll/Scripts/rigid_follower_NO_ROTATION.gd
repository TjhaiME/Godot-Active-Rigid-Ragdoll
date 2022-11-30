extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var target = null
var slerpWeight = 0.5

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _integrate_forces(state):
	if target == null:
		return
#	if target.get_is_active() == false:
#		return
	var goalVel = target.global_transform.origin - global_transform.origin
	var newVel = state.linear_velocity.linear_interpolate(goalVel, slerpWeight)
	var strength = 1.2#newVel.length_squared() #2 seems just too fast
	state.linear_velocity = strength*newVel
	#now rotation
#	var goalQuat = Quat(target.global_transform.basis)
#	var oldQuat = Quat(global_transform.basis)
#	var newQuat = oldQuat.slerp(goalQuat, slerpWeight)
#	var newTForm = Transform(newQuat)
	
	#var w = calc_angular_velocity(global_transform.basis, target.global_transform.basis)
	
	# Adjust velocity by simulation timestep
	#state.angular_velocity = w / state.step


#func rigid_follow_target(body, target): #both are node references
#	var vel = target.global_transform.origin - body.global_transform.origin
#	vel *= vel.length_squared()
#	body.add_central_force(20*vel)




func calc_angular_velocity(from_basis: Basis, to_basis: Basis) -> Vector3:
	#https://www.reddit.com/r/godot/comments/q1lawy/basis_and_angular_velocity_question/
	var q1 = from_basis.get_rotation_quat()
	var q2 = to_basis.get_rotation_quat()
	
	# Quaternion that transforms q1 into q2
	var qt = q2 * q1.inverse()
	
	# Angle from quaternion
	var angle = 2 * acos(qt.w)

	# There are two distinct quaternions for any orientation.
	# Ensure we use the representation with the smallest angle.
	if angle > PI:
		qt = -qt
		angle = TAU - angle
	
	# Prevent divide by zero
	if angle < 0.0001:
		return Vector3.ZERO
	
	# Axis from quaternion
	var axis = Vector3(qt.x, qt.y, qt.z) / sqrt(1-qt.w*qt.w)
	
	return axis * angle

#func _integrate_forces(state):
#	var from_basis = ...
#	var to_basis = ...
#
#	var w = calc_angular_velocity(from_basis, to_basis)
#
#	# Adjust velocity by simulation timestep
#	state.angular_velocity = w / state.step
