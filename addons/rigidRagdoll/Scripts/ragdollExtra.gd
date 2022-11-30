extends "res://addons/rigidRagdoll/Scripts/ragdollBase.gd"


#here I will put verious physics driven animation code



var my_skel = null
var my_headNode = null
var basePosNode = null #could be a singular ffoot or hips
var floorPos = Vector3(0,0,0) #where I am on the floor, if basePosNode is hips then we need to ssubtract hips height

var dominantHand = null
var handPosNodeToHandDist = 0
var baseAnimTime = 0 #we need a different timer for death because yield functions resume

var total_weight = 30


var faction = 0
#var stats = { #this is wrong but this is what my calculations led to
#	swingSpeed = 0.5,
#	walkSpeed = 0.5,
#}
var stats = {
	"swingSpeed" : 0.35,
	"walkSpeed" : 0.5,
}

# Called when the node enters the scene tree for the first time.
#func _ready():
#


func parent_is_ready():
	var hand = "right"
	if randi()%3 == 0:
		hand = "left"
	#get_dominant_hand(hand)
	get_dominant_hand(hand) #Can we even put this here or has my_skel not been declared yet?
	pass # Replace with function body.
	total_weight = get_total_weight()
	_set_up()

func get_total_weight():
	#a 1d vector version of get_mass
	#not actually weight as it isnt multiplied by the gravity value, only the gravity scale
	var total_weight = 0
	for childIndex in my_skel.get_child_count():
		var child = my_skel.get_child(childIndex)
		if child.get_class() == "RigidBody":
			var childWeight = child.gravity_scale*child.mass
			total_weight += childWeight
		
	return total_weight
		


func get_dominant_hand(hand):
	# a way of transfering animations from one physics LOD to another
	if dominantHand != null:
		return
	
	var bodyPart = my_skel.get_node_or_null("RightHand")
	if hand == "left":
		bodyPart = my_skel.get_node("LeftHand")
	if bodyPart != null:
		pass
		
	else:
		bodyPart = my_skel.get_node_or_null("RightForeArm")
		handPosNodeToHandDist = 0.3
		if hand == "left":
			bodyPart = my_skel.get_node("LeftForeArm")
		
	dominantHand = bodyPart

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	#floorPos = basePosNode.global_transform.origin += offset, do this in actual ragdoll script
#	pass


var extraAnimBool = false
var extraAnimString = "null"
var extraAnimTarget = Vector3(0,0,0)
var extraAnimTime = 0
var extraAnimNode = null
var extraAnimState = 0
var extraAnimRand = 0
var walkStrength = 10.0

func extra_animations(delta):
	if extraAnimBool == false:
		return
	
#	if extraAnimString == "null":
#		return
	
	if has_method(extraAnimString):
		call(extraAnimString, delta)


func is_target_in_vision(targetNode, areaBool, collisionInteger):
#	if is_instance_valid(targetNode) == false:
#		targetNode = null
#		return
	var tempTarget = targetNode.global_transform.origin
	var startPos = my_headNode.global_transform.origin#floorPos
	#tempTarget.y = startPos.y
	#startPos.y = tempTarget.y
	var distanceMax = 15
	var dir = (tempTarget - startPos).normalized()
	var finalDir = dir
	var endPos = dir*distanceMax
	#var actualEndPos = #$mixamorig_Hips.global_transform.origin
	var exceptions = []#get_raycast_exceptions()
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(startPos, startPos+endPos, exceptions, collisionInteger, true, areaBool)
	var returnVal = null
	if result:
		#print("we hit ", result.collider, " target was ", targetNode)
#		if result.collider.get_collision_layer_bit(1) == true:
#			#then it is a wall
#			return returnVal
		if result.collider == targetNode:
			#we hit our target
			return result
	return null




func rotate_eyes_toward(targetPos):
	var eyes = $SkeletonRagdoll/HeadAttachment/EyeSpatial
	if eyes == null:
		return
	for childIndex in eyes.get_child_count():
		var eye = eyes.get_child(childIndex)
		eye.look_at(targetPos, Vector3(0,1,0))
		eye.rotate_y(PI)





