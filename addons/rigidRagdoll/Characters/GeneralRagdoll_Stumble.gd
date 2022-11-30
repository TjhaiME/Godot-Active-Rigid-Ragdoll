extends "res://addons/rigidRagdoll/Scripts/ragdollExtra.gd"

#we need to also check if our hips are out of the right orientation, if it is we need to try to fix our rotation
#we could apply strength to tis only if we are touching floor.

var legR = null
var legL = null
var footR = null
var footL = null
var hipsNode = null
var defaultHipsHeight = 0
var footXMod = 0.1

var strengthMod = 0
var hipsDotY = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	
	rigidBodiesFromBones = {
		#"BONE_NAME" : "RIGIDBODY_NODE_NAME",
		#we put the name of our bone as the key
		#we put the name of the corresponding rigidBody as the value (has to be child of skeleton)
		#so if we change the model but keep the ragdoll, then we only change the keys
		#the rest of the data will be generated from this list and the data in skeleton
		"mixamorig_Hips" : "Hips",
		"mixamorig_Spine1" : "Spine1",
		"mixamorig_Spine2" : "Spine2",
		"mixamorig_Head" : "Head",
		"mixamorig_LeftArm" : "LeftArm",
		"mixamorig_LeftForeArm" : "LeftForeArm",
		"mixamorig_LeftHand" : "LeftHand",
		"mixamorig_RightArm" : "RightArm",
		"mixamorig_RightForeArm" : "RightForeArm",
		"mixamorig_RightHand" : "RightHand",
		"mixamorig_LeftUpLeg" : "LeftUpLeg",
		"mixamorig_RightUpLeg" : "RightUpLeg",
		"mixamorig_LeftLeg" : "LeftLeg",
		"mixamorig_RightLeg" : "RightLeg",
	}
	
	
	anim_time += rand_range(0.0, 0.1)
	
	
	skeleton = $SkeletonRagdoll
	rigidBodyParent = skeleton
	#_set_up()
	legR = $SkeletonRagdoll/RightLeg
	legL = $SkeletonRagdoll/LeftLeg
	footR = $SkeletonRagdoll/RightFoot
	footL = $SkeletonRagdoll/LeftFoot
	hipsNode = $SkeletonRagdoll/Hips
	defaultHipsHeight = hipsNode.global_transform.origin.y - legR.global_transform.origin.y
	
	my_skel = skeleton
	my_headNode = $SkeletonRagdoll/Head
	basePosNode = $SkeletonRagdoll/Hips #could be a singular ffoot or hips
	stats["swingSpeed"] = 1.0 #0.7
	parent_is_ready()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	floorPos = hipsNode.global_transform.origin - defaultHipsHeight*Vector3(0,1,0)
	
	var strengthMod = int(footL.touchingFloor) + int(footR.touchingFloor)
	if strengthMod > 0:
		stabilise_oscillations(delta)
		extra_animations(delta)
	
	return
	
	walk_in_direction(delta, Vector3(0,0,1), true)
	
	#deform_skeleton_with_rigidBodies() #done in base Script
	pass
	if Input.is_action_just_pressed("ui_accept"):
		print("changing mass")
		var newMass = 0.5
		footR.temp_falling_override = true
		footR.newMass = newMass
		footL.temp_falling_override = true
		footL.newMass = newMass
	#SHITTY HIPS GRAV SCALE CHANGE CODE FOR GETTINGG UP, DOESNT WORK
	#print(" touching floor L R = ", $SkeletonRagdoll/LeftLeg.touchingFloor, " , ", $SkeletonRagdoll/RightLeg.touchingFloor)
#	var strengthMod = int(legL.touchingFloor) + int(legR.touchingFloor) #cast bools to int (in {0,1,2})
#	#var new_scale = 0#-1 if strengthMod = 2 0.5 if strengthMod = 1 1 if strengthMod = 0
#	if strengthMod == 0:
#		if hipsNode.gravity_scale != 1:
#			hipsNode.change_grav_scale = true
#			hipsNode.new_gravity_scale = 1
#		return
#	var new_scale = 0 - 0.5*strengthMod
#	#hipsNode.change_grav_scale(new_scale)
#	hipsNode.change_grav_scale = true
#	hipsNode.new_gravity_scale = 1
	
	
	
	#if foot touching ground then
	#apply rotation fix to hips
	hipsDotY = hipsNode.global_transform.basis.y.dot(Vector3(0,1,0))
	strengthMod = int(footL.touchingFloor) + int(footR.touchingFloor) #cast bools to int (in {0,1,2})
	#move_feet_under_hips(delta)
	
	#stabilise_oscillations(delta) #need a function to stop us oscillating when we finally get close to standing straight
	#above function also doesnt seem to acually do anything

