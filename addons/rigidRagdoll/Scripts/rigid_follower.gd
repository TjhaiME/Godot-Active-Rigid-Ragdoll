extends RigidBody

#TODO:
#When I have a static object grabbed and my hand is jointed to a wall, 
#I want pushing the controller under the hand to make my body lift up
#we can currrently climb down things and possibly across (more difficult in forwards direction)
#we cannot climb up because our arms wont go that far because our body wont go that far

func lift_body_when_wall_grabbed(delta):
	
	#FIX Doesnt workl with left hanbd for some reason
	
	print("trying to lift")
#	#	if linear_velocity > threshold:
#	#		#and
#	#		if linear_velocity is in the right direction, relative to body:
#	#			#we are pushing down with the controller relative to the body and the current hand p-osition
#	#			#we could make it only work if trigger is held too
#	#			pass
	
	
	
	#if controller is underneath (relative to the body) handPos when something is grabbed
	#it means we are trying to push up
	#we need to lift the body (probs through hips or capsuleBase) so that the controller
	#is moved close to the hand (so the effect stops itself)
	
	#we need to do this with a strength proportional to the distance to the controller
	
	var skelRagdoll = get_parent()
	var hips = skelRagdoll.get_node("mixamorig_Hips")
	#var baseBody = skelRagdoll.get_node("mixamorig_Hips")
	var upDir = hips.global_transform.basis.y
	
	var handPos = global_transform.origin
	var contPos = target.global_transform.origin
	
	#is contPos lower than handPos
	#probs use projecions proj w on v = w.v/v^3 * v
	var handProjMag = handPos.dot(upDir)
	var contProjMag = contPos.dot(upDir)
	if contProjMag < handProjMag:
		print("cont is loiwer than hand")
		#I think this would mean controller is lower than hand
		var distance = handProjMag - contProjMag #which is positive in this if statement
		var strengthMod = 500.0 #500 is alright, I could decrease it and increase distance insteads
		hips.apply_central_impulse(strengthMod*distance*hips.mass*delta*upDir)
	





# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var target = null
var slerpWeight = 0.5
var original_spatial_transform
var original_spatial_basis_inverse
var original_linear_damp = -1

#var holding_item = false
var held_item = null
var side = "right"

# Called when the node enters the scene tree for the first time.
func _ready():
	if name == "mixamorig_LeftHand":
		side = "left"
	#print("side = ", side, " name = ", name, " self.name = ", self.name)
	original_spatial_transform = $Spatial.transform
	original_spatial_basis_inverse = $Spatial.transform.basis.inverse()
	original_linear_damp = linear_damp
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.


func _physics_process(delta):
	if target == null:
		return
	if target.get_is_active() == false:
		return
	rumble_process()
#	var goalVel = target.global_transform.origin - global_transform.origin
#	var newVel = goalVel
#	#var newVel = linear_velocity.linear_interpolate(goalVel, slerpWeight)
#	var strength = 45.0*mass #was 45 with damping, 35 worked better 25.0 seemed to be working#newVel.length_squared() #2 seems just too fast
#	#strength = (goalVel.length()*35+5)*mass
#	var forceVec = strength*newVel*delta
#	apply_central_impulse(forceVec)
	#custom_dampened_force(delta)
	#custom_dampened_force_2(delta)
	custom_dampened_force_2_3(delta)
	#apply_torque_toward_controller_velocity(delta)
	
	var capBase = get_parent().get_node("capsuleBase")
	if capBase.grabbingStaticObj[side] == true:
		lift_body_when_wall_grabbed(delta)

func custom_dampened_force(delta):
	var goalVel = target.global_transform.origin - global_transform.origin
	var newVel = goalVel
	#var newVel = linear_velocity.linear_interpolate(goalVel, slerpWeight)
	var strength = 35.5*mass#37.5*mass #was 45 with damping, 35 worked better 25.0 seemed to be working#newVel.length_squared() #2 seems just too fast
	#strength = (goalVel.length()*35+5)*mass
	
	#var goalVel = target.global_transform.origin - global_transform.origin
	var myVel = linear_velocity
	var dotProd = goalVel.dot(myVel)
	#var newVel =  myVel
	#if dotProd < 0.01: #this value of 0.01 seems to work for strength = 15.0*mass
	var distToGoal = goalVel.length()

	#try this to limit max speed
#	if dotProd > distToGoal*distToGoal - 0.2:
#		return

	var threshold = 0.07
	#method 2:
#	if distToGoal > threshold:
#		pass
##	elif distToGoal < threshold:
##		newVel = myVel.linear_interpolate(Vector3(0,0,0), 0.5)#6*(threshold-distToGoal))#+0.1) # was 0.7 after this -> #was 0.3 which is fine except for sword swings
##		newVel *= -1
#	else: #inbetween
#		if (goalVel-myVel).length() < threshold:
#			return
#		newVel = myVel.linear_interpolate(Vector3(0,0,0), (1.0/threshold)*(threshold-distToGoal))
#		newVel *= -1
	
