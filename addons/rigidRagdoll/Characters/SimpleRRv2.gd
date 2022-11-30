extends Spatial
#need to replace all bone names with the correct ones

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


var health = 10
var stunTime = 0
var rigid_bodies = []
#var stamina = 10


var faction = 0
var extraAnimBool = false
var extraAnimString = "null"
var extraAnimTarget = Vector3(0,0,0)
var extraAnimTime = 0
var extraAnimNode = null
var extraAnimState = 0
var extraAnimRand = 0
var walkStrength = 10.0
var dominantHand = null
var weaponLength = 1.0
var total_weight = 45
var stats = {
	"walkSpeed" : 0.75,
	"swingSpeed" : 1.0
}
var prepareTarget = Vector3(0,0,0)
var handPosNodeToHandDist = 0.15

var legOffset = Vector3(0,0.1,0) #zero vec changes it to apply_central_impulse

var is_dying = false
var baseAnimTime = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	#get_initial_tforms()
	rigid_bodies = [$Legs, $Body, $Head, $ArmL, $ForeArmL, $ArmR, $ForeArmR]
	dominantHand = $ForeArmR
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#deform_skeleton_with_rigidBodies()
	if is_dying == true:
		baseAnimTime -= delta
		if baseAnimTime <= 0:
			queue_free()
		return
	check_health()
	if stunTime > 0: #only do AI things when I recover from knockback
		stunTime -= delta
		#print("I am stunned")
		#test alternate stun effects
#		axis_lock_angles($capsuleBase, false)
#		ragdollState = ragdollStateDir["gettingUp"]
		if stunTime <= 0:
			stunTime = 0
		return
	extra_animations(delta)
#	pass
func check_health():
	if health <= 0:
		#print("health below zero, extraAnimTime = ", extraAnimTime, " is_dying = ", is_dying)
		if is_dying == false:
			dyingFunction()
			baseAnimTime = 3.5
			is_dying = true
			if get_parent().has_method("npc_died"):
				#tell our master scenes parent that we have been deleted
				get_parent().npc_died()
			
		
func dyingFunction():
	
	unequip_all()
	$Body.physics_override_on_death = true
	$Head.physics_override_on_death = true
	#$mixamorig_Spine2.physics_override_on_death = true
#func spawn_and_equip(filePath):
#	var weaponLoad = load(filePath)
#	var weaponNode = weaponLoad.instance()
#	skelRagdoll.add_child(weaponNode)
#	var dominantHandSide = "right"
#	var domHand = skelRagdoll.dominantHand
#	if domHand == skelRagdoll.get_node_or_null("mixamorig_LeftHand"):
#		dominantHandSide = "left"
#	skelRagdoll.equip_weapon(weaponNode, dominantHandSide)


func extra_animations(delta):
	if extraAnimBool == false:
		return
	
#	if extraAnimString == "null":
#		return
	#print("extra_animations function , extraAnimString = ", extraAnimString)
	if has_method(extraAnimString):
		#print("trying to call extra animation = ", extraAnimString)
		call(extraAnimString, delta)





func anim_meleeFight(delta): #walk towards target and swing, ..more of a state then an animation
	anim_meleeFight_generalTarget(delta, extraAnimNode)
	return

func anim_meleeFight_generalTarget(delta, targetNode):
	#_WORKING_BUT_OLD_NO_NAVIGATION
	var handPosNode = dominantHand
	
	#############
	#STATE CHANGE
	###############################################
	#I never accounted for extraAnimNode dying
	if is_instance_valid(extraAnimNode) == false:
		#go back into alert state
		print("extraAnimNode = ", extraAnimNode, " is not a valid instance, switching to alert state")
		extraAnimString = "anim_alert_state"
		extraAnimTime = 0
		return
	###############################################
	
	var target = targetNode.global_transform.origin
	#rotate_eyes_toward(target+Vector3(0,1.7,0))
	var distanceToTarget = target.distance_to($Legs.global_transform.origin)
	var moveBackThreshold = weaponLength
	if distanceToTarget > 0.9 + weaponLength: #distance too large
		do_walk_direct_to_target(delta, target)
	elif distanceToTarget < moveBackThreshold: #distance too small
		do_walk_away_from_target(delta, target)
	else: # distanceToTarget < 0.9 + weaponLength:#0.9: #1.5 is for testing out of VR so I can see, but in VR it still felt waay to close and not needed if we are swinging a sword
		#we are close enough to swing (not walk), we need to check if our hand is far enough away
		do_melee_fight_state(delta, handPosNode, target)
		#maybe here we could check if we have a ranged weapon
		#if it does then do a ranged attack instead




