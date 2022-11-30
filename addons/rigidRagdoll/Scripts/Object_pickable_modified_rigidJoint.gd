extends RigidBody

#code by Bastiaan Olij
#Tutorial at https://youtu.be/gPVXwwvxlzs?t=384

#original rewrite was Object_pickable_modified
#it was meant for kinematicPlayer picking up rigidBodies

#we want to rewrite for a rigidRagdollPlayerController who picks things up through joints
#a lot should be able to be done by default

#weapons like polearms and swords must point their poles toward the -ve z axis to align properly with controllers
#the curved attack part of weapons like axes or daggers must be pointing toward the -ve x axis

#  sword      <-z   --|-------- 
#
#   pretend this is an axe --------/^^^^\ ( up-^ = -x , down-v = +x )


# Set hold mode
export (bool) var press_to_hold = true
export (bool) var reset_transform_on_pickup = false
export (NodePath) var center_pickup_on = null
export (NodePath) var highlight_mesh_instance = null
export (int, LAYERS_3D_PHYSICS) var picked_up_layer = 0b00000100000000000000 #I have set this to only bit 15 #was originally 0

# Remember some state so we can return to it when the user drops the object
onready var original_parent = get_parent()
onready var original_collision_mask = collision_mask
onready var original_collision_layer = collision_layer
var sheathed_item_layer = 5#I dont know just transferring files

onready var highlight_material = preload("res://addons/rigidRagdoll/Scripts/highlightMaterial.tres")
var original_materials = Array()
var highlight_mesh_instance_node : MeshInstance = null

# Who picked us up?
var picked_up_by = null
var center_pickup_on_node = null
var by_controller = null #: ARVRController = null #was ARVRController type, but we just need a node reference don't we?
var closest_count = 0

var closest_to_sheathe_count = 0 #closest count but for sheath functions
var adjacent_sheathe_slot = null #store the sheathe slot we are close to, because the sheath function is called through Function_Pickup
var current_sheathe_slot = null

var trying_to_teleport = false
var teleported_linear_velocity = Vector3.ZERO
var previous_linear_velocity = Vector3.ZERO
var teleport_transform = Transform()

var original_gravity_scale = 1
var original_linear_damp = -1
var original_angular_damp = -1

#Custom throwable explosive items
var do_action_when_thrown = false
var speed_on_release = 0

var is_melee_weapon = false
var hitbox = null
var hitbox_collision_mask = 32+64 #hit player and enemy by default
var hitbox_collision_layer = 128+256 
var reset_hitbox_collision_mask_bool = false
var reset_hitbox_collision_mask_timer = 5
var is_parry_object = false
var parrybox = null

var trying_to_move = false
var velocity_to_controller = Vector3(0,0,0)

var original_mode = RigidBody.MODE_RIGID #so this can be overwritten by the actual items script if needed

var joint_node_ref = null
var precision_grab = false #required for objects like paintbrushes that have better gameplay when they are non physical objects

# have we been picked up?
func is_picked_up():
	if picked_up_by:
		return true

	return false

func _update_highlight():
	if highlight_mesh_instance_node:
		
		#print("passed first if in update_highlight")
		# if we can find a node remember which materials are currently set on each surface
		#I keep getting glitches here where it tells me a lot of variables are null including highlight_mesh_instance_node so maybe I should do a null check
		#since deleting items on throw
		for i in range(0, highlight_mesh_instance_node.get_surface_material_count()):
			#if not picked up then do this default one
			if is_picked_up() == false:
				if closest_count > 0:
					highlight_mesh_instance_node.set_surface_material(i, highlight_material)
				else:
					highlight_mesh_instance_node.set_surface_material(i, original_materials[i])
					
			elif is_picked_up() == true:
				if closest_to_sheathe_count > 0:
					highlight_mesh_instance_node.set_surface_material(i, highlight_material) #should make a material colour for sheathing specifically
				else:
					highlight_mesh_instance_node.set_surface_material(i, original_materials[i])
					
	else:
		print("big else statement in update_highlight")
		# should probably implement this in our subclass
		pass

func increase_is_closest():
	closest_count += 1
	_update_highlight()

func decrease_is_closest():
	closest_count -= 1
	_update_highlight()

func drop_and_free():
	if picked_up_by:
		picked_up_by.drop_object()

	queue_free()

