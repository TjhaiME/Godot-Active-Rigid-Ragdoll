extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var targetRotation = Vector3(0,0,0)
var fix_rotation = false#true#
var check_air_speed = false
var lastStablePos = Vector3(0,0,0)
var air_speed_threshold = 20
var airCount = 0
var originalMass = 12
var fix_rotation_timer = 0
var fix_rotation_max_time = 1.5

var applying_impulse = false

#var last_stable_pos = Vector3(0,0,0)#get_parent().floorPosUnderHips

# Called when the node enters the scene tree for the first time.
func _ready():
	originalMass = mass
	targetRotation = rotation
	#set_up_test_physics_stabilised_mode()
	pass # Replace with function body.

func set_up_test_physics_stabilised_mode():
	axis_lock_angular_x = false
	axis_lock_angular_z = false

	get_parent().get_node("mixamorig_Hips").gravity_scale = -0.5
	get_parent().get_node("mixamorig_Hips").original_gravity_scale = get_parent().get_node("mixamorig_Hips").gravity_scale
	#method 1
	fix_rotation = true
	#method 2
#	get_parent().get_node("mixamorig_Head").mass = 12
#	get_parent().get_node("mixamorig_Spine1").gravity_scale = -1
#	get_parent().get_node("mixamorig_Spine2").gravity_scale = -1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#return
	#we only want to check air speed when we are above our last known position
	
#	if check_air_speed == true:
#		#if we are stunned then we dont want to check air speed
#		if get_parent().stunTime > 0:
#			return
#		if global_transform.origin.y <= lastStablePos.y:
#			#we aren't neccesarily flying off because of physics we might have just fallen off a cliff
#			return
#		#print("checking air speed")
#		var air_speed = linear_velocity.length()
#		if air_speed > air_speed_threshold:
#			print("air speed too high")
#			airCount += delta
#			if airCount > 0.5: #so we have to be over the threshold for a whole second before activating this, which hopefully we can tweak to only happen when we fly off the map
#				print("air speed too high for too long, resetting ragdoll")
#				reset_to_last_stable_pos()
#				airCount = 0
#		elif air_speed < 5:
#			check_air_speed = false
	
	#print("oipo")
	if linear_velocity.length_squared() < 0.25:
		get_repulsion_force_from_close_npcs(delta)
	
	
	if fix_rotation == false:
		fix_rotation_timer = 0
		return
	#return
	
	
	custom_dampened_force(delta)
	
	return #tyurn off below stuff for now
	
	
	var targetRot = Vector3(targetRotation.x, rotation.y, targetRotation.z) #so we can change directions
#	var diff = targetRot.distance_squared_to(rotation)
#	if diff <0.1:
#		return
	#print("I think I found my quat orthonormalised error")
	var targetQuat = Quat(targetRot)
	var currentQuat = Quat(rotation)
	var intermediateQuat = currentQuat.slerp(targetQuat, 2 * delta)
	var intermediateEuler = intermediateQuat.get_euler()
	var targetEuler = intermediateEuler - rotation
	#var strength = 800*mass  #800*mass works for 10 #500*mass works for mass of 20 #for mass of 50 a value of 10 = 0.2*mass? seemed to work (goes down since we get less of the physics engine impact when the mass is smaller)
	#the above values only worked before mass adjustments to upper parts
	var strength = 1.3*(-30*mass+1100)*mass #1.5*(-30*mass+1100)*mass seems okay for current addon version but sometimes bounces heaps, 1.3 seems to bounce less
	#var strength = 1.1*(-30*mass+1100)*mass
	apply_torque_impulse(targetEuler * delta * strength)



func custom_dampened_force(delta):
	var targetRot = Vector3(targetRotation.x, rotation.y, targetRotation.z)
	var diffVel = targetRot - rotation
	var strength = 1.0*(-30*mass+600)*mass 
	
	if fix_rotation_timer > fix_rotation_max_time:
		strength *= 1 + (fix_rotation_timer - fix_rotation_max_time)
	fix_rotation_timer += delta
	
	var diff = diffVel.length()
	if diff < 0.1:
		var newVel = angular_velocity.linear_interpolate(Vector3(0,0,0), 5*diff) #was 0.3 which is fine except for sword swings
		newVel *= -1
		targetRot = Vector3(newVel.x, targetRot.y, newVel.z)
		#return
#		apply_torque_impulse(newVel * delta * strength)
#		return
	
	var targetQuat = Quat(targetRot)
	var currentQuat = Quat(rotation)
	var intermediateQuat = currentQuat.slerp(targetQuat, 2 * delta)
	var intermediateEuler = intermediateQuat.get_euler()
	var targetEuler = intermediateEuler - rotation
	apply_torque_impulse(targetEuler * delta * strength)




#var rot = Quaternion.FromToRotation(transform.up, Vector3.up);
#  rb.AddTorque(new Vector3(rot.x, rot.y, rot.z)*uprightTorque);