var check_floor_ahead = true
var floor_detected = false
func do_walk_direct_to_target(delta, target):
	#var target = extraAnimTarget
	var walkingTarget = target
	walkingTarget.y = $Legs.global_transform.origin.y
	#we should turn and face the target first (before moving)
	var rotStrength = apply_rotation_to_look_toward($Legs,walkingTarget)
	if rotStrength > 0.15: #0.25 workd okay but overshoots I think, 0.15 tries to correct for the overshoot but cant do it becasue it has zoolander-itis
		$Legs.linear_damp = 0.5
		return
	else:
		$Legs.linear_damp = -1
	var mylinVel = $Legs.linear_velocity
	if mylinVel.length_squared() > 25:
		#attempt to limit max speed
		return
	#walking towards
	#var walkingTarget = extraAnimTarget
	#walkingTarget.y = 0
	
	if check_floor_ahead == true:
		var safe_to_move = check_if_there_is_floor_ahead()
		if safe_to_move == false:
			return
		#then there is floor ahead of me and I can safely move forward
	
#	var dir = target - $Legs.global_transform.origin
#	dir = dirVec.normalized()
	
	var dirVec = target - $Legs.global_transform.origin
	var dirLength = dirVec.length() #so the speed is constant and not distance based
	if dirLength < 1:
		$Legs.linear_damp = 1
	else:
		$Legs.linear_damp = -1
	var dir = (1.0/float(dirLength))*dirVec
#	if dirLength > 0.5:
#		return
	
	#var strength = 1.5*walkStrength*$Legs.mass #when I wasnt normalising it was walkStrength*$Legs.mass
	
	var strength = 0.7*walkStrength*total_weight
	
	#$Legs.look_at(walkingTarget, Vector3(0,1,0)) #this fucks with joints, capsuleBase seems to stay in the same spot
	#apply_rotation_to_look_toward($Legs,walkingTarget)
	#$Legs.apply_central_impulse(stats.walkSpeed*strength*dir*delta)
	var offset = legOffset
	$Legs.apply_impulse(offset,stats.walkSpeed*strength*dir*delta)
	$Legs.applying_impulse = true
	#$Legs.apply_torque_impulse()


func do_walk_away_from_target(delta, target):
	var dir = target - $Legs.global_transform.origin
	do_walk_in_direction_with_strength(dir,delta,-0.7)
#	var walkingTarget = target
#	walkingTarget.y = $Legs.global_transform.origin.y
#	#we should turn and face the target first (before moving)
#	var rotStrength = apply_rotation_to_look_toward($Legs,walkingTarget)
#	if rotStrength > 0.15: #0.25 workd okay but overshoots I think, 0.15 tries to correct for the overshoot but cant do it becasue it has zoolander-itis
#		return
#	var dir = target - $Legs.global_transform.origin
#	dir = dir.normalized() #so the speed is constant and not distance based
#	var strength = 0.7*walkStrength*total_weight
#	$Legs.apply_central_impulse(-stats.walkSpeed*strength*dir*delta)



func do_walk_in_direction(dir,delta):
	do_walk_in_direction_with_strength(dir,delta, 1.5)
#	print("walking in direction, ", dir)
#	var walkingTarget = $Legs.global_transform.origin + dir
#	walkingTarget.y = $Legs.global_transform.origin.y
#	#we should turn and face the target first (before moving)
#	var rotStrength = apply_rotation_to_look_toward($Legs,walkingTarget)
#	if rotStrength > 0.15: #0.25 workd okay but overshoots I think, 0.15 tries to correct for the overshoot but cant do it becasue it has zoolander-itis
#		return
#	var strength = 1.5*walkStrength*$Legs.mass #when I wasnt normalising it was walkStrength*$Legs.mass
#	$Legs.apply_central_impulse(stats.walkSpeed*strength*dir*delta)
#	

