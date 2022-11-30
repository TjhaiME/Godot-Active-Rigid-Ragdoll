extends RigidBody


# Declare member variables here. Examples:
var change_grav_scale = false
var new_gravity_scale = 1

#this all does nothigng hahah

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
var fallenThreshold = 0.2
var fallingThreshold = 0.7

var state = 0

var stateDic = {
	0 : "standing",
	1 : "falling",
	2 : "fallen",
}

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
#	#check if we are falling
#	var hipsAngle = global_transform.basis.y.dot(Vector3(0,1,0))
#	if hipsAngle < fallenThreshold:
#		state = 2
#		pass#we have fallenOver
#	elif hipsAngle < fallingThreshold:
#		state = 1
#		pass#we are falling
#	else:
#		state = 0
#		pass#we are at an acceptable hip rotation
#	print("state = ", stateDic[state])
#	if state == 0:
#		return
#	elif state == 1:
#		if gravity_scale == -0.5:
#			return
#		new_gravity_scale = -0.5
#		change_grav_scale = true
#	elif state == 2:
#		if gravity_scale == -1:
#			return
#		new_gravity_scale = -1
#		change_grav_scale = true

var stabilise = false
var stop_speed = 0.85

func _integrate_forces(state):
	
	if change_grav_scale:
		gravity_scale = new_gravity_scale
		change_grav_scale = false
	
	if stabilise == true:
		#we need to resist forces
		state.linear_velocity.x = lerp(state.linear_velocity.x,0,stop_speed)
		state.linear_velocity.z = lerp(state.linear_velocity.z,0,stop_speed)
		state.angular_velocity.x = lerp(state.angular_velocity.x,0,stop_speed)
		state.angular_velocity.y = lerp(state.angular_velocity.y,0,stop_speed)
		state.angular_velocity.z = lerp(state.angular_velocity.z,0,stop_speed)
	