# we are being picked up by...
func pick_up(by, jointed_body): #by is playerItemMaster, #jointed_body is the thing it is jointed to
	#print("we have sucsessfully picked something up")
	#by_controller = jointed_body.target
	pass
	#print("in objects pick up function")
	if picked_up_by == by: #have we already been picked up by this character
		return null

	if picked_up_by: #if we are already picked up by another object, then call let_go function first
		let_go()
			

	var newParent = by
	var newAngularDamp = 0.5
	if precision_grab == true:
		#precision_pick_up()
		newParent = jointed_body.target


#deal with sheathe variables
	var reset_transform_on_this_pickup = reset_transform_on_pickup
	var center_pickup_on_node_thisTime = center_pickup_on_node
	
	if current_sheathe_slot: #is not null #If the item is sheathed then we remove the data saying it is sheathed
		#print("picking up a sheathed object")
		mode = MODE_RIGID
		current_sheathe_slot.object_in_sheathe = null
		current_sheathe_slot.removed_from_sheathe(self)
		current_sheathe_slot = null
		#so we can pick it up from any spot on the sheathe and it will pick up nicely
		reset_transform_on_this_pickup = false#true was true
		center_pickup_on_node_thisTime = true#true #try false
		collision_layer = original_collision_layer#is sheathed item layer if its sheathed, we need to reset it
	else: #hopefully this means we are not picking up a sheathed object, then we copy it's gravity from the world around us
		pass#we will still be able to glitch the game and pick up objects with different gravity from a boost pad or store an item from a room with less gravity...it's not a bug it's a feature
#		original_gravity_scale = gravity_scale
#		gravity_scale = 0
#		#to stop potantial movement when in hand?
		original_linear_damp = linear_damp
		original_angular_damp = angular_damp
		var damp_mult = 50
		
		#method 0
		#, sword still rotates weirdly when in hand, I be think'n' it's because these values are negative
#		linear_damp = original_linear_damp*damp_mult 
#		angular_damp = original_angular_damp*damp_mult
		
		
		#method 1
		
		#if this is weird then comment out linear_damp line, rotation may be my main issue
		#linear_damp = abs(original_linear_damp)*damp_mult 
		#angular_damp = abs(original_angular_damp)*damp_mult
		######angular_damp = 1#0.5 #4 is too much, default is too little #a little bit of extra movement on the sword is okay
		
		#method 2
#		if sign(original_linear_damp) == -1:
#			pass
#		else:
#			linear_damp = original_linear_damp*damp_mult #100 #we need to slow the sword down when we swing it to simulate us having the strength to stop the motion
#		if sign(original_angular_damp) == -1:
#			#From DOCs : 
#			#If this value is different from -1.0 it will be 
#			#ADDED to any angular damp derived from the world or areas.
#		else:
#			angular_damp = original_angular_damp*damp_mult #100

	# remember who picked us up
	picked_up_by = by
	by_controller = jointed_body
	
	if "held_item" in jointed_body:
		jointed_body.held_item = self

#	if is_melee_weapon == true: #the damage is now dealt with impacts
#		#the hitbox may still be useful to add extra impact to strong/sharp objects
#		if picked_up_by == vars.player_item_parent:
#			vars.melee_weapons_held_by_player += 1
#			hitbox_collision_mask = vars.player_weapon_collision_mask
#			hitbox_collision_layer = 128 #be a player weapon
#		hitbox.collision_mask = hitbox_collision_mask
#		hitbox.collision_layer = hitbox_collision_layer
#
#	if is_parry_object == true:
#		parrybox.collision_layer = 65536
#		parrybox.collision_mask = 65536
	

	# turn off physics on our pickable object
	linear_velocity = Vector3.ZERO #this lets us "absorb" all kinetic energy when catching something

	##################
	#mode = RigidBody.MODE_CHARACTER #was STATIC #CANNOT DO THIS FOR JOINTED BODY
	#mode = RigidBody.MODE_KINEMATIC
	#probably shouldnt change the layers and maks either
	
	#had these two on before
	#collision_layer = vars.kinematic_picked_up_layer #I put it on this to test collision in held objects it was originally #vars.picked_up_layer
	#collision_mask = 1+2+16384
	
	
	#collision_mask = 16384 #2^14 so it is the 14th layer which is picked_up_layer
	#original_gravity_scale = gravity_scale
	#gravity_scale = 0

	# now reparent it to the itemMasterNode, so it will move with us through scene transfers
	var original_transform = global_transform
	#maybe we need to do more than just remove
	get_parent().remove_child(self) #we want to be able to access this from sheathed weapons too, originally it was #original_parent.remove_child(self) #but that did not work when we had moved it to the sheathe slot
	newParent.add_child(self)
	
	if reset_transform_on_this_pickup:
		if center_pickup_on_node_thisTime:
			transform = center_pickup_on_node.global_transform.inverse() * global_transform
			#I dont think this transform settrer works for my items
		else:
			# reset our transform
			transform = Transform()
	else:
		# make sure we keep its original position
		global_transform = original_transform
	if has_method("special_fix_transform_on_pickup"):
		call("special_fix_transform_on_pickup")
	print("finished pick up code on object")
	
	return self