func do_walk_in_direction_with_strength(dir,delta, strengthMod):
	#print("walking in direction, ", dir)
	var walkingTarget = $Legs.global_transform.origin + dir
	walkingTarget.y = $Legs.global_transform.origin.y
	#we should turn and face the target first (before moving)
	var rotStrength = apply_rotation_to_look_toward($Legs,walkingTarget)
	if rotStrength > 0.15: #0.25 workd okay but overshoots I think, 0.15 tries to correct for the overshoot but cant do it becasue it has zoolander-itis
		return
	var strength = strengthMod*walkStrength*$Legs.mass #when I wasnt normalising it was walkStrength*$Legs.mass
	#$Legs.apply_central_impulse(stats.walkSpeed*strength*dir*delta)
	var offset = legOffset
	$Legs.apply_impulse(offset,stats.walkSpeed*strength*dir*delta)
	$Legs.applying_impulse = true
	#we should tell capsuleBase when we are applying an impulse
	#so it can calll its own integrate forces function to try and slow down




func do_melee_fight_state(delta, handPosNode, target):
	var heightMod = rand_range(0.9,1.6) #we dont want to swing at the floor we want to swing at the upper body
	#we only want to choose heightMod once
	var swingTarget = target + Vector3(0,heightMod,0) #technically it should be heightMod*floorNormal
	#var weaponPos = handPosNode.global_transform.origin# + weaponLength*weaponRef.basis.z #foreArm.basis.y points out of the hand independent of hand rotation so could be used
	var handToTargDist = swingTarget.distance_to(handPosNode.global_transform.origin)
	if extraAnimState == 0: #we are not swinging yet
		#print("need to wind up for the attack")
		var handPreparedDist = prepareTarget.distance_to(handPosNode.global_transform.origin)
		
		if handPreparedDist < 0.7 or handToTargDist > 0.5 + weaponLength: # was handToTargDist > 0.7
			#we are winded up, set the state to attacking and fix the sword pos by applying a slight force
			
			#print("we are winded up")
			#we are far enough to attack
			extraAnimState = 1 #we want to swing towards enemy
			extraAnimRand = rand_range(0.9,1.6)
			#swingTarget = extraAnimTarget + Vector3(0,heightMod,0) 
			var rightDir = (-1*$Legs.global_transform.basis.x)
			var upDir = $Legs.global_transform.basis.y
			var fixDir = rightDir + upDir #to stop the dsword getting stuck behind us
			#handPosNode.apply_central_impulse(0.2*fixDir)
			var offset = handPosNodeToHandDist*handPosNode.global_transform.basis.y
			handPosNode.apply_impulse(offset, 0.2*fixDir)
			
			yield(get_tree().create_timer(0.1), "timeout")
		else:
			#apply a force to move toward a better winded up position
			
			#print("winding up now")
			#var prepareTarget = swingTarget
			if extraAnimTime < 0.08:
				extraAnimRand = rand_range(0.7,1.8)
				prepareTarget = $Legs.global_transform.origin + extraAnimRand*Vector3(0,1,0) + 0.6*(-1*$Legs.global_transform.basis.x) + 0.3*(-1*$Legs.global_transform.basis.z) #-1x because we are on the right side
				#print("prepareTarget was set")
				extraAnimTime += 0.1
			#we need to swing away from target first, I should do this with more controlled positions as the arm generally ends up behind the head and then gets stuck
			var dir = prepareTarget - handPosNode.global_transform.origin
			#dir *= -1
			#dir += Vector3(0,2,0)
			##handPosNode.apply_central_impulse(15*dir*delta) 
			
			#handPosNode.apply_central_impulse(stats.swingSpeed*2*dir) 
			var offset = handPosNodeToHandDist*handPosNode.global_transform.basis.y
			handPosNode.apply_impulse(offset, stats.swingSpeed*2*dir)
			
			
			#handPosNode.apply_central_impulse(stats.swingSpeed*20*dir*delta) #15#-VE
	elif extraAnimState == 1: #we are mid swing
		#this is where we apply the force to swing towards the target
		
		#should I rotate while I swing
		var walkingTarget = target
		walkingTarget.y = $Legs.global_transform.origin.y
		apply_rotation_to_look_toward($Legs,walkingTarget)
		
		swingTarget = target + Vector3(0,extraAnimRand,0)
		#swingTarget is for the sword not for the hand
		var weaponRef = get_node_or_null("rightWeapon")
		if weaponRef == null: #it  breaks when I grab his weapon
			weaponRef = handPosNode
			weaponLength = 0
			#return #should just attack with fist now
		
		var handTarget = swingTarget - weaponRef.global_transform.basis.z*weaponLength#*weaponRef.length
		
		
		#method 1 distance check
