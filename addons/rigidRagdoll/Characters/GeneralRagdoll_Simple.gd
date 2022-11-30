extends "res://addons/rigidRagdoll/Scripts/ragdollExtra.gd"

#To customise the mesh:
# you need to replace all bone names with the correct ones in the rigidBodiesFromBones dictionary

#NOTES:
# Remember Left and Right may need to be switched if the meshes arms are crossed.
# (is it my left and right when looking at the character front on or is it the characters left and right),
# the rigidBodies is this ragdoll are named from the characters perspective of left and right.

#I haven't done scaling yet so you may need to rescale things yourself







var health = 10
var stunTime = 0
var rigid_bodies = []
#var stamina = 10


#var faction = 0
#var extraAnimBool = false
#var extraAnimString = "null"
#var extraAnimTarget = Vector3(0,0,0)
#var extraAnimTime = 0
#var extraAnimNode = null
#var extraAnimState = 0
#var extraAnimRand = 0
#var walkStrength = 10.0
#var dominantHand = null
#var weaponLength = 1.0
#var total_weight = 45
#var stats = {
#	"walkSpeed" : 0.75,
#	"swingSpeed" : 1.0
#}
#var prepareTarget = Vector3(0,0,0)
#var handPosNodeToHandDist = 0.15

var legOffset = Vector3(0,0.1,0) #zero vec changes it to apply_central_impulse

var is_dying = false
#var baseAnimTime = 0



#var skeleton = null #set in get_initial_tforms

#func get_initial_tforms():
#	skeleton = $Skeleton
#	for boneName in rigidBodiesFromBones.keys():
#		boneNameToIndex[boneName] = skeleton.find_bone(boneName)
#		var rigidBodyName = rigidBodiesFromBones[boneName]
#		var tForm = get_node(rigidBodyName).transform
#		rigidBodiesInitialTForms[rigidBodyName] = tForm
#		rigidBodiesInverseTForms[rigidBodyName] = tForm.affine_inverse() ##this tForm should have no scaling if we want normal inverse()
#		var boneIndex = boneNameToIndex[boneName]#skeleton_bones_sync[boneName]
#		boneInitialTForms[boneName] = skeleton.get_bone_global_pose(boneIndex) #returns transform relative to skeleton


#var actual_bones_used = rigidBodiesFromBones.keys()
#var rigidBodiesInitialTForms = {}
#var rigidBodiesInverseTForms = {}
#var boneInitialTForms = {}
#var boneNameToIndex = {}



# Called when the node enters the scene tree for the first time.
func _ready():
	
	rigidBodiesFromBones = {
	#we put the name of our bone as the key
	#we put the name of the corresponding rigidBody as the value (has to be child of skeleton)
	#so if we change the model but keep the ragdoll, then we only change the keys
	#the rest of the data will be generated from this list and the data in skeleton
	"mixamorig_Spine2" : "Body",
	"mixamorig_Hips" : "Legs",
	"mixamorig_Head" : "Head",
	"mixamorig_LeftArm" : "ArmL",
	"mixamorig_LeftForeArm" : "ForeArmL",
	"mixamorig_RightArm" : "ArmR",
	"mixamorig_RightForeArm" : "ForeArmR",
	}
	
	skeleton = $SkeletonRagdoll
	rigidBodyParent = skeleton
	#_set_up()
	
	my_skel = skeleton
	my_headNode = $SkeletonRagdoll/Head
	basePosNode = $SkeletonRagdoll/Legs #could be a singular ffoot or hips
	
	dominantHand = $SkeletonRagdoll/ForeArmR
	parent_is_ready()
	
	
#	get_initial_tforms()
#	rigid_bodies = [$Legs, $Body, $Head, $ArmL, $ForeArmL, $ArmR, $ForeArmR]
#	dominantHand = $ForeArmR
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	floorPos = basePosNode.global_transform.origin
	extra_animations(delta)
	
	
	
#	deform_skeleton_with_rigidBodies()
#	if is_dying == true:
#		baseAnimTime -= delta
#		if baseAnimTime <= 0:
#			queue_free()
#		return
#	check_health()
#	if stunTime > 0: #only do AI things when I recover from knockback
#		stunTime -= delta
#		#print("I am stunned")
#		#test alternate stun effects
##		axis_lock_angles($capsuleBase, false)
##		ragdollState = ragdollStateDir["gettingUp"]
#		if stunTime <= 0:
#			stunTime = 0
#		return
#	extra_animations(delta)
##	pass