#	#method 1
	if  distToGoal < threshold:
		newVel = myVel.linear_interpolate(Vector3(0,0,0), 6*distToGoal)#6*(threshold-distToGoal))#+0.1) # was 0.7 after this -> #was 0.3 which is fine except for sword swings
		newVel *= -1
	
	var forceVec = strength*newVel*delta
	apply_central_impulse(forceVec)
	#apply it to held item too
#	if held_item == null:
#		return
#	if !is_instance_valid(held_item):
#		return
#	held_item.apply_central_impulse(forceVec)

func custom_dampened_force_2(delta):
	var goalVec = (target.global_transform.origin - global_transform.origin)
	var distToGoal = goalVec.length()
	var goalDir = (1.0/distToGoal)*goalVec
#	apply_central_impulse(5*mass*delta*goalDir)
#	return
	
	#var distToGoal = goalVec.length()
	#var goalDir = (1.0/distToGoal)*goalVec
	#we dont want forces to get too big so we seperate the lengths
	var newStrength = distToGoal
	var maxThreshold = 1
	if distToGoal > maxThreshold:
		newStrength = maxThreshold
	var newVel  = newStrength*goalDir
	#clamped from above
	#then do the rest of the force giving
	#dampen if needed etc
	var minThreshold = 0.15
	if  distToGoal < minThreshold:
		newVel = linear_velocity.linear_interpolate(Vector3(0,0,0), 6*distToGoal)#6*(threshold-distToGoal))#+0.1) # was 0.7 after this -> #was 0.3 which is fine except for sword swings
		newVel *= -1
		linear_damp = 1 #messing with damp is the only way to  slow it and make it seem nice
	else:
		linear_damp = -1
	
	var strength = 25*mass #25*mass works#20.5
	var forceVec = strength*newVel*delta
	apply_central_impulse(forceVec)

func custom_dampened_force_2_2(delta):
	#still bounces around too much in some positions
	var goalVec = (target.global_transform.origin - global_transform.origin)
	var distToGoal = goalVec.length()
	var goalDir = (1.0/distToGoal)*goalVec
#	apply_central_impulse(5*mass*delta*goalDir)
#	return
	
	#var distToGoal = goalVec.length()
	#var goalDir = (1.0/distToGoal)*goalVec
	#we dont want forces to get too big so we seperate the lengths
	var newStrength = distToGoal
	var maxThreshold = 1
	if distToGoal > maxThreshold:
		newStrength = maxThreshold
	var newVel  = newStrength*goalDir
	#clamped from above
	#then do the rest of the force giving
	#dampen if needed etc
	var minThreshold = 0.15# works
	if  distToGoal < minThreshold:
		newVel = linear_velocity.linear_interpolate(Vector3(0,0,0), 6*distToGoal)#6*(threshold-distToGoal))#+0.1) # was 0.7 after this -> #was 0.3 which is fine except for sword swings
		newVel *= -1
		#distToGoal in [0,minThreshold] --> distToGoal/minThreshold in [0,1]
		var normalVar = float(distToGoal)/float(minThreshold)#, to make a smooth damping
		var in_threshold_damp_strength = 20# 2 works
		linear_damp = original_linear_damp + (1-normalVar)*in_threshold_damp_strength #messing with damp is the only way to  slow it and make it seem nice
		#set_linear_damp_for_both(original_linear_damp + (1-normalVar)*in_threshold_damp_strength)
	else:
		linear_damp = original_linear_damp
		#set_linear_damp_for_both(original_linear_damp)
	
	var strength = 25*mass# works well #20.5
	var forceVec = strength*newVel*delta
	apply_central_impulse(forceVec)

func custom_dampened_force_2_3(delta):
	#still bounces around too much in some positions
	var goalVec = (target.global_transform.origin - global_transform.origin)
	var distToGoal = goalVec.length()
	var goalDir = (1.0/distToGoal)*goalVec
#	apply_central_impulse(5*mass*delta*goalDir)
#	return
	
	#var distToGoal = goalVec.length()
	#var goalDir = (1.0/distToGoal)*goalVec
	#we dont want forces to get too big so we seperate the lengths
	var newStrength = distToGoal
	var maxThreshold = 1
	if distToGoal > maxThreshold:
		newStrength = maxThreshold
	var newVel  = newStrength*goalDir
	#clamped from above
	#then do the rest of the force giving
	#dampen if needed etc
	var minThreshold = 0.15# works
	#var minThreshold = 0.1
	if  distToGoal < minThreshold:
		newVel = linear_velocity.linear_interpolate(Vector3(0,0,0), 6*distToGoal)#6*(threshold-distToGoal))#+0.1) # was 0.7 after this -> #was 0.3 which is fine except for sword swings
		newVel *= -1
		#distToGoal in [0,minThreshold] --> distToGoal/minThreshold in [0,1]
		var normalVar = float(distToGoal)/float(minThreshold)#, to make a smooth damping
		var in_threshold_damp_strength = 20# 2 works
		linear_damp = original_linear_damp + (1-normalVar)*in_threshold_damp_strength #messing with damp is the only way to  slow it and make it seem nice
		#set_linear_damp_for_both(original_linear_damp + (1-normalVar)*in_threshold_damp_strength)
	else:
		linear_damp = original_linear_damp
		#set_linear_damp_for_both(original_linear_damp)
	
	#var strength = 55*mass
	#var strength = 65*mass
	var strength = 45*mass#25*mass works well #20.5 ,#45 feels good
	var forceVec = strength*newVel*delta
	apply_central_impulse(forceVec)