#		if handToTargDist < 0.35: #we should do this using time instead of distance
#			#we are finished attacking
#			extraAnimState = 0
#			return
#			else:
#
#				var dir = swingTarget - handPosNode.global_transform.origin
#				handPosNode.apply_central_impulse(65*dir*delta)
#				print("trying to swing mah sword")
		
		#method 2 single impulse
		#if extraAnimTime == 0?
		var dir = handTarget - handPosNode.global_transform.origin
		dir = dir.normalized()
		#handPosNode.apply_central_impulse(stats.swingSpeed*7*dir) #was 4
		var offset = handPosNodeToHandDist*handPosNode.global_transform.basis.y
		handPosNode.apply_impulse(offset,stats.swingSpeed*7*dir)
		#handPosNode.apply_central_impulse(stats.swingSpeed*40*dir*delta)
		#print("trying to swing mah sword")
		yield(get_tree().create_timer(0.1), "timeout")
		extraAnimState = 0
		extraAnimTime = 0
	elif extraAnimState == 2: #WAIT STATE, waits 0.1 then goes back to initial swing state
		extraAnimTime += delta
		if extraAnimTime >= 0.1:
			extraAnimState = 0
			extraAnimTime = 0
	else:
		extraAnimState = 0 #for bugfixing


func apply_rotation_to_look_toward(nodeRef,target):
	#causes the model to zoolander and spin around heaps to do small turns.
	var vecToTarget = target - nodeRef.global_transform.origin
#	var strength = target.angle_to(nodeRef.global_transform.basis.z)
#	strength = signed_min_angle(strength)
	var strength = signed_min_angle2(nodeRef.global_transform.basis.z, vecToTarget)
	#print("applying rotation, strength = ", strength)
	var rotateVec = 1.0*strength*Vector3(0,1,0) #0.3*strength*Vector3(0,1,0) worked alright
	nodeRef.apply_torque_impulse(rotateVec)
	return strength

func signed_min_angle2(this, other):
	var angleVar = other.angle_to(this)
	var newAngle = angleVar
	if this.cross(other).dot(Vector3(0,1,0)) < 0:
		newAngle *= -1
	#print("signed min angle function, angleVar = ", angleVar, " newAngle = ",newAngle)
	return newAngle


func check_if_there_is_floor_ahead():
		#raycast down in front of your capsule base
		var distanceAhead = 2
		var startPos = $Legs.global_transform.origin + distanceAhead*$Legs.global_transform.basis.z + Vector3(0,0.1,0)
		#tempTarget.y = startPos.y
		#startPos.y = tempTarget.y
		var distanceMax = 1.1 #max drop distance
		var rayDir = Vector3(0,-1,0)
		#var finalDir = rayDir
		var endPos = rayDir*distanceMax
		#var actualEndPos = #$mixamorig_Hips.global_transform.origin
		var exceptions = [$Legs]#get_raycast_exceptions()
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(startPos, startPos+endPos, exceptions, 2)
		#var result = is_target_in_vision(extraAnimNode, false, 3)
		if !result:
			if floor_detected == true:
				$Legs.linear_damp = 100
				#$JOINT_mixamorig_Hips_mixamorig_capsuleBase. set force limits to 0
				floor_detected = false
			else:
				if $Legs.linear_damp > -1:
					$Legs.linear_damp -= 1
				else:
					$Legs.linear_damp = -1
			return false
			#there is no floor ahead of us
		else:
			floor_detected = true
			return true



func equip_weapon(weaponNode):#, hand):
	var picked_up_grav_scale = 0.1
	#weapons are rigidBodies with extra variables like attackLength
	weaponLength = weaponNode.attackLength
	#need to reparent to skelRagdoll if it is external
	var nameVar = "weapon"
	var bodyPart = dominantHand
#	var bodyPart = get_node_or_null("mixamorig_RightHand")
#	if hand == "left":
#		bodyPart = get_node_or_null("mixamorig_LeftHand")
#		nameVar = "leftWeapon"
	if bodyPart != null:
		weaponNode.global_transform.origin = bodyPart.global_transform.origin - weaponNode.get_node("grabPoint").translation
		spawn_a_joint(bodyPart, weaponNode, [])
		weaponNode.name = nameVar
		weaponNode.gravity_scale = picked_up_grav_scale