var SO_timer = 0
#func stabilise_oscillations(delta):
#	var falling = false
#	if hipsDotY > 0.85:
#
#		if strengthMod == 0:
#			falling = true
#			return
#		#print("we are losing balance, hipsDotY = ", hipsDotY)
#		if falling == true:
#			print("damping on")
#			hipsNode.linear_damp = 100
#			hipsNode.angular_damp = 100
#			SO_timer = 0.1
#		elif SO_timer < 0:#se:
#			SO_timer = 0
#			hipsNode.linear_damp = -1
#			hipsNode.angular_damp = -1
#			print("damping RESET")
#		else:
#			SO_timer -= delta
#			print("damping, timer ticking")
#	else:
#		falling = true
	

func stabilise_oscillations(delta):
	var falling = false
	if hipsDotY > 0.7:
		#we are upright
		if strengthMod == 0:
			falling = true
			return
		#print("we are losing balance, hipsDotY = ", hipsDotY)
	else:
		falling = true
	
	
	if falling == true:
		if SO_timer == 0:
			#print("damping on")
			#hipsNode.linear_damp = 100
			hipsNode.angular_damp = 100
			SO_timer = 0.03
	
	if SO_timer < 0:#se:
		SO_timer = 0
		#hipsNode.linear_damp = -1
		hipsNode.angular_damp = -1
		#print("damping RESET")
	else:
		if SO_timer == 0:
			return
		SO_timer -= delta
		#print("damping, timer ticking")

func move_feet_under_hips(delta):
	#if my feet are too far away from being right under my hips then we should apply a force to the foot to correct it, only if we are standing
	if hipsDotY < 0.7:
		return
	
	
	#var new_scale = 0#-1 if strengthMod = 2 0.5 if strengthMod = 1 1 if strengthMod = 0
	if strengthMod == 0:
		return #we are not standing, so we shouldnt apply forces as we cannot put tension on the ground
	#else we are standing
	var hipsGroundPos = hipsNode.global_transform.origin
	hipsGroundPos.y -= defaultHipsHeight
	
	var footDistR = hipsGroundPos.distance_to(footR.global_transform.origin)
	var footDistL = hipsGroundPos.distance_to(footL.global_transform.origin)
	var distThreshold = 0.5
	var footToMove = footR
	var footPosMod = -footXMod
	var footDist = footDistR
	if footDistL > footDistR:
		footToMove = footL
		footPosMod = footXMod
		footDist = footDistL
	if footDist > distThreshold:
		var desiredFootPos = hipsGroundPos + footPosMod*hipsNode.global_transform.basis.x
		var dir = desiredFootPos - footToMove.global_transform.origin
		footToMove.apply_central_impulse(dir*footToMove.mass*delta)

var anim_time = 0
var anim_side = "l"
var anim_state = 0
var switchFootTime = 0.5

func choose_foot_for_walk():
	
	var dir = hipsNode.global_transform.basis.z
	#which foot is behind
	var footPosL = footL.global_transform.origin
	var floorPos = hipsNode.global_transform.origin - defaultHipsHeight*Vector3(0,1,0)
	var vecToFootL = footPosL - floorPos
	var footPosR = footR.global_transform.origin
	var vecToFootR = footPosR - floorPos
	
#	var lPosProj = dir.dot(footL.global_transform.origin)
#	var rPosProj = dir.dot(footR.global_transform.origin)
	
	var lPosProj = dir.dot(vecToFootL)
	var rPosProj = dir.dot(vecToFootR)
	var side = "r"
	if lPosProj < rPosProj:
		side = "l"
	#foot "side" is the one behind the other foot
	print("choosing new foot to move = ", side)
	anim_side = side

func do_walk_direct_to_target(delta, target): #override
	print("2 feet walking to target")
	var dir = target - floorPos
	dir = dir.normalized()
	walk_in_direction(delta, dir, true)