var prepareTarget = Vector3(0,0,0) #bad solution
var weaponLength = 0.6
var rangedAtkRange = 10.0

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
		extraAnimString = "anim_alert_state"
		extraAnimTime = 0
		return
	###############################################
	
	var target = targetNode.global_transform.origin
	rotate_eyes_toward(target+Vector3(0,1.7,0))
	var distanceToTarget = target.distance_to(floorPos)
	var moveBackThreshold = weaponLength
	if distanceToTarget > 0.9 + weaponLength: #distance too large
		do_walk_direct_to_target(delta, target)
		print("walking TO target")
		#change to do_walk_in_direction_with_strength
	elif distanceToTarget < moveBackThreshold: #distance too small
		do_walk_away_from_target(delta, target)
		print("walking back from target")
	else: # distanceToTarget < 0.9 + weaponLength:#0.9: #1.5 is for testing out of VR so I can see, but in VR it still felt waay to close and not needed if we are swinging a sword
		#we are close enough to swing (not walk), we need to check if our hand is far enough away
		do_melee_fight_state(delta, handPosNode, target)
		#maybe here we could check if we have a ranged weapon
		#if it does then do a ranged attack instead



var check_floor_ahead = true
var floor_detected = false
func do_walk_direct_to_target(delta, target):
	print("walking toward target")
	
	var dir = target - floorPos
	do_walk_in_direction_with_strength(dir,delta,0.7)
	return
#
#
#
#	#var target = extraAnimTarget
#	var walkingTarget = target
#	walkingTarget.y = floorPos.y
#	#we should turn and face the target first (before moving)
#	var rotStrength = apply_rotation_to_look_toward(basePosNode,walkingTarget)
#	if rotStrength > 0.15: #0.25 workd okay but overshoots I think, 0.15 tries to correct for the overshoot but cant do it becasue it has zoolander-itis
#		basePosNode.linear_damp = 0.5
#		return
#	else:
#		basePosNode.linear_damp = -1
#	var mylinVel = basePosNode.linear_velocity
#	if mylinVel.length_squared() > 25:
#		#attempt to limit max speed
#		return
#	#walking towards
#	#var walkingTarget = extraAnimTarget
#	#walkingTarget.y = 0
#
#	if check_floor_ahead == true:
#		var safe_to_move = check_if_there_is_floor_ahead()
#		if safe_to_move == false:
#			return
#		#then there is floor ahead of me and I can safely move forward
#
##	var dir = target - floorPos
##	dir = dirVec.normalized()
#
#	var dirVec = target - floorPos
#	var dirLength = dirVec.length() #so the speed is constant and not distance based
#	if dirLength < 1:
#		basePosNode.linear_damp = 1
#	else:
#		basePosNode.linear_damp = -1
#	var dir = (1.0/float(dirLength))*dirVec
##	if dirLength > 0.5:
##		return
#
#	#var strength = 1.5*walkStrength*basePosNode.mass #when I wasnt normalising it was walkStrength*basePosNode.mass
#
#	var strength = 0.7*walkStrength*total_weight
#
#	#basePosNode.look_at(walkingTarget, Vector3(0,1,0)) #this fucks with joints, capsuleBase seems to stay in the same spot
#	#apply_rotation_to_look_toward(basePosNode,walkingTarget)
#	basePosNode.apply_central_impulse(stats.walkSpeed*strength*dir*delta)
#	if basePosNode.get("applying_impulse") != null:
#		basePosNode.applying_impulse = true
#	#basePosNode.apply_torque_impulse()


func do_walk_away_from_target(delta, target):
	var dir = target - floorPos
	do_walk_in_direction_with_strength(dir,delta,-0.7)


func do_walk_in_direction(dir,delta):
	#ONLY FOR SINGLE CAPSULE FOOT, OVERRIDE FOR OTHER RAGDOLLS
	do_walk_in_direction_with_strength(dir,delta, 1.5)
#	