func set_linear_damp_for_both(amount):
	linear_damp = amount
	if held_item == null:
		return false
	if !is_instance_valid(held_item):
		return false
	var itemLinDamp = held_item.get("linear_damp")
	if itemLinDamp == null:
		return false
		held_item.linear_damp = amount

func custom_dampened_force_3(delta):
	var result = target.get_velocity_values()
	var controller_velocity = result[0]
	var goalVel = controller_velocity
	var vecToGoalVel = goalVel - linear_velocity
	apply_central_impulse(delta*mass*vecToGoalVel)


func rumble_process():
	if is_held_item_colliding() == true:
		target.rumble = 0.5
	else:
		target.rumble = 0.0

func _integrate_forces(state):
	#does this integrate forces function mess with my joints that I generate?
	if target == null:
		return
#	if target.get_is_active() == false:
#		var newVel = state.linear_velocity.linear_interpolate(Vector3(0,0,0), 0.9)
#		state.linear_velocity = newVel
#		newVel = state.angular_velocity.linear_interpolate(Vector3(0,0,0), 0.9)
#		state.angular_velocity = newVel
#		#gopefully that stops us flyin away when a controller disconnects, it doesnt
#		return
	
	apply_torque_toward_controller_velocity(state.step)
	


var controller_moving = false
func apply_torque_toward_controller_velocity(timeStep):
	var result = target.get_velocity_values()

#	#Test limit ang velocity when we do big swings
#doesnt feel as expected and feels weird when not intended
#	var linVel = result[0]
#	if linVel.length() > 0.8:
#		controller_moving = true
#	elif linVel.length() < 0.1:
#		controller_moving = false
#	else:
#		if controller_moving == true:
#			angular_damp = 20
#		else:
#			angular_damp = -1


	var angVel = result[1]
	var strengthMod = 1#0.5
	var forceVel = angVel - angular_velocity
	apply_torque_impulse(strengthMod*forceVel*timeStep)


#func rigid_follow_target(body, target): #both are node references
#	var vel = target.global_transform.origin - body.global_transform.origin
#	vel *= vel.length_squared()
#	body.add_central_force(20*vel)

func dampen_movement_in_wrong_direction(state):
	var goalVel = target.global_transform.origin - global_transform.origin
	var myVel = state.linear_velocity
	var dotProd = goalVel.dot(myVel)
	if dotProd < 0.01: #this value of 0.01 seems to work for strength = 15.0*mass
		var newVel = state.linear_velocity.linear_interpolate(Vector3(0,0,0), 0.7) #was 0.3 which is fine except for sword swings
		state.linear_velocity = newVel
	#print("dotProd = ", dotProd)# this doesnnt work as expected, dotProd is always small and positive, instead of checking if negative check if small enough
	
	#if we are holding something we should probably dampen that too


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

func get_target_rotation_from_controller():
	var targetBasis = target.global_transform.basis
	var rotatedTargetBasis = original_spatial_transform.basis*targetBasis*original_spatial_basis_inverse
	return rotatedTargetBasis

func align_myself_so_child_spatial_aligns_with_target():
	#print("aligning hand")
	var spatial = get_node("Spatial")
	#var targetBasis = Basis(target.global_transform.basis.x, -target.global_transform.basis.y, target.global_transform.basis.z)
	var targetBasis = target.global_transform.basis
	#targetBasis.rotated(target.global_transform.basis.y, PI)
	#targetBasis.rotated(Vector3(0,1,0), PI)
	spatial.global_transform.basis = targetBasis
	var localBasis = original_spatial_basis_inverse*spatial.transform.basis
	#seems to work except that basis is rotated 180 around y axis to align the camera, hence the Basis(Vector3(0,1,0), PI)
	#could also be
	#var localBasis = spatial.transform.basis*original_spatial_basis_inverse
	spatial.transform = original_spatial_transform
	#apply it to my rotation
	#methoid1: local: #working but was flipped as camera points PI away from other things
#	var xForm = localBasis*transform.basis
#	xForm = xForm.orthonormalized()
#	transform.basis = xForm
	#method 2: global:, this doesnt fix my rotation issues.
	var xForm = localBasis*global_transform.basis
	xForm = xForm.orthonormalized()
	#global_transform.basis = xForm #do outside
	return xForm
	
	#set my spatial back tp default
	#print("aligned hand")
	#quaternion error happens after this....

func is_held_item_colliding():
	if held_item == null:
		return false
	if !is_instance_valid(held_item):
		return false
	if held_item.contact_monitor == false: #should be removed when let go
		held_item.contact_monitor = true
		held_item.contacts_reported = 1
	var colliding_bodies = held_item.get_colliding_bodies()
	for body in colliding_bodies:
		if body != self:
			return true
	return false

