#func _on_FloorCheck_area_exited(area): #floor are bodies not areas
#	#we just left the floor, record the spot we are at and intiate velocity checking procedures
#	lastStablePos = global_transform.origin
#	check_air_speed = true
#	pass # Replace with function body.
#
#
#func _on_FloorCheck_area_entered(area):
#	#we just landed, record this spot as a possible respawn point
#	lastStablePos = global_transform.origin
#	check_air_speed = false
#	pass # Replace with function body.

func reset_to_last_stable_pos(): #badly hardcoded
	#ummm this is hard to do with rigidBodyRagdolls.
	#so I will have to die for now...this is a bad way to do it because I will lose a lot of info like state and weapon etc.
	var masterNode = get_parent().get_parent().get_parent()
	var myName = masterNode.name
	masterNode.name = str(myName, "DEL")
	var newMe = load("res://addons/rigidRagdoll/Characters/rigidRagdollNPC.tscn").instance()
	#badly done
	var parent = masterNode.get_parent()
	parent.add_child(newMe)
	newMe.global_transform.origin = lastStablePos
	newMe.name = myName
	#ONLY WORKS FOR TEST SCENES
	parent.set_up_npc_state(newMe, parent.faction)
	
	check_air_speed = false
	masterNode.queue_free()

var physics_override_on_death = false
var temp_falling_override = false
var getting_up_override = false
var overrideTimer = 0
var overrideTimerMax = 100
var newMass = 1
func _integrate_forces(state):
	if physics_override_on_death == true:
		#mass =1
		if mass != 1:
			mass = 1
		#physics_override_on_death = false
		return
	elif temp_falling_override == true:
		#return #turn off for now
		#mass = 1
		if mass != newMass:
			mass = newMass
		overrideTimer += state.step
		if overrideTimer > overrideTimerMax:
			if physics_override_on_death == true:
				#seemed to fix the npc from suddenly disappearing if stamina and health run out at same time
				return
			overrideTimer = 0
			mass = originalMass 
			temp_falling_override = false
	
#	##########################################################################
#	#Special next part for testing if lowered mass makes gameplay more fun
#	elif getting_up_override == true:
#		mass = 12
#	elif getting_up_override == false:
#		get_parent().stats["walkSpeed"] += 0.001
#		mass = 6
#	##########################################################################
	 #it doesnt fuck things up as much if we do it here
	#are all physics states safe here, no if we acsess others things fuck up again
#	var rigid_bodies = get_parent().rigid_bodies
#	for rigid_body in rigid_bodies:
#		rigid_body.gravity_scale = 1


var floorBodies = []
var touchingFloor = false

func _on_FloorCheck_body_entered(body):
	#we just landed, record this spot as a possible respawn point
	lastStablePos = global_transform.origin
	check_air_speed = false
	
	
	if body in floorBodies:
		return
	floorBodies.append(body)
	touchingFloor = true
	
	pass # Replace with function body.


func _on_FloorCheck_body_exited(body):
	#we just left the floor, record the spot we are at and intiate velocity checking procedures
	lastStablePos = global_transform.origin
	check_air_speed = true
	
	
	if body in floorBodies:
		floorBodies.erase(body)
	if floorBodies.size() == 0:
		touchingFloor = false
	
	pass # Replace with function body.



func get_faction_from_area(area):
	var areaSkelRagdoll = area.get_parent().get_parent()
	if areaSkelRagdoll == null:
		return null
	var enemyFaction = areaSkelRagdoll.get("faction")
	return enemyFaction

#for swarm behaviour
var close_npcs = [] #skelRagdoll

func _on_CloseArea_area_entered(area):
	var areaSkelRagdoll = area.get_parent().get_parent()
	if areaSkelRagdoll in close_npcs:
		return
	if get_parent().faction != get_faction_from_area(area):
		return
	
	close_npcs.append(areaSkelRagdoll)
	pass # Replace with function body.


func _on_CloseArea_area_exited(area):
	var areaSkelRagdoll = area.get_parent().get_parent()
	if areaSkelRagdoll in close_npcs:
		close_npcs.erase(areaSkelRagdoll)
	pass # Replace with function body.


func get_repulsion_force_from_close_npcs(delta):
	var force_away = Vector3(0,0,0)
	for index in close_npcs.size():
		var friend_skelRagdoll = close_npcs[index]
		var friendCapBase = friend_skelRagdoll.get_node("capsuleBase")
		if friendCapBase == null: #random bug happened probably when someone died
			continue
		var vecToMe = global_transform.origin - friendCapBase.global_transform.origin
		var distToMe = vecToMe.length()
		force_away += ($CloseArea/CollisionShape.shape.radius - distToMe)*vecToMe
	
	#now we have a force_away
	#print("force = ", force_away)
	apply_central_impulse(200*force_away*delta*mass)