# we are being let go
#func let_go_old(p_linear_velocity = Vector3(), p_angular_velocity = Vector3()):
#	if picked_up_by: #we only want to do the let_go function if we were picked up
#
#		if adjacent_sheathe_slot != null:
#			sheathe()
#			return
#
#		speed_on_release = p_linear_velocity.length() #so I can record velocity objects are released at so I don't have to undertsnad get_contact_impulse()
#		# get our current global transform
#		var t = global_transform
#
##		if is_melee_weapon == true:
##			if picked_up_by == vars.player_item_parent:
##				#if we are a melee weapon we want to know how many for dual wielding stat decreases if we want to
##				vars.melee_weapons_held_by_player -= 1 #letting go
##				#start a timer to turn off the player hitbox
##			reset_hitbox_collision_mask_bool = true
##			reset_hitbox_collision_mask_timer = 5
#
#		# reparent it
#		picked_up_by.remove_child(self)
#		var new_parent = null#vars.current_area
#		if new_parent == null: #if there is no current_area
#			if is_instance_valid(original_parent):
#				new_parent = original_parent
#			else:
#				new_parent = get_tree().get_current_scene() #dump it on the master
#		new_parent.add_child(self) #original_parent isn't good for scene switching
#
#		# reposition it and apply impulse and change other physics values back to original
#		global_transform = t #reassigning our global_trassform after reparenting object
##		mode = original_mode #RigidBody.MODE_RIGID
#		gravity_scale = original_gravity_scale
#		linear_damp = original_linear_damp
#		angular_damp = original_angular_damp
##		collision_mask = original_collision_mask
##		collision_layer = original_collision_layer
#
#		# set our starting velocity #this bit is not in the tutorial, But it seems to take the place of apply_impulse()
#		#This should be handled by just removing the joint
#		linear_velocity = p_linear_velocity
#		angular_velocity = p_angular_velocity
#
#		# we are no longer picked up
#		picked_up_by = null
#		by_controller = null
#
#		if "held_item" in by_controller:
#			by_controller.held_item = null
#
#		#######################################################
#		#Custom throwing code
#		#####################################################
#		#so here we have been thrown so I need to find a way to start running a physics_process to check for collisions and when I collide
#		#I play my desired effect, e.g. explode the bomb
#		print("item let go")
#		if do_action_when_thrown == true:
#			print("custom item should try to connect signal now")
#			contact_monitor = true #this is high level shit here, I am scared (me not Bastiaan),....update  year later I'm not as scared especially since I took precautions and only activated this for throwables when thrown
#			contacts_reported = 1
#			connect("body_entered", self, "on_impact")
#			#we need to check the impact of the collision so we can safely put down explosives but this will have to be handled in each individual item
#		collision_mask = 0
#		collision_layer = 0
#		yield(get_tree().create_timer(0.1), "timeout")  #will this work to allow us to have no collision until it is thrown
#		collision_mask = original_collision_mask
#		collision_layer = original_collision_layer
#
#		return self

func let_go(p_linear_velocity = Vector3(), p_angular_velocity = Vector3()):
	#new version of let_go where we duplicate the item we are throwing
	
	if picked_up_by: #we only want to do the let_go function if we were picked up
		
		if adjacent_sheathe_slot != null:
			sheathe()
			return
	
		var newMe = self#.duplicate()#self (without duplicate()) should be same as old version, self.duplicate() leads t a nicer throwing but it ends up with issues with get_surface_count()
		
		
		
		# get our current global transform
		var t = global_transform