func do_walk_in_direction_with_strength(dir,delta, strengthMod):
	#ONLY FOR SINGLE CAPSULE FOOT, OVERRIDE FOR OTHER RAGDOLLS
	#print("walking in direction, ", dir)
	var walkingTarget = floorPos + dir
	walkingTarget.y = floorPos.y
	#we should turn and face the target first (before moving)
	var rotStrength = apply_rotation_to_look_toward(delta,basePosNode,walkingTarget)
	if rotStrength > 0.15: #0.25 workd okay but overshoots I think, 0.15 tries to correct for the overshoot but cant do it becasue it has zoolander-itis
		return
	var strength = strengthMod*walkStrength*basePosNode.mass #when I wasnt normalising it was walkStrength*basePosNode.mass
	basePosNode.apply_central_impulse(stats.walkSpeed*strength*dir*delta)
	if basePosNode.get("applying_impulse") != null:
		basePosNode.applying_impulse = true
	#we should tell capsuleBase when we are applying an impulse
	#so it can calll its own integrate forces function to try and slow down





func do_melee_fight_state(delta, handPosNode, target):
	#print("stats = ", stats.swingSpeed)
	var heightMod = 1.2#rand_range(0.9,1.6) #we dont want to swing at the floor we want to swing at the upper body
	#we only want to choose heightMod once (we have to do it elsewhere fo that)
	var swingTarget = target + Vector3(0,heightMod,0) #technically it should be heightMod*floorNormal
	#var weaponPos = handPosNode.global_transform.origin# + weaponLength*weaponRef.basis.z #foreArm.basis.y points out of the hand independent of hand rotation so could be used
	var handToTargDist = swingTarget.distance_to(handPosNode.global_transform.origin)
	if extraAnimState == 0: #we are not swinging yet
		#print("need to wind up for the attack")
		var handPreparedDist = prepareTarget.distance_to(handPosNode.global_transform.origin)
		
		if handPreparedDist < 0.7 or handToTargDist > 0.5 + weaponLength: # was handToTargDist > 0.7
			#we are winded up, set the state to attacking and fix the sword pos by applying a slight force
			
			print("we are winded up")
			#we are far enough to attack
			extraAnimState = 1 #we want to swing towards enemy
			extraAnimRand = rand_range(0.9,1.6)
			#swingTarget = extraAnimTarget + Vector3(0,heightMod,0) 
			var rightDir = (-1*basePosNode.global_transform.basis.x)
			var upDir = basePosNode.global_transform.basis.y
			var fixDir = rightDir + upDir #to stop the dsword getting stuck behind us
			#handPosNode.apply_central_impulse(0.2*fixDir)
			var offset = handPosNodeToHandDist*handPosNode.global_transform.basis.y
			handPosNode.apply_impulse(offset, 0.2*stats.swingSpeed*fixDir)
			#basePosNode.angular_damp = -1
			#yield(get_tree().create_timer(0.1), "timeout")
		else:
			#apply a force to move toward a better winded up position
			
			print("winding up now")
			#var prepareTarget = swingTarget
			if extraAnimTime < 0.08:
				extraAnimRand = rand_range(0.7,1.8)
				prepareTarget = floorPos + extraAnimRand*Vector3(0,1,0) + 0.6*(-1*basePosNode.global_transform.basis.x) + 0.3*(-1*basePosNode.global_transform.basis.z) #-1x because we are on the right side
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
		walkingTarget.y = floorPos.y
		#apply_rotation_to_look_toward(delta,basePosNode,walkingTarget)
		#print("rotating while we swing")
		swingTarget = target + Vector3(0,extraAnimRand,0)
		#swingTarget is for the sword not for the hand
		var weaponRef = my_skel.get_node_or_null("rightWeapon")
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
		#basePosNode.angular_damp = 1
		set_stabilise_var(basePosNode,true)
		#handPosNode.apply_central_impulse(stats.swingSpeed*40*dir*delta)
		print("trying to swing mah sword")
		#yield(get_tree().create_timer(0.1), "timeout")
		extraAnimState = 2
		extraAnimTime = 0
	elif extraAnimState == 2: #WAIT STATE, waits 0.1 then goes back to initial swing state
		print("wait state")
		extraAnimTime += delta
		if extraAnimTime >= 0.1:
			extraAnimState = 0
			extraAnimTime = 0
			#basePosNode.angular_damp = -1
			set_stabilise_var(basePosNode,false)
	else:
		extraAnimState = 0 #for bugfixing