func do_walk_away_from_target(delta, target):
	print("walking away from target 2 feet")
	var dir = target - floorPos
	walk_in_direction(delta, -dir, false)

func walk_in_direction(delta, dir, forwardWalkBool):
	
	#get foot that is behind
	#normal forward walk
	var foot = get_foot_from_side(anim_side)
	var otherFoot = get_other_foot_from_side(anim_side)
	if forwardWalkBool == false: #BACKWARD WALK
		otherFoot = get_foot_from_side(anim_side)
		foot = get_other_foot_from_side(anim_side)
	if otherFoot.touchingFloor == false:
		#we need to have a foot pushing on the floor to lift our other foot
		print("otherFoot isnt touching the floor")
		return
	var rotStrength = rotate_hips_towards_dir(delta, dir)
	if rotStrength > 0.25:#0.15: gets stuck while walking and essentially facing forward
		print("rotating towards target direction while walking")
		#return
	
	anim_time += delta
	print("anim_time = ", anim_time)
	
	#move it up and in direction
	var scalar = 0.7071# = 1.0/sqrt(2)
	var directUpTime = 0.2
	#we only need one of these
	#var upDiagDir = scalar*dir + scalar*Vector3(0,1,0)
	#var downDiagDir = scalar*dir - scalar*Vector3(0,1,0)
	var newDir = dir
	var runStrengthMod = 1.0#0.0
	var walkStrengthMod = 4.5 #4.0 works for a slight stable walk
	var upDirStrengthMod = 2.60#2.5 works for a slight stable walk
	var actualSwitchFootTime = switchFootTime# - 0.25*switchFootTime*runStrengthMod
	if anim_state == 0:#"up":
		#we probably have to move the thigh up instead
		
		
		#we are moving the foot up
		#we know the other foot is on the ground
		#newDir = scalar*dir + scalar*Vector3(0,1,0)
		newDir = 0.4*dir + 0.9165*Vector3(0,1,0) #(if x=0.4 -> y = sqrt(1-(0.4)^2))
		#need more up in my direction to stop it colliding with floor and it cant just go straight up
		var multi = 3.0
		#newDir = (1.0/multi*5.0)*(multi*4*Vector3(0,1,0) + multi*3*dir)
		if anim_time <= directUpTime:
			pass
			#move foot or leg directly up at first
			#newDir = Vector3(0,1,0)
			#foot = get_leg_from_side(anim_side)
		walkStrengthMod += upDirStrengthMod
		var finished_step
		if foot.global_transform.origin.y > otherFoot.global_transform.origin.y + 0.4*defaultHipsHeight: #have we lifted our foot to near our knee height?
			anim_state = 1#"down"
			print("foot is high enough, moving to down state of step")
			return
		if anim_time > actualSwitchFootTime : #abort if fails for too long
			anim_state = 1#"down"
			print("tried too long to lift foot and failed, switching foot")
			return
		###############
		#not really needed but it does make it smoother slightly
		#as we use our upper leg to walk
		var thigh = get_thigh_from_side(anim_side)
		#-0.4y from our pos is our knee
		thigh.apply_impulse(Vector3(0,-0.4,0), newDir*walkStrengthMod*thigh.mass*delta)
		##############
		#added code to turn into a run
		var runStrength = runStrengthMod*total_weight*0.5
		var hipDir = scalar*dir + scalar*Vector3(0,1,0)
		if runStrength == 0:
			hipsNode.apply_central_impulse(hipsNode.mass*Vector3(0,1,0)*delta)
		else:
			hipsNode.apply_central_impulse(hipDir*runStrength*delta)
		walkStrengthMod += runStrengthMod
		print("hipsNode = ", hipsNode, " runStrength = ", runStrength)
	else: #moving foot down toward ground
		newDir = scalar*dir - scalar*Vector3(0,1,0)
		if foot.global_transform.origin.y < otherFoot.global_transform.origin.y + 0.1: #is our foot near the ground?
			anim_state = 0
			anim_time = 0
			choose_foot_for_walk()
			print("foot on ground and far away from oherFoot, switching state")
			return
	
	
	
	foot.apply_central_impulse(newDir*walkStrengthMod*foot.mass*delta)
	print("applying impulse to foot = ", foot, ", anim state = ", anim_state)
	
	
	return
	
	#extra check:
	if anim_time <= directUpTime:
		return
	var footPos = foot.global_transform.origin
	var floorPos = hipsNode.global_transform.origin - defaultHipsHeight*Vector3(0,1,0)
	var vecToFoot = footPos - floorPos
	var otherFootPos = otherFoot.global_transform.origin
	var vecToOtherFoot = otherFootPos - floorPos
	var difference_in_projections = abs(dir.dot(vecToFoot) - dir.dot(vecToOtherFoot))#abs(dir.dot(footPos) - dir.dot(otherFootPos))
	var vertThresh = 0.08
	var dirThresh = 0.8#1.0 #metres
	if abs(footPos.y-otherFootPos.y) < vertThresh:
		#thern check if it is far enough in the direction we want
		if abs(dir.dot(footPos) - dir.dot(otherFootPos)) < dirThresh:
			anim_state = 0
			anim_time = 0
			choose_foot_for_walk()
		


