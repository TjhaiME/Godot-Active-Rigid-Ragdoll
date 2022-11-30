extends RigidBody
#need to move onto all middle bits of the body

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var last_linear_velocity = Vector3(0,0,0)
var dmgIndicPreload = null#preload("res://addons/rigidRagdoll/UI/DamageIndicator.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered", self, "my_body_entered")
	dmgIndicPreload = load("res://addons/rigidRagdoll/UI/DamageIndicator.tscn")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
var frameCount = 0
var update_frames = 2
func _physics_process(delta):
#	frameCount += 1
#	if frameCount == 2:
#		last_linear_velocity = linear_velocity
#		frameCount == 0
	pass

func my_body_entered_OLD(body):
	#is the body my weapon? for now this is sorted through get_parent (like bones) but we should keep a reference to our weapon when we equip it through code
	#is body one of my bones? 
	#print("my body entered")
	if body.get_parent() == get_parent():
		#print("parent is the same")
		return #body is one of my bones? 
	#compare my current velocity to the last_linear_velocity
	var velDif = linear_velocity.distance_to(last_linear_velocity)
	if velDif < 1:
		print("body entered but force too low, velDif = ", velDif)
		return
	#f=ma=mdv/dt = m(velDif)*(1.0/float(frameCount+1))*delta -> impulse = f/delta = fdt
	var impact_impulse = mass*(velDif)#*(1.0/float(frameCount+1))#*delta
	print("damage taken = ", impact_impulse, "\n by body : ", body.name," , ", body)
	#I need to do this woth torque too but I need to know how my moment of inertia affects me
	#print("linearVel = ", linear_velocity, "\n last_linear_velocity = ", last_linear_velocity, "\n  impact impulse = ", impact_impulse)
	#get_parent().stamina -= impact_impulse
	take_damage(impact_impulse)


func my_body_entered(body):
	#this way we dont need to record a value every frame
	#it seems stable producing values seemingly close to force values and within a reasonable range, then every now and again it gives me a HUGE number and it isnt reliable
	#if I were to use this method I would have to clamp it to a reasonable value that I could find, or find the huge value (probs the dot prduct)
	
	if check_exceptions(body) == false:
		#print("body ,", body," entered, ", self, " but there was an exception")
		return
	
	
#	if body.get_class() != "RigidBody":
#		return
#	if body.get_parent() == get_parent():
#		return #body is one of my bones?
	var m1 = body.mass
	var m2 = mass
	var initialBodyVel = (1.0/float(m1+m2))*(float(m1-m2)*body.linear_velocity + 2*m2*linear_velocity) #one dimensional approximation....probs bad
	var myInitialVel = (1.0/float(m1+m2))*(2*m1*body.linear_velocity + float(m2-m1)*linear_velocity)
	
	#var weaponMomentumBeforeCollision = m1*initialBodyVel#.length()
	
	#var impactScalarApproxValue = m1*(initialBodyVel.length() + initialBodyVel.dot(myInitialVel))
	var impactScalarApproxValue = m1*(initialBodyVel.length()) + m1*abs(initialBodyVel.dot(myInitialVel.normalized()))
	#print("impactScalarApproxValue = ", impactScalarApproxValue)
	
	#print("damage taken = ", impactScalarApproxValue, "\n by body : ", body.name," , ", body)
	#I need to do this woth torque too but I need to know how my moment of inertia affects me
	#print("linearVel = ", linear_velocity, "\n last_linear_velocity = ", last_linear_velocity, "\n  impact impulse = ", impact_impulse)
	#get_parent().stamina -= impactScalarApproxValue
	take_damage(impactScalarApproxValue)
	if impactScalarApproxValue > 7.5:
		spawn_blood_spurt(body)