#		if is_melee_weapon == true:
#			if picked_up_by == vars.player_item_parent:
#				#if we are a melee weapon we want to know how many for dual wielding stat decreases if we want to
#				vars.melee_weapons_held_by_player -= 1 #letting go
#				#start a timer to turn off the player hitbox
#			reset_hitbox_collision_mask_bool = true
#			reset_hitbox_collision_mask_timer = 5
	
		# reparent it
		
		var new_parent = null#vars.current_area
		if new_parent == null: #if there is no current_area
			if is_instance_valid(original_parent):
				new_parent = original_parent
			else:
				new_parent = get_tree().get_current_scene() #dump it on the master
		picked_up_by.remove_child(self) #have to do this after get_tree()
		new_parent.add_child(newMe) #original_parent isn't good for scene switching
		if newMe != self:
			add_collision_exception_with(newMe)
		# reposition it and apply impulse and change other physics values back to original
		newMe.global_transform = t #reassigning our global_trassform after reparenting object
#		mode = original_mode #RigidBody.MODE_RIGID
		newMe.gravity_scale = original_gravity_scale
		newMe.linear_damp = original_linear_damp
		newMe.angular_damp = original_angular_damp
#		collision_mask = original_collision_mask
#		collision_layer = original_collision_layer

		# set our starting velocity #this bit is not in the tutorial, But it seems to take the place of apply_impulse()
		#This should be handled by just removing the joint
#		newMe.linear_velocity = p_linear_velocity
#		newMe.angular_velocity = p_angular_velocity
		newMe.apply_central_impulse(mass*p_linear_velocity*1.0)
		newMe.apply_torque_impulse(mass*p_angular_velocity*0.003)
		
		newMe.speed_on_release = linear_velocity.length() #so I can record velocity objects are released at so I don't have to undertsnad get_contact_impulse()

		# we are no longer picked up
		if "held_item" in by_controller:
			by_controller.held_item = null
		newMe.picked_up_by = null
		newMe.by_controller = null

		
		#######################################################
		#Custom throwing code
		#####################################################
		#so here we have been thrown so I need to find a way to start running a physics_process to check for collisions and when I collide
		#I play my desired effect, e.g. explode the bomb
		print("item let go")
		if newMe.do_action_when_thrown == true:
			print("custom item should try to connect signal now")
			newMe.contact_monitor = true #this is high level shit here, I am scared (me not Bastiaan),....update  year later I'm not as scared especially since I took precautions and only activated this for throwables when thrown
			newMe.contacts_reported = 1
			newMe.connect("body_entered", newMe, "on_impact")
			#we need to check the impact of the collision so we can safely put down explosives but this will have to be handled in each individual item
		else:
			newMe.contact_monitor = false #so I can turn it on whenn i pick it up for rumble
		newMe.collision_mask = 0
		newMe.collision_layer = 0
		newMe.collision_mask = original_collision_mask
		newMe.collision_layer = original_collision_layer
		if newMe != self:
			collision_mask = 0
			collision_layer = 0
			visible = false
#			for child in get_children():
#				if child.get_class() == "MeshInstance":
#					child.visible = false
			newMe.ready_functions()
			newMe.highlight_mesh_instance_node = newMe.get_node(highlight_mesh_instance)
#		yield(get_tree().create_timer(0.1), "timeout")  #will this work to allow us to have no collision until it is thrown
#		newMe.collision_mask = original_collision_mask
#		newMe.collision_layer = original_collision_layer
			proper_deletion()
		return newMe


func _ready():
	ready_functions()


func ready_functions():
	if highlight_mesh_instance:
		# if we have a highlight mesh instance selected obtain our node
		highlight_mesh_instance_node = get_node(highlight_mesh_instance)
		if highlight_mesh_instance_node:
			# if we can find a node remember which materials are currently set on each surface
			for i in range(0, highlight_mesh_instance_node.get_surface_material_count()):
				original_materials.push_back(highlight_mesh_instance_node.get_surface_material(i))

	if center_pickup_on:
		# if we have center pickup on set obtain our node
		center_pickup_on_node = get_node(center_pickup_on)
###################################################
#custom sheathe code
###################################################

func increase_is_closest_to_sheathe(sheathe_slot):
	if is_instance_valid(self) == false:
		return
	#print("func increase_is_closest_to_sheathe()")
	closest_to_sheathe_count += 1
	adjacent_sheathe_slot = sheathe_slot
	_update_highlight()

func decrease_is_closest_to_sheathe(_sheathe_slot):
	if is_instance_valid(self) == false:
		return
	#print("func decrease_is_closest_to_sheathe()")
	closest_to_sheathe_count -= 1
	yield(get_tree().create_timer(0.001), "timeout") #would be nice to get some sort of call deffered function instead but this seems to work for now
	adjacent_sheathe_slot = null #this is possibly triggering too early
	_update_highlight()