func get_foot_from_side(sideLetter):
	var footNode = footR
	if sideLetter == "l":
		footNode = footL
	return footNode

func get_thigh_from_side(sideLetter):
	var footNode = $SkeletonRagdoll/RightUpLeg
	if sideLetter == "l":
		footNode = $SkeletonRagdoll/LeftUpLeg
	return footNode

func get_leg_from_side(sideLetter):
	var footNode = legR
	if sideLetter == "l":
		footNode = legL
	return footNode

func get_other_foot_from_side(sideLetter):
	var footNode = footL
	if sideLetter == "l":
		footNode = footR
	return footNode

func vectorProjection(vecA,vecB):
	#a·b / |b|
	return float(vecA.dot(vecB))/float(vecB.length())

func signed_min_angle2(this, other):
	var angleVar = other.angle_to(this)
	var newAngle = angleVar
	if this.cross(other).dot(Vector3(0,1,0)) < 0:
		newAngle *= -1
	#print("signed min angle function, angleVar = ", angleVar, " newAngle = ",newAngle)
	return newAngle

func rotate_hips_towards_dir(delta, dir):
	##################
	####rotate feet too
	var nodeRefArray = [hipsNode, footL, footR]
	return apply_rotation_to_look_toward_vec_array(delta, nodeRefArray, dir)
	#this works better for our 2 footed friend, stops 'em from getting stuck when you are behind them
	##################
#	#just hips
#	return apply_rotation_to_look_toward_vec(delta,hipsNode,dir)
#	#if just hips we dont have enough strength to move the feet sometimes, it can easily get stuck


func apply_rotation_to_look_toward_vec(delta, nodeRef, vecToTarget):# delta
	#causes the model to zoolander and spin around heaps to do small turns.
	#var vecToTarget = target - nodeRef.global_transform.origin
#	var strength = target.angle_to(nodeRef.global_transform.basis.z)
#	strength = signed_min_angle(strength)
	var strength = signed_min_angle2(nodeRef.global_transform.basis.z, vecToTarget)
	#print("applying rotation, strength = ", strength)
	var rotStrengthMod = 7.0#0.4 #1.0 seemed too much without delta
	var rotateVec = rotStrengthMod*strength*Vector3(0,1,0) #0.3*strength*Vector3(0,1,0) worked alright
	nodeRef.apply_torque_impulse(delta*rotateVec)
	return strength

func apply_rotation_to_look_toward_vec_array(delta, nodeRefArray, vecToTarget):# delta
	#causes the model to zoolander and spin around heaps to do small turns.
	#var vecToTarget = target - nodeRef.global_transform.origin
#	var strength = target.angle_to(nodeRef.global_transform.basis.z)
#	strength = signed_min_angle(strength)
	if nodeRefArray.size() == 0:
		return 0
	var strength = signed_min_angle2(nodeRefArray[0].global_transform.basis.z, vecToTarget)
	for nodeRef in nodeRefArray:
		#print("applying rotation, strength = ", strength)
		var rotStrengthMod = 7.0#0.4 #1.0 seemed too much without delta
		var rotateVec = rotStrengthMod*strength*Vector3(0,1,0) #0.3*strength*Vector3(0,1,0) worked alright
		nodeRef.apply_torque_impulse(delta*rotateVec)
	return strength