func spawn_a_joint(bodyPart, externalNode, jointConditions):
	print("spawning a joint as a child of bodyPart: ", bodyPart)
	var jointPos = bodyPart.global_transform.origin
	var joint = Generic6DOFJoint.new()
	var parent = bodyPart# self#skelRagdoll
	var bodyPath = str("../", parent.get_path_to(bodyPart))
	var externalPath = str("../", parent.get_path_to(externalNode))
	
	joint.set("nodes/node_a", bodyPath)
	#var spawnedSegmentMainRigidBody = segment.get_child(0).name #should probs do this in a better way
	#var pathToNode = bodyPart.get_path_to(externalNode)
	#print("in joint creation. Path to external node = ", pathToNode)
	joint.set("nodes/node_b", externalPath)
	#we are in czpsuleBase, we should probs add the joint as a child of skeletonRagdoll
	#add_child(joint) #I dont think this works because skelRagdoll doesnt move
	parent.add_child(joint)#perhaps I should make the joint a child of the handRigidBody
	#this helps the joint move around but the rotation isnt right
	joint.global_transform.origin = jointPos
	joint.name = str("grbJnt")
	
	dampen_joint(joint)
	
	for jointConditionDuo in jointConditions:
		var jointParameter = jointConditionDuo[0]
		var jointValue = jointConditionDuo[1]
		joint.set(jointParameter, jointValue)


func dampen_joint(joint):
	var dampValue = 16
	var softValue = 0.01
	var restiValue = 0.1
	for dim in ["x", "y", "z"]:
		var angLimString = str("angular_limit_",dim)
		joint.set(str("angular_limit_",dim,"/damping"), dampValue)
		joint.set(str("angular_limit_",dim,"/softness"), softValue)
		joint.set(str("angular_limit_",dim,"/restitution"), restiValue)
		joint.set(str("linear_limit_",dim,"/damping"), dampValue)


func take_damage(damage):
	var stunMultiplier = 0.01 #can be used as a resistance to stun
	
	health -= damage
	
	
#	if stunTime > 0:
#		stamina -= 2*damage
#	else:
#		stamina -= damage
	
	#we should also add a stun value so it doesnt 
	#keep doing non-essential physics process until un stunned
	
	var stunTimeMod = damage*stunMultiplier#0.05
	stunTimeMod = min(stunTimeMod,2)
	stunTime += stunTimeMod
	#should all body parts go to default gravity?
	for body in rigid_bodies:
		if body.get("temp_physics_override") != null:
			body.temp_physics_override = true
			body.phys_override_timer = 0
			body.stun_time = damage*0.1#0.1

func reparent_to_outside_my_scene(item):
	var oldTransform = item.global_transform
	var oldLinVel = item.linear_velocity
	var oldRotVel = item.angular_velocity
	var myParent = item.get_parent()
	myParent.remove_child(item)
	item.gravity_scale = 1
	var masterParent = get_parent()
	masterParent.add_child(item)
	item.global_transform = oldTransform
	item.linear_velocity = oldLinVel
	item.angular_velocity = oldRotVel
	#print("reparenting item = ", item, " oldParent = ", myParent, " newParent = ", masterParent, " actual new parent = ", item.get_parent())

func unequip_all():
	#print("unequipping things from dead body")
	var bodyParts = ["mixamorig_RightHand", "mixamorig_LeftHand", "mixamorig_RightForeArm", "mixamorig_LeftForeArm"]
	for bodyPartString in bodyParts:
		var bodyPart = get_node_or_null(bodyPartString)
		if bodyPart == null:
			continue
		if bodyPart.has_node(str("grbJnt")):
			var joint = bodyPart.get_node(str("grbJnt"))
			var nodePath = joint.get("nodes/node_b")
			var item = joint.get_node_or_null(nodePath)
			if item == bodyPart:
				#then choose the other thing connected to it
				nodePath = joint.get("nodes/node_a")
				item = joint.get_node_or_null(nodePath)
			if item == null:
				item = get_node_or_null("rightWeapon")
				if item != null:
					reparent_to_outside_my_scene(item)
					#duplicate_to_outside_my_scene(item)
				item = get_node_or_null("leftWeapon")
				if item != null:
					reparent_to_outside_my_scene(item)
					#duplicate_to_outside_my_scene(item)
			else:
				print("we actually found an item through good general method")
				reparent_to_outside_my_scene(item)
				#duplicate_to_outside_my_scene(item)
			joint.queue_free()