func sheathe():
#	if is_melee_weapon == true: #need to do before removing as a parent
#		if picked_up_by == vars.player_item_parent:
#			#if we sheathe we need to tell the record
#			vars.melee_weapons_held_by_player -= 1
#		hitbox.collision_mask = 0 #remove all hitbox
#		hitbox.collision_layer = 0 
#	if is_parry_object == true:
#		parrybox.collision_layer = 0
#		parrybox.collision_mask = 0
	#not called by the sheathe slot so we need sheathe_slot to be a stored variable
	#item is already picked_up
	#but we need to pick it up with the sheathe slot
	current_sheathe_slot = adjacent_sheathe_slot
	#we might only need to do the last part of the pick up function which reparents
	# now reparent it
	var original_transform = global_transform
	picked_up_by.remove_child(self) #We want to remove from the player, it was originally #original_parent.remove_child(self)
#	if joint_node_ref != null: #NEED TO KNOW IF THE JOINT IS REALLY GONE
#		joint_node_ref.queue_free()
#		joint_node_ref = null
	current_sheathe_slot.add_child(self) #We want to add to the sheathe slot, it was originally #picked_up_by.add_child(self)
	mode = MODE_KINEMATIC
	current_sheathe_slot.object_in_sheathe = self #this is to make it so we can only put one item in each slot
	
	
	picked_up_by = null
	by_controller = null
	#probably have to set it to a new collision layer so I can pick it up.
	#e.g. a collision layer for sheathed objects that I can also pick things up from, so it doesn't get hit by objects when I walk around but I can still pick it up.
	collision_layer = sheathed_item_layer
	collision_mask = 0
	
	
	if true:#reset_transform_on_pickup: # could make a reset_transform_on_sheathe variable
		if true:#center_pickup_on_node:
			transform = center_pickup_on_node.global_transform.inverse() * global_transform
		else:
			# reset our transform
			transform = Transform()
	else:
		# make sure we keep its original position
		global_transform = original_transform

#func _integrate_forces(state):
#	#FIX turn back on, for now there is something else setting my position
#	item_integrate_forces_function(state)
#	pass