func set_stabilise_var(nodeRef,boolVal):
	if nodeRef.get("stabilise") == null:
		return
	nodeRef.stabilise = boolVal

func apply_rotation_to_look_toward(delta,nodeRef,target):
	#causes the model to zoolander and spin around heaps to do small turns.
	var myPos = nodeRef.global_transform.origin
	myPos.y = target.y
	var vecToTarget = target - myPos
#	var strength = target.angle_to(nodeRef.global_transform.basis.z)
#	strength = signed_min_angle(strength)
	var strength = signed_min_angle2(nodeRef.global_transform.basis.z, vecToTarget)
	#print("applying rotation, strength = ", strength)
	
#	#NO DELTA
#	var rotateVec = 1.0*strength*Vector3(0,1,0) #0.3*strength*Vector3(0,1,0) worked alright
#	nodeRef.apply_torque_impulse(rotateVec)
	
	#DELTA
	var rotateVec = 1.0*nodeRef.mass*strength*Vector3(0,1,0) #0.3*strength*Vector3(0,1,0) worked alright
	nodeRef.apply_torque_impulse(rotateVec*delta)
	
	return strength

func signed_min_angle2(this, other):
	var angleVar = other.angle_to(this)
	var newAngle = angleVar
	if this.cross(other).dot(Vector3(0,1,0)) < 0:
		newAngle *= -1
	#print("signed min angle function, angleVar = ", angleVar, " newAngle = ",newAngle)
	return newAngle

func spawn_and_equip(filePath):
	var weaponLoad = load(filePath)
	var weaponNode = weaponLoad.instance()
	my_skel.add_child(weaponNode)
	var dominantHandSide = "right"
	var domHand = dominantHand
	if domHand == my_skel.get_node_or_null("LeftHand"):
		dominantHandSide = "left"
	equip_weapon(weaponNode, dominantHandSide)

#func extra_animations(delta):
#	if extraAnimBool == false:
#		return
#
##	if extraAnimString == "null":
##		return
#
#	if has_method(extraAnimString):
#		call(extraAnimString, delta)



func equip_weapon(weaponNode, hand):
	var picked_up_grav_scale = 0.1
	#weaponNode.mass = 0.1#TEST
	#weapons are rigidBodies with extra variables like attackLength
	weaponLength = weaponNode.attackLength
	#need to reparent to skelRagdoll if it is external
	var nameVar = "rightWeapon"
	var bodyPart = my_skel.get_node_or_null("RightHand")
	if hand == "left":
		bodyPart = my_skel.get_node_or_null("LeftHand")
		nameVar = "leftWeapon"
	if bodyPart != null:
		weaponNode.global_transform.origin = bodyPart.global_transform.origin - weaponNode.get_node("grabPoint").translation
		spawn_a_joint(bodyPart, weaponNode, [])
		weaponNode.name = nameVar
		weaponNode.gravity_scale = picked_up_grav_scale
	else: #we dont have hands
		
		bodyPart = my_skel.get_node("RightForeArm")
		if hand == "left":
			bodyPart = my_skel.get_node("LeftForeArm")
		if bodyPart == null:
			if dominantHand != null:
				bodyPart = dominantHand
		var node = bodyPart.get_node_or_null("CollisionShape2")
		if node == null:
			node = bodyPart
		var spawnPos = node.global_transform.origin
		weaponNode.global_transform.origin = spawnPos - weaponNode.get_node("grabPoint").translation
		spawn_a_joint(bodyPart, weaponNode, [])
		weaponNode.name = nameVar
		weaponNode.gravity_scale = picked_up_grav_scale