func spawn_blood_spurt(body):
	#spawn a blood spurt
	#check all collisions
	#var colBodies = get_colliding_bodies()
	
	#get bodys position and find a position on our collisionBox that is close to it
	#then spawn the blood spurt there
	var bodyPos = body.global_transform.origin
	var finalPos = global_transform.origin
	var myColShape = $CollisionShape.shape
	var startPos = $CollisionShape.global_transform.origin
	var dir = bodyPos - startPos
	dir = dir.normalized()
	if myColShape.get("radius") != null:
		#then probs sphere or cylinder
		var radius = myColShape.get("radius")
#		var dir = bodyPos - startPos
#		dir = dir.normalized()
		finalPos = startPos + radius*dir
		
		
	else:
		#assume it is a box
		var scaleVec = myColShape.get("extents")
		if scaleVec != null:
			var x = clamp(bodyPos.x, startPos.x-scaleVec.x, startPos.x+scaleVec.x)
			var y = clamp(bodyPos.y, startPos.y-scaleVec.y, startPos.y+scaleVec.y)
			var z = clamp(bodyPos.z, startPos.z-scaleVec.z, startPos.z+scaleVec.z)
			finalPos = Vector3(x,y,z)
	
	#spawn blood spurt at finalPos with it's z direction facing dir
	var bloodSpurt = get_parent().bloodSpurtLoad.instance()
	add_child(bloodSpurt)
	bloodSpurt.global_transform.origin = finalPos
	bloodSpurt.look_at(bodyPos, Vector3(0,1,0))
	bloodSpurt.rotate(Vector3(0,1,0), PI)

func take_damage(damage):
	var physRes = 0.3
	damage -= physRes
	if damage < 0:
		damage = 0
		return
		
	get_parent().take_damage(damage)
	
	####### attempting to make attack feedback feel better
	temp_physics_override = true
	phys_override_timer = 0
	stun_time = damage*0.1
	
	
	
	return
	
	
	
	
	#spawn damage indicator #this is a slow way of doing things but good for testing in VR
	var dmgIndic = dmgIndicPreload.instance()
	add_child(dmgIndic) #cant be child of rigidBody as it just stays hidden, need to move it  so its seen
	#human radius is about 0.2
	var damageVal = 0.1*(floor(10*damage))
	dmgIndic.update_label(str(damageVal))
	dmgIndic.global_transform.origin = dmgIndic.global_transform.origin + 0.2*Vector3(dmgIndic.dir,0,0) 
	
	#for fun
	var speechBubble = get_node_or_null("HeadAttachment/SpeechBubble")
	if speechBubble != null:
		get_parent().get_node("HeadAttachment/SpeechBubble").generate_insult()


#to possibly optimise we could put all the damage to the body to collect over a frame so it only spawns 1 damage indicator per frame
#

#these two functions can take up a lot of time if a lot of things call them in a frame, maybe we could average it out

func check_exceptions(body):
	var my_parent = get_parent()
	var their_parent = body.get_parent()
	if body.get_class() != "RigidBody":
		return false
	if my_parent == their_parent:
		return false#body is one of my bones?
	if their_parent.get("faction") != null:
		if my_parent.faction == their_parent.faction:
			#print("friendly fire between, ", body, " and , ", self)
			#what about friendly fire
			#this is difficult as we need to make a faction variable somewhere
			#if its parent is a skeleton node then we are being hit by someone, most likely we are next to someone and bumping into them
			#also if its parent is a skeleton node then it is skeletonRagdoll and we have a place to attempt to look for a faction variable
			#my parent which is a skeletonRagdoll would have this value too
			return false
	
	return true


var physics_override_on_death = false
var temp_physics_override = false
var phys_override_timer = 0
var stun_time = 0.1
var original_gravity_scale = gravity_scale
func _integrate_forces(state):
	if physics_override_on_death == true:
		gravity_scale = 1 #on normal body parts we dont want to change the mass
		physics_override_on_death = false
		return
	####################################3
	elif temp_physics_override == true:
		if phys_override_timer == 0:
			gravity_scale = 1
			phys_override_timer += state.step
		elif phys_override_timer > stun_time:
			phys_override_timer = 0
			gravity_scale = original_gravity_scale
			temp_physics_override = false
		else:
			phys_override_timer += state.step