#var rigidBodiesFromBones = {
#	"mixamorig_Spine2" : "Body",
#	"mixamorig_Hips" : "Legs",
#	"mixamorig_Head" : "Head",
#	"mixamorig_LeftArm" : "ArmL",
#	"mixamorig_LeftForeArm" : "ForeArmL",
#	"mixamorig_RightArm" : "ArmR",
#	"mixamorig_RightForeArm" : "ForeArmR",
#}
#
#var actual_bones_used = rigidBodiesFromBones.keys()
#var rigidBodiesInitialTForms = {}
#var rigidBodiesInverseTForms = {}
#var boneInitialTForms = {}
#
#var skeleton_bones_sync = {
#	"mixamorig_Head": 5,
#	"mixamorig_Neck": 4,
#	# Trunk
#	"mixamorig_Spine2": 3,
#	"mixamorig_Spine1": 2,
#	"mixamorig_Spine": 1,
#	"mixamorig_Hips": 0,
#	# Right arm
#	"mixamorig_RightShoulder" : 19,
#	"mixamorig_RightArm": 20,
#	"mixamorig_RightForeArm": 21,
#	"mixamorig_RightHand": 22,
#	# Left arm
#	"mixamorig_LeftShoulder" : 7,
#	"mixamorig_LeftArm": 8,
#	"mixamorig_LeftForeArm": 9,
#	"mixamorig_LeftHand": 10,
#	# Right leg
#	"mixamorig_RightUpLeg": 38,
#	"mixamorig_RightLeg": 39,
#	"mixamorig_RightFoot": 40,
#	# Left leg
#	"mixamorig_LeftUpLeg": 33,
#	"mixamorig_LeftLeg": 34,
#	"mixamorig_LeftFoot": 35,
#	#other Fun Parts
#	"BreastRight" : 32,
#	"BreastLeft" : 31,
#}
#
#func get_initial_tforms():
#	for boneName in actual_bones_used:
#		var rigidBodyName = rigidBodiesFromBones[boneName]
#		var tForm = get_node(rigidBodyName).transform
#		rigidBodiesInitialTForms[rigidBodyName] = tForm
#		rigidBodiesInverseTForms[rigidBodyName] = tForm.affine_inverse() ##this tForm should have no scaling if we want normal inverse()
#		var skeleton = $SkeletonRagdoll
#		var boneIndex = skeleton_bones_sync[boneName]
#		boneInitialTForms[boneName] = skeleton.get_bone_global_pose(boneIndex) #returns transform relative to skeleton
#
#func deform_skeleton_with_rigidBodies_OLD(): #for this the default tfrom of bones has to be equal to default tfrom of rigidBodies
#	# Syncing skeleton bones with rigid bodies positions in case if we're using skinned mesh
#	#if using_mesh_with_skeleton:
#	var skeleton = $SkeletonRagdoll
#	#for key in skeleton_bones_sync:
#	for boneName in actual_bones_used:
#		#var skeleton_bones_sync = {
#		#"mixamorig_Head": 5, etc,...
#		var boneIndex = skeleton_bones_sync[boneName]
#		var rigid_body_match = get_node(rigidBodiesFromBones[boneName])
##		for rigid_body in rigid_bodies:
##			if rigid_body.name.find(key) > -1:
##				rigid_body_match = rigid_body
##				break
##		var final_transform = skeleton.get_bone_global_pose(value) #this was slowing things down significantly and it wasnt being used
##		if rigid_body_match.get_children().size() > 2:
##			#var joint = rigid_body_match.get_child(2)
##		var jointName = joint_sync.get(rigid_body_match.name)
##		if jointName != null:
##			var joint = get_node(jointName)
##			#final_transform = rigid_body_match.transform * joint.transform
##			final_transform = rigid_body_match.transform
##		else:
##			final_transform = rigid_body_match.transform
#		if rigid_body_match == null:
#			continue
#		var final_transform = rigid_body_match.transform
#		skeleton.set_bone_global_pose_override(boneIndex, final_transform, 1, true)
#	#fix_clothing_positions()
#
#
#func deform_skeleton_with_rigidBodies():
#	#this should do it for a general ragdoll, as long as we give it the bones to use
#	var skeleton = $SkeletonRagdoll
#	for boneName in actual_bones_used:
#		var boneIndex = skeleton_bones_sync[boneName]
#		var rB_name = rigidBodiesFromBones[boneName]
#		var rigid_body_match = get_node(rB_name)
#		if rigid_body_match == null:
#			continue
#		var rB_tForm_final = rigid_body_match.transform
#		var relative_tForm = rB_tForm_final*rigidBodiesInverseTForms[rB_name]
#		var final_bone_tForm = relative_tForm*boneInitialTForms[boneName]
#
#
#		skeleton.set_bone_global_pose_override(boneIndex, final_bone_tForm, 1, true)
#	#fix_clothing_positions()