#func _process(delta): #should this be physics_process
#	#print(item delt)
#	#my concern here is that maybe I should store a bool to check if I am picked up
#	#depends if checking if something is not null takes up a significantly more amount of memory than checking a bool
#
#	item_process_function(delta)
#
##	if picked_up_by: #is not null
##		print("item delta = ", delta)
##		#then we have to follow the controller
##		var vec = move_toward_controller(by_controller)
##		if is_melee_weapon == true:
##			if get_parent() == vars.player_item_parent: #only do it if player is holding item
##				#hmmm maybe we should only transfer the position
##				vars.playerWeaponTransform = hitbox.global_transform #this will be overwritten if we dual wield. But who wants to bother writing all this complicated averaging AI code for dual wielding anyways.
##
#
#		#Idea for having controllers drop out of your hand
#		#if get_parent() == vars.player_item_parent: #if we check this again might as well put the above "If is_melee_weapon check in here too"
#		#	var distance_to_controller = vec.length #just get vel from move_to_controller
#		#	if distance_to_controller > 0.5: #some threshold
#		#		time_until_drop_weapon -= 1 
#		#		if time_until_drop_weapon < 0:
#		#			let_go()
#		#	else:
#		#		time_until_drop_weapon = 180 #framerate is 90 or 60 so this should be 2-3 seconds
#
#func item_integrate_forces_function(state):
#	if picked_up_by: #is not null
#		if get_parent() == vars.player_item_parent: #held by player
#			print("sword is picked up by player integrate forces, is it asleep ", state.sleeping)
#			velocity_to_controller = by_controller.global_transform.origin - global_transform.origin
#			velocity_to_controller *= 1
#			print("velocity_to_controller = ", velocity_to_controller)
#			#print("in _integrate_forces item.linear_velocity = ", linear_velocity)
#			#state.linear_velocity = velocity_to_controller
#			state.set_linear_velocity(velocity_to_controller)
#			print("linear_velocity = ", state.get_linear_velocity())
#			global_transform.basis = by_controller.global_transform.basis
#	else: #it is null so we have been let go (or we are sitting still) #so we start a 5 second timer to change the hitbox back to normal
#		if reset_hitbox_collision_mask_bool == true:
#			var delta = state.get_step()
#			reset_hitbox_collision_mask_timer -= delta
#			#print("we have let go and we are resetting the collision mask in ", reset_hitbox_collision_mask_timer,  " seconds")
#			if reset_hitbox_collision_mask_timer < 0:
#				print("timer complete, reset collision")
#				hitbox_collision_mask = 32+64 #hurt everyone
#				hitbox.collision_mask = hitbox_collision_mask
#				#hitbox.collision_layer =  SHOULDN'T i SET THIS TOO
#				reset_hitbox_collision_mask_bool = false
#
#func item_process_function(delta): #same but made for "process" or "physics process"
#	if picked_up_by: #is not null
#		if get_parent() == vars.player_item_parent: #held by player
#			print("sword is picked up by player")
#			velocity_to_controller = move_toward_controller(by_controller)
#			if is_melee_weapon == true:
#				vars.playerWeaponTransform = hitbox.global_transform #for enemies to detect
#				#Maybe I could add something here to increase the impulse it does
#
#		#else: #held by NPC
#		#	#just make it a child of NPC's hand so godot handles correct positioning
#		#	pass
#	else: #it is null so we have been let go (or we are sitting still) #so we start a 5 second timer to change the hitbox back to normal
#		if reset_hitbox_collision_mask_bool == true:
#
#			reset_hitbox_collision_mask_timer -= delta
#			#print("we have let go and we are resetting the collision mask in ", reset_hitbox_collision_mask_timer,  " seconds")
#			if reset_hitbox_collision_mask_timer < 0:
#				print("timer complete, reset collision")
#				hitbox_collision_mask = 32+64 #hurt everyone
#				hitbox.collision_mask = hitbox_collision_mask
#				#hitbox.collision_layer =  SHOULDN'T i SET THIS TOO
#				reset_hitbox_collision_mask_bool = false
#
#
#
#func move_toward_controller(controller):
#
#	var vec = controller.global_transform.origin - global_transform.origin
#	vec = vec*75 #100 was speed of movement toward the controller but it seemed to very dependent on frame rate and delta I was getting different results in VR and "R" (or !VR) .normalised() fixed this sort of 
#	linear_velocity = vec #this doesn't seem to do anything as the rigid body is in character mode?
#	trying_to_move = true #can I get rid of this?
#	print("In item.move_toward_controller func, item.linear_velocity is = ", linear_velocity)#, " sleeping = ", sleeping )  sleeping was false
#	#move_and_slide(vec)
#	#if get_parent() ==  vars.player_item_parent: #to only rotate for player
#	#print("BEFORE item's rotation is = ", rotation)
#	global_transform.basis = controller.global_transform.basis #before it was local but it wouldn't work with how I set up my enemy attacks
#	#rotation = controller.rotation #need to be son of origin node for it to rotate with the controller properly
#	#print("AFTER item's rotation is = ", rotation)
#	return vec

func fix_position(): #called when we move, when we are being held this is okay, but if we are still ahn acting rigid body we need different code
	 #global_transform.origin = by_controller.global_transform.origin
	 global_transform.origin = picked_up_by.global_transform.origin

#func set_up_teleport(glo_transform): #essentially a caLL DEFFERED thing for process and integrate forces
#	#Store the variables we need for teleporting
#	previous_linear_velocity = linear_velocity
#	teleport_transform = glo_transform
#	trying_to_teleport = true
#	collision_layer = 0
#	collision_mask = 2 #just the floor
#	set_use_custom_integrator(true)
#	#sleeping = true

#func teleport_rigid(state): #called from integrate forces
#
#	global_transform = teleport_transform
#
#	angular_velocity = Vector3.ZERO
#
#	var original_speed = previous_linear_velocity.length()
#	linear_velocity = original_speed*teleport_transform.origin
#
#	#state.linear_velocity = 0
#	set_use_custom_integrator(false)
#	trying_to_teleport = false
#	teleport_transform = null #Im guessing this might save us data
#	previous_linear_velocity = null
#	collision_mask = original_collision_mask
#	collision_layer = original_collision_layer
#	pass
##

#func _integrate_forces(state):
#	if trying_to_teleport == true:
#		teleport_rigid(state)

#func _integrate_forces(state):
#	if trying_to_move == true:
#		velocity_to_controller = by_controller.global_transform.origin - global_transform.origin
#		velocity_to_controller*=75
#		#print("in _integrate_forces item.linear_velocity = ", linear_velocity)
#		state.linear_velocity = velocity_to_controller
#		trying_to_move = false

func proper_deletion():
	collision_mask = 0
	collision_layer = 0
	highlight_mesh_instance_node = null
	queue_free()
